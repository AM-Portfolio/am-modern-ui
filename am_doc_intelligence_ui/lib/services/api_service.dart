import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'client_creator.dart';
import 'package:am_common/am_common.dart';
import 'package:am_library/am_library.dart';
import 'package:am_doc_intelligence_ui/models/batch_sync_models.dart';
import 'package:am_doc_intelligence_ui/models/sync_unavailable_exception.dart';
import 'package:get_it/get_it.dart';

enum AppEnvironment { local, preprod }

class ApiService {
  AppEnvironment environment = AppEnvironment.preprod;

  // Create a Client with credentials disabled on Web
  http.Client _makeClient() {
    return createClient();
  }

  // Base URLs resolved dynamically based on environment switcher selection
  String get _docBase => environment == AppEnvironment.local
      ? 'http://localhost:8081/v1'
      : '${EnvDomains.docs}/v1';

  String get _emailBase => environment == AppEnvironment.local
      ? 'http://localhost:8080/api/v1'
      : '${EnvDomains.gmail}/api/v1';

  // Credentials — fallback values for demo login sessions
  static const String _authToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NzkwMDcyNzUsImlhdCI6MTc3ODkyMDg3NSwic3ViIjoiYjc1NzQzYzktZmUwZS00YzU0LThlZTAtOGRhMzUwY2MyN2IzIiwidXNlcm5hbWUiOiJzc2QyNjU4QGdtYWlsLmNvbSIsImVtYWlsIjoic3NkMjY1OEBnbWFpbC5jb20iLCJzY29wZXMiOlsicmVhZCIsIndyaXRlIl19.uqaDH_iDEZeSgnjOD7Q5gnG3MrE8jnxzhrPgYQjUUpU";
  static const String _userId = "b75743c9-fe0e-4c54-8ee0-8da350cc27b3";

  Future<Map<String, String>> _getHeaders() async {
    String? token;
    String? userId;
    try {
      if (GetIt.I.isRegistered<SecureStorageService>()) {
        final storage = GetIt.I<SecureStorageService>();
        token = await storage.getAccessToken();
        userId = await storage.getUserId();
      } else {
        final storage = SecureStorageService();
        token = await storage.getAccessToken();
        userId = await storage.getUserId();
      }
    } catch (e) {
      debugPrint('[ApiService] Secure storage read failed: $e');
    }

    // Fallback to static demo credentials only if the session storage is completely empty
    final finalToken = (token != null && token.isNotEmpty) ? token : _authToken;
    final finalUserId = (userId != null && userId.isNotEmpty) ? userId : _userId;

    return {
      'Authorization': 'Bearer $finalToken',
      // X-User-ID is redundant with JWT on the server. Sending it from a
      // localhost UI to preprod/prod trips CORS (header not allow-listed) and
      // surfaces as ClientException: Failed to fetch on multipart upload.
      if (!kIsWeb) 'X-User-ID': finalUserId,
    };
  }

  final List<String> brokerTypes = [
    'ZERODHA',
    'UPSTOX',
    'GROWW',
    'DHAN',
    'MSTOCK',
    'ANGEL_ONE',
  ];

  // --- Document Processor endpoints ---

  Future<List<String>> getSupportedDocumentTypes() async {
    final url = '$_docBase/documents/types';
    debugPrint('[ApiService] GET $url');
    final apiClient = GetIt.I.isRegistered<ApiClient>() 
        ? GetIt.I<ApiClient>() 
        : ApiClient();

    return apiClient.get<List<String>>(
      url,
      parser: (data) => List<String>.from(data),
      requireAuth: false,
    );
  }

  Future<Map<String, dynamic>> processDocument(
      Uint8List fileBytes, String filename, String docType,
      {String brokerType = 'ZERODHA', String? portfolioId}) async {
    // Same ingress pattern as types (/doc/processor) and other modules
    // (/portfolio, /market): Traefik → service with Keycloak Bearer.
    // Do NOT use /am/... here — asrax-proxy is a separate auth path and
    // is what returned 401 while Keycloak worked everywhere else.
    final url = '$_docBase/documents/process';
    debugPrint(
        '[ApiService] POST $url (type=$docType, broker=$brokerType, portfolio=$portfolioId)');
    var request = http.MultipartRequest('POST', Uri.parse(url));
    final headers = await _getHeaders();
    request.headers.addAll(headers);
    // Map custom UI broker types to backend enum values
    String apiBrokerType = brokerType;
    if (brokerType == 'GROWW') {
      apiBrokerType = 'GROW';
    }
    request.fields['brokerType'] = apiBrokerType;
    
    // Map custom UI document types to backend-supported document types
    String apiDocType = docType;
    if (docType == 'PORTFOLIO_EQUITY' || docType == 'PORTFOLIO_ETF') {
      apiDocType = 'STOCK_PORTFOLIO';
    }
    request.fields['documentType'] = apiDocType;
    final trimmedPortfolio = portfolioId?.trim();
    if (trimmedPortfolio != null && trimmedPortfolio.isNotEmpty) {
      request.fields['portfolioId'] = trimmedPortfolio;
    }

    request.files
        .add(http.MultipartFile.fromBytes('file', fileBytes, filename: filename));

    final client = _makeClient();
    try {
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('[ApiService] process: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception(
          'Process failed: ${response.statusCode}\n${response.body}');
    } finally {
      client.close();
    }
  }

  String? mapBrokerForApi(String? brokerType) {
    if (brokerType == null || brokerType.isEmpty || brokerType == 'AUTO') {
      return null;
    }
    // Keep parity with [processDocument] legacy Groww enum mapping.
    if (brokerType == 'GROWW') return 'GROW';
    return brokerType;
  }

  String? mapDocumentTypeForApi(String? docType) {
    if (docType == null || docType.isEmpty || docType == 'AUTO') {
      return null;
    }
    if (docType == 'PORTFOLIO_EQUITY' || docType == 'PORTFOLIO_ETF') {
      return 'STOCK_PORTFOLIO';
    }
    return docType;
  }

  /// Submits up to 5 files for async multi-broker / multi-portfolio sync.
  /// Returns the initial [BatchSyncStatus] (HTTP 202).
  Future<BatchSyncStatus> submitBatchSync({
    required List<Uint8List> fileBytes,
    required List<String> filenames,
    List<String?>? brokerTypes,
    List<String?>? documentTypes,
    List<String?>? passwords,
    List<String?>? portfolioIds,
    String? portfolioId,
  }) async {
    if (fileBytes.isEmpty || fileBytes.length != filenames.length) {
      throw Exception('At least one file is required');
    }
    final url = '$_docBase/documents/sync';
    debugPrint('[ApiService] POST $url (files=${fileBytes.length})');
    final request = http.MultipartRequest('POST', Uri.parse(url));
    final headers = await _getHeaders();
    request.headers.addAll(headers);

    for (var i = 0; i < fileBytes.length; i++) {
      request.files.add(http.MultipartFile.fromBytes(
        'files',
        fileBytes[i],
        filename: filenames[i],
      ));
    }

    void addAlignedField(String name, List<String?>? values) {
      if (values == null) return;
      for (final value in values) {
        request.files.add(http.MultipartFile.fromString(name, value ?? ''));
      }
    }

    addAlignedField('brokerTypes', brokerTypes);
    addAlignedField('documentTypes', documentTypes);
    addAlignedField('passwords', passwords);
    addAlignedField('portfolioIds', portfolioIds);
    if (portfolioId != null && portfolioId.trim().isNotEmpty) {
      request.fields['portfolioId'] = portfolioId.trim();
    }

    final client = _makeClient();
    try {
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('[ApiService] sync: ${response.statusCode}');
      if (response.statusCode == 202 || response.statusCode == 200) {
        return BatchSyncStatus.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body) as Map),
        );
      }
      if (SyncUnavailableException.looksLikeNetworkOrMissingRoute(
          response.body, response.statusCode)) {
        throw SyncUnavailableException(
          message: _syncUnavailableMessage(),
          statusCode: response.statusCode,
          cause: 'HTTP ${response.statusCode}',
        );
      }
      throw Exception('Sync failed: ${response.statusCode}\n${response.body}');
    } on SyncUnavailableException {
      rethrow;
    } catch (e) {
      if (SyncUnavailableException.looksLikeNetworkOrMissingRoute(e)) {
        throw SyncUnavailableException(
          message: _syncUnavailableMessage(),
          cause: e,
        );
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  String _syncUnavailableMessage() {
    final envLabel = environment == AppEnvironment.local ? 'Local' : 'Preprod';
    return 'Auto-detect sync is temporarily unavailable on $envLabel. '
        'Set broker and document type for each file, then try Sync again.';
  }

  Future<BatchSyncStatus> getBatchSyncStatus(String batchId) async {
    final url = '$_docBase/documents/sync/$batchId/status';
    debugPrint('[ApiService] GET $url');
    final client = _makeClient();
    try {
      final headers = await _getHeaders();
      final response = await client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return BatchSyncStatus.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body) as Map),
        );
      }
      throw Exception(
          'Status failed: ${response.statusCode}\n${response.body}');
    } finally {
      client.close();
    }
  }

  /// Confirm, supply password, or override broker/doc type for a gated file.
  Future<BatchSyncStatus> resolveBatchFile({
    required String batchId,
    required String fileId,
    bool confirm = false,
    String? brokerType,
    String? documentType,
    String? password,
    String? portfolioId,
  }) async {
    final url = '$_docBase/documents/sync/$batchId/files/$fileId/resolve';
    debugPrint('[ApiService] POST $url (confirm=$confirm)');
    final client = _makeClient();
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final body = <String, dynamic>{
        if (confirm) 'confirm': true,
        if (brokerType != null && brokerType.isNotEmpty)
          'brokerType': mapBrokerForApi(brokerType) ?? brokerType,
        if (documentType != null && documentType.isNotEmpty)
          'documentType': mapDocumentTypeForApi(documentType) ?? documentType,
        if (password != null && password.isNotEmpty) 'password': password,
        if (portfolioId != null && portfolioId.isNotEmpty)
          'portfolioId': portfolioId,
      };
      final response = await client
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      debugPrint('[ApiService] resolve: ${response.statusCode}');
      if (response.statusCode == 200) {
        return BatchSyncStatus.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body) as Map),
        );
      }
      throw Exception(
          'Resolve failed: ${response.statusCode}\n${response.body}');
    } finally {
      client.close();
    }
  }

  // --- Health Checks ---

  Future<bool> checkDocProcessorHealth() async {
    // /documents/types is a public endpoint — no auth header needed.
    // Using a plain http.get avoids false-offline status caused by expired JWT tokens.
    final url = '$_docBase/documents/types';
    debugPrint('[ApiService] Health -> GET $url');
    try {
      final client = _makeClient();
      final response = await client.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      client.close();
      debugPrint('[ApiService] Health status: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[ApiService] Health failed: $e');
      return false;
    }
  }

  Future<bool> checkEmailExtractorHealth() async {
    final url = '$_emailBase/health';
    debugPrint('[ApiService] Email health -> GET $url');
    try {
      final apiClient = GetIt.I.isRegistered<ApiClient>() 
          ? GetIt.I<ApiClient>() 
          : ApiClient();
          
      await apiClient.get<dynamic>(
        url,
        parser: (data) => data,
        requireAuth: false,
      );
      return true;
    } catch (e) {
      debugPrint('[ApiService] Email health failed: $e');
      return false;
    }
  }

  // --- Email Extractor endpoints ---

  Future<Map<String, dynamic>> checkGmailStatus() async {
    final url = '$_emailBase/gmail/status';
    debugPrint('[ApiService] GET $url');
    try {
      final apiClient = GetIt.I.isRegistered<ApiClient>() 
          ? GetIt.I<ApiClient>() 
          : ApiClient();
          
      final headers = await _getHeaders();
      return await apiClient.get<Map<String, dynamic>>(
        url,
        headers: headers,
        parser: (data) => Map<String, dynamic>.from(data),
      );
    } catch (e) {
      debugPrint('[ApiService] gmail/status error: $e');
      return {'connected': false, 'error': '$e'};
    }
  }

  Future<Map<String, dynamic>> getBrokers() async {
    final url = '$_emailBase/brokers';
    debugPrint('[ApiService] GET $url');
    final apiClient = GetIt.I.isRegistered<ApiClient>() 
        ? GetIt.I<ApiClient>() 
        : ApiClient();
        
    final headers = await _getHeaders();
    return apiClient.get<Map<String, dynamic>>(
      url,
      headers: headers,
      parser: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> extractFromGmail(String broker) async {
    final url = '$_emailBase/extract/gmail/$broker?pan=PANK1234F';
    debugPrint('[ApiService] GET $url');
    final apiClient = GetIt.I.isRegistered<ApiClient>() 
        ? GetIt.I<ApiClient>() 
        : ApiClient();
        
    final headers = await _getHeaders();
    return apiClient.get<Map<String, dynamic>>(
      url,
      headers: headers,
      parser: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> connectGmail() async {
    final url = '$_emailBase/gmail/connect';
    debugPrint('[ApiService] GET $url');
    final apiClient = GetIt.I.isRegistered<ApiClient>() 
        ? GetIt.I<ApiClient>() 
        : ApiClient();
        
    final headers = await _getHeaders();
    return apiClient.get<Map<String, dynamic>>(
      url,
      headers: headers,
      parser: (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, dynamic>> disconnectGmail() async {
    final url = '$_emailBase/gmail/disconnect';
    debugPrint('[ApiService] DELETE $url');
    final apiClient = GetIt.I.isRegistered<ApiClient>() 
        ? GetIt.I<ApiClient>() 
        : ApiClient();
        
    final headers = await _getHeaders();
    return apiClient.delete<Map<String, dynamic>>(
      url,
      headers: headers,
      parser: (data) => Map<String, dynamic>.from(data),
    );
  }
}

final apiProvider = ApiService();

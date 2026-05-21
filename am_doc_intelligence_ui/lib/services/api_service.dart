import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:am_common/am_common.dart';
import 'package:am_library/am_library.dart';
import 'package:get_it/get_it.dart';

enum AppEnvironment { local, preprod }

class ApiService {
  AppEnvironment environment = AppEnvironment.preprod;

  // Create a BrowserClient with withCredentials = false
  // This ensures the browser doesn't send cookies/credentials,
  // allowing the server's "Access-Control-Allow-Origin: *" to work.
  http.Client _makeClient() {
    if (kIsWeb) {
      final client = BrowserClient()..withCredentials = false;
      return client;
    }
    return http.Client();
  }

  // Base URLs resolved dynamically from central registry
  String get _docBase => '${EnvDomains.docs}/v1';
  String get _emailBase => '${EnvDomains.gmail}/api/v1';

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
      'X-User-ID': finalUserId,
    };
  }

  final List<String> brokerTypes = [
    'ZERODHA',
    'UPSTOX',
    'GROWW',
    'ICICI_DIRECT',
    'HDFC_SECURITIES',
    'ANGEL_ONE',
    'OTHER',
  ];

  // --- Document Processor endpoints ---

  Future<List<String>> getSupportedDocumentTypes() async {
    final url = '$_docBase/documents/types';
    debugPrint('[ApiService] GET $url');
    final apiClient = GetIt.I.isRegistered<ApiClient>() 
        ? GetIt.I<ApiClient>() 
        : ApiClient();

    final headers = await _getHeaders();
    return apiClient.get<List<String>>(
      url,
      headers: headers,
      parser: (data) => List<String>.from(data),
    );
  }

  Future<Map<String, dynamic>> processDocument(
      Uint8List fileBytes, String filename, String docType,
      {String brokerType = 'ZERODHA'}) async {
    final url = '$_docBase/documents/process';
    debugPrint('[ApiService] POST $url (type=$docType, broker=$brokerType)');
    var request = http.MultipartRequest('POST', Uri.parse(url));
    final headers = await _getHeaders();
    request.headers.addAll(headers);
    request.fields['brokerType'] = brokerType;
    request.fields['documentType'] = docType;
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

  // --- Health Checks ---

  Future<bool> checkDocProcessorHealth() async {
    final url = '$_docBase/documents/types';
    debugPrint('[ApiService] Health -> GET $url');
    try {
      final apiClient = GetIt.I.isRegistered<ApiClient>() 
          ? GetIt.I<ApiClient>() 
          : ApiClient();
          
      final headers = await _getHeaders();
      await apiClient.get<dynamic>(
        url,
        headers: headers,
        parser: (data) => data,
      );
      return true;
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
          
      final headers = await _getHeaders();
      await apiClient.get<dynamic>(
        url,
        headers: headers,
        parser: (data) => data,
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
}

final apiProvider = ApiService();

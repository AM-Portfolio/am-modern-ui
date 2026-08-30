// ignore_for_file: unnecessary_null_comparison, parameter_assignments, unused_import, unused_element, always_put_required_named_parameters_first, constant_identifier_names, lines_longer_than_80_chars, avoid_dynamic_calls, invalid_assignment, undefined_method, undefined_getter, for_in_of_invalid_type, case_expression_type_is_not_switch_expression_subtype, deprecated_member_use_from_same_package
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

part of openapi.api;

class FundamentalAnalysisApi {
  FundamentalAnalysisApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get fundamental ratios for a given symbol
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] symbol (required):
  Future<Response> getRatiosWithHttpInfo(String symbol) async {
    final path = r'/v1/fundamentals/{symbol}/ratios'
      .replaceAll('{symbol}', symbol);
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get fundamental ratios for a given symbol
  ///
  /// Parameters:
  ///
  /// * [String] symbol (required):
  Future<FundamentalRatiosResponse?> getRatios(String symbol) async {
    final response = await getRatiosWithHttpInfo(symbol);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'FundamentalRatiosResponse') as FundamentalRatiosResponse;
    }
    return null;
  }
}

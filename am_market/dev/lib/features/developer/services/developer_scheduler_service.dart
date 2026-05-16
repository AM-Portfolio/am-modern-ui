import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:am_common/am_common.dart';

class DeveloperSchedulerService {
  static String get baseUrl => '${EnvDomains.market}/v1/scheduler';
  final Dio _dio = Dio();

  Future<List<String>> getSchedulers() async {
    try {
      final response = await _dio.get('$baseUrl/jobs');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching schedulers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> triggerScheduler(String jobName) async {
    try {
      final response = await _dio.post('$baseUrl/trigger/$jobName');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to trigger scheduler');
    } catch (e) {
      debugPrint('Error triggering scheduler $jobName: $e');
      rethrow;
    }
  }
}

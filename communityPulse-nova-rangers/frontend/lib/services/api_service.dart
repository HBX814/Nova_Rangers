import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Centralised HTTP client for the CommunityPulse FastAPI backend.
///
/// All methods use the [http] package and read [AppConfig.baseUrl] for the
/// base URL.  Use the singleton [ApiService.instance] everywhere — never
/// construct a new instance.
class ApiService {
  ApiService._();

  /// Singleton instance.
  static final ApiService instance = ApiService._();

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Build a [Uri] from a relative [path] and optional nullable query params.
  /// Null-valued params are automatically dropped.
  Uri _uri(String path, [Map<String, String?>? rawParams]) {
    final params = <String, String>{};
    rawParams?.forEach((k, v) {
      if (v != null) params[k] = v;
    });
    return Uri.parse('${AppConfig.baseUrl}$path')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  Map<String, dynamic> _decodeMap(http.Response res, String method) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('$method failed [${res.statusCode}]: ${res.body}');
  }

  List<Map<String, dynamic>> _decodeList(http.Response res, String method) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = json.decode(res.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('$method failed [${res.statusCode}]: ${res.body}');
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// GET /analytics/summary
  Future<Map<String, dynamic>> fetchSummary() async {
    try {
      final res = await http.get(_uri('/analytics/summary'));
      return _decodeMap(res, 'fetchSummary');
    } on SocketException catch (e) {
      throw Exception('fetchSummary: network error — $e');
    }
  }

  /// GET /needs  (optional filters: category, status, min_urgency)
  Future<List<Map<String, dynamic>>> fetchNeeds({
    String? category,
    String? status,
    int? minUrgency,
  }) async {
    try {
      final res = await http.get(
        _uri('/needs', {
          'category': category,
          'status': status,
          'min_urgency': minUrgency?.toString(),
        }),
      );
      return _decodeList(res, 'fetchNeeds');
    } on SocketException catch (e) {
      throw Exception('fetchNeeds: network error — $e');
    }
  }

  /// GET /needs/heatmap
  Future<List<Map<String, dynamic>>> fetchHeatmapNeeds() async {
    try {
      final res = await http.get(_uri('/needs/heatmap'));
      return _decodeList(res, 'fetchHeatmapNeeds');
    } on SocketException catch (e) {
      throw Exception('fetchHeatmapNeeds: network error — $e');
    }
  }

  /// GET /volunteers  (optional filters: status, skill)
  Future<List<Map<String, dynamic>>> fetchVolunteers({
    String? status,
    String? skill,
  }) async {
    try {
      final res = await http.get(
        _uri('/volunteers', {
          'status': status,
          'skill': skill,
        }),
      );
      return _decodeList(res, 'fetchVolunteers');
    } on SocketException catch (e) {
      throw Exception('fetchVolunteers: network error — $e');
    }
  }

  /// POST /submissions/upload  (multipart/form-data)
  ///
  /// Returns a [Map] containing at least `submission_id` and `status`.
  Future<Map<String, dynamic>> uploadSubmission(
    String filePath,
    String orgId,
    String submittedBy,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        _uri('/submissions/upload'),
      )
        ..fields['org_id'] = orgId
        ..fields['submitted_by'] = submittedBy
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
      throw Exception(
          'uploadSubmission failed [${res.statusCode}]: ${res.body}');
    } on SocketException catch (e) {
      throw Exception('uploadSubmission: network error — $e');
    }
  }

  /// GET /analytics/needs-by-category
  Future<List<Map<String, dynamic>>> fetchAnalyticsByCategory() async {
    try {
      final res = await http.get(_uri('/analytics/needs-by-category'));
      return _decodeList(res, 'fetchAnalyticsByCategory');
    } on SocketException catch (e) {
      throw Exception('fetchAnalyticsByCategory: network error — $e');
    }
  }
}

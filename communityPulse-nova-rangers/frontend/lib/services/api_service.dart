import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

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

  MediaType _mediaTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    return MediaType('application', 'octet-stream');
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// GET /analytics/summary
  Future<Map<String, dynamic>> fetchSummary() async {
    try {
      final res = await http.get(_uri('/analytics/summary'));
      return _decodeMap(res, 'fetchSummary');
    } on http.ClientException catch (e) {
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
    } on http.ClientException catch (e) {
      throw Exception('fetchNeeds: network error — $e');
    }
  }

  /// GET /needs/{needId}
  Future<Map<String, dynamic>> fetchNeedById(String needId) async {
    try {
      final res = await http.get(_uri('/needs/$needId'));
      return _decodeMap(res, 'fetchNeedById');
    } on http.ClientException catch (e) {
      throw Exception('fetchNeedById: network error — $e');
    }
  }

  /// GET /needs/heatmap
  Future<List<Map<String, dynamic>>> fetchHeatmapNeeds() async {
    try {
      final res = await http.get(_uri('/needs/heatmap'));
      return _decodeList(res, 'fetchHeatmapNeeds');
    } on http.ClientException catch (e) {
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
    } on http.ClientException catch (e) {
      throw Exception('fetchVolunteers: network error — $e');
    }
  }

  /// POST /submissions/upload  (multipart/form-data)
  ///
  /// Returns a [Map] containing at least `submission_id` and `status`.
  Future<Map<String, dynamic>> uploadSubmission(
    XFile file,
    String orgId,
    String submittedBy,
  ) async {
    try {
      final fileBytes = await file.readAsBytes();
      final request = http.MultipartRequest(
        'POST',
        _uri('/submissions/upload'),
      )
        ..fields['org_id'] = orgId
        ..fields['submitted_by'] = submittedBy
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: file.name,
            contentType: _mediaTypeForFileName(file.name),
          ),
        );

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
      throw Exception(
          'uploadSubmission failed [${res.statusCode}]: ${res.body}');
    } on http.ClientException catch (e) {
      throw Exception('uploadSubmission: network error — $e');
    }
  }

  /// GET /analytics/needs-by-category
  Future<List<Map<String, dynamic>>> fetchAnalyticsByCategory() async {
    try {
      final res = await http.get(_uri('/analytics/needs-by-category'));
      return _decodeList(res, 'fetchAnalyticsByCategory');
    } on http.ClientException catch (e) {
      throw Exception('fetchAnalyticsByCategory: network error — $e');
    }
  }

  /// GET /organizations
  Future<List<Map<String, dynamic>>> fetchOrganizations() async {
    try {
      final res = await http.get(_uri('/organizations'));
      return _decodeList(res, 'fetchOrganizations');
    } on http.ClientException catch (e) {
      throw Exception('fetchOrganizations: network error — $e');
    }
  }

  /// GET /volunteers/{volunteerId}/assignments
  Future<List<Map<String, dynamic>>> fetchVolunteerAssignments(
      String volunteerId) async {
    try {
      final res = await http.get(_uri('/volunteers/$volunteerId/assignments'));
      return _decodeList(res, 'fetchVolunteerAssignments');
    } on http.ClientException catch (e) {
      throw Exception('fetchVolunteerAssignments: network error — $e');
    }
  }
}

/// CommunityPulse API Service
///
/// Centralised HTTP client for communicating with the FastAPI backend.
/// Uses Dio for request/response handling with interceptors for auth tokens.
///
/// Configuration is read from environment variables at build time:
///   --dart-define=API_BASE_URL=https://your-cloud-run-url.run.app

import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    // TODO: Replace with your Cloud Run URL or use --dart-define
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth interceptor — attaches Firebase ID token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // TODO: Get Firebase Auth token
          // final user = FirebaseAuth.instance.currentUser;
          // if (user != null) {
          //   final token = await user.getIdToken();
          //   options.headers['Authorization'] = 'Bearer $token';
          // }
          return handler.next(options);
        },
        onError: (error, handler) {
          // TODO: Handle 401 → redirect to login
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;

  // ---------------------------------------------------------------------------
  // Needs
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getNeeds({String? status, String? category, int limit = 100}) async {
    final params = <String, dynamic>{'limit': limit};
    if (status != null) params['status_filter'] = status;
    if (category != null) params['category'] = category;

    final response = await _dio.get('/needs', queryParameters: params);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getNeed(String needId) async {
    final response = await _dio.get('/needs/$needId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createNeed(Map<String, dynamic> data) async {
    final response = await _dio.post('/needs', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTopPriorityNeeds({int limit = 10}) async {
    final response = await _dio.get('/needs/priority/top', queryParameters: {'limit': limit});
    return response.data as List<dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Volunteers
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getVolunteers({String? status, int limit = 100}) async {
    final params = <String, dynamic>{'limit': limit};
    if (status != null) params['status_filter'] = status;

    final response = await _dio.get('/volunteers', queryParameters: params);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getVolunteer(String volunteerId) async {
    final response = await _dio.get('/volunteers/$volunteerId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerVolunteer(Map<String, dynamic> data) async {
    final response = await _dio.post('/volunteers', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> findNearbyVolunteers({
    required double lat,
    required double lng,
    double radiusKm = 25.0,
  }) async {
    final response = await _dio.get('/volunteers/nearby/', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
    return response.data as List<dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Submissions
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> data) async {
    final response = await _dio.post('/submissions', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSubmissions({int limit = 50}) async {
    final response = await _dio.get('/submissions', queryParameters: {'limit': limit});
    return response.data as List<dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Organizations
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getOrganizations({int limit = 100}) async {
    final response = await _dio.get('/organizations', queryParameters: {'limit': limit});
    return response.data as List<dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final response = await _dio.get('/analytics/summary');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTopVolunteers({int limit = 10}) async {
    final response = await _dio.get('/analytics/top-volunteers', queryParameters: {'limit': limit});
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getDistrictHeatmap() async {
    final response = await _dio.get('/analytics/district-heatmap');
    return response.data as List<dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/token', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }
}

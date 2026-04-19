import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

class NetworkService extends GetxService {
  late Dio _dio;
  
  Future<NetworkService> init() async {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ));
    // Add interceptors for logging or auth if needed
    return this;
  }

  Future<Response> get(String url, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(url, queryParameters: queryParameters);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String url, {dynamic data}) async {
    try {
      final response = await _dio.post(url, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Add more methods as needed (put, delete, etc.)
}

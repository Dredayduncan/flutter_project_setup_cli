import 'package:dio/dio.dart';
import 'api_result_model.dart';
import '../setup/setup.dart';

class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? getIt.get<Dio>();

  final Dio _dio;

  Future<ApiResult<T, String>> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.data is ApiData) {
      return Future.value(
        ApiData(
          data: fromJson != null
              ? fromJson((response.data as ApiData).getData)
              : null as T,
        ),
      );
    } else if (response.data is ApiError) {
      final apiError = response.data as ApiError<dynamic, String>;
      return Future.value(ApiError<T, String>(error: apiError.error));
    } else {
      // This should never happen due to our interceptor, but just in case:
      return Future.value(ApiError(error: 'Unexpected response type'));
    }
  }

  Future<ApiResult<T, String>> get<T>(
    String path,
    T Function(dynamic) fromJson, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    return _handleResponse<T>(response, fromJson);
  }

  Future<ApiResult<T, String>> post<T>(
    String path,
    T Function(dynamic)? fromJson, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return _handleResponse<T>(response, fromJson);
  }

  Future<ApiResult<T, String>> delete<T>(
    String path,
    T Function(dynamic)? fromJson, {
    dynamic data,
    Options? options,
  }) async {
    final response = await _dio.delete(
      path,
      data: data,
      options: options,
    );
    return _handleResponse<T>(response, fromJson);
  }

  Future<ApiResult<T, String>> put<T>(
    String path,
    T Function(dynamic)? fromJson, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return _handleResponse<T>(response, fromJson);
  }

  Future<ApiResult<T, String>> patch<T>(
    String path,
    T Function(dynamic)? fromJson, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return _handleResponse<T>(response, fromJson);
  }
}

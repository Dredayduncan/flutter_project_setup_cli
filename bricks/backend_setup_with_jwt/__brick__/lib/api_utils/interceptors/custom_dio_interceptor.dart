import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api_result_model.dart';
import '../extensions/dio_extensions.dart';
import '../../services/platform_services/storage_services/token_storage_service.dart';

class CustomDioInterceptor extends Interceptor {
  CustomDioInterceptor({
    required TokenStorageService tokenStorageService,
    required VoidCallback onRefreshTokenExpired,
    required Dio dio,
  })  : _dio = dio,
        _tokenStorageService = tokenStorageService,
        _onRefreshTokenExpired = onRefreshTokenExpired;

  final TokenStorageService _tokenStorageService;
  final Dio _dio;
  final VoidCallback _onRefreshTokenExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if the Authorization header is not present in the request options
    if (!options.headers.containsKey('Authorization')) {
      // Get the token from storage
      final tokenModel = await _tokenStorageService.getToken();

      // Add the token to the request options if it is not null
      if (tokenModel != null) {
        options.headers.addAll(tokenModel.toHeader);
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Convert successful responses to ApiData
    handler.resolve(
      Response(
        requestOptions: response.requestOptions,
        data: ApiData(data: response.data),
        statusCode: response.statusCode,
        headers: response.headers,
      ),
    );
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.isTokenExpiry) {
      await _tokenStorageService.refreshUserToken(
        onSuccess: (tokenModel) async {
          // Retry the original request with the new token
          final opts = err.requestOptions;
          opts.headers.addAll(tokenModel.toHeader);

          try {
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.reject(retryError);
          }
        },
        onError: (error) async {
          _onRefreshTokenExpired();

          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: error,
            ),
          );
        },
      );

      return;
    }

    // Convert errors to ApiError
    var errorMessage = 'An error occurred while accessing the server.';

    if (err.response != null && err.response!.data != null) {
      if (err.response!.data is Map<String, dynamic>) {
        final errorResponseData = err.response!.data as Map<String, dynamic>;
        if (errorResponseData['detail'] != null) {
          errorMessage = errorResponseData['detail'].toString();

          // check if the user has been delete and delete the stored tokens
          if (errorResponseData['detail'] == 'User not found') {
            // delete the user's tokens from storage
            await _tokenStorageService.deleteToken();
          }
        } else {
          // Get the keys of the map
          final keys = errorResponseData.keys.toList();

          // Retrieve the value associated with the first key
          final firstKey = keys.first;
          final firstValue = errorResponseData[firstKey];

          errorMessage = firstValue.toString();
        }
      } else {
        // Extract the value of the 'string' field
        final regex = RegExp(r"ErrorDetail\(string='([^']+)'");
        final match = regex.firstMatch(err.response!.data.toString());

        if (match != null) {
          errorMessage = match.group(1) ?? errorMessage;
          // print(errorMessage); // Output: Image failed to upload
        }
      }
    }

    log(err.toString(), stackTrace: err.stackTrace);
    handler.resolve(
      Response(
        requestOptions: err.requestOptions,
        data: ApiError(error: errorMessage),
        statusCode: err.response?.statusCode,
      ),
    );
  }
}

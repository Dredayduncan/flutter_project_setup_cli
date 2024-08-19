import 'package:dio/dio.dart';

extension DioExceptionsExtension on DioException {
  bool get isTokenExpiry {
    return response?.statusCode == 403 &&
        response?.data is Map<String, dynamic> &&
        ((response!.data as Map<String, dynamic>)['detail'] ==
                'Token is invalid or expired' ||
            ((response!.data as Map<String, dynamic>).containsKey('code') &&
                (response!.data as Map<String, dynamic>)['code'] == 'token_not_valid'));
  }
}

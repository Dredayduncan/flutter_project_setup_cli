import 'dart:convert';

import '../../../models/auth_models/token_model.dart';
import '../../../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../api_utils/api_result_model.dart';

class TokenStorageService {
  const TokenStorageService(this._secureStorageInstance, this._authService);

  final FlutterSecureStorage _secureStorageInstance;
  final AuthService _authService;
  final _tokenKey = 'token';

  Future<void> storeToken(TokenModel token) async {
    await _secureStorageInstance.write(
      key: _tokenKey,
      value: jsonEncode(
        token.toJson(),
      ),
    );
  }

  Future<TokenModel?> getToken() async {
    final encodedToken = await _secureStorageInstance.read(key: _tokenKey);

    if (encodedToken == null) {
      return null;
    }
    return TokenModel.fromJson(
        jsonDecode(encodedToken) as Map<String, dynamic>);
  }

  Future<void> deleteToken() async {
    await _secureStorageInstance.delete(key: _tokenKey);
  }

  Future<ApiResult<TokenModel, String>> refreshUserToken({
    ValueChanged<TokenModel>? onSuccess,
    ValueChanged<String>? onError,
  }) async {
    final token = await getToken();

    if (token == null) {
      const error = 'Token not found';
      onError?.call(error);
      return ApiError(error: error);
    }

    final refreshTokenResult = await _authService.refreshToken(
      {'refresh': token.refreshToken},
    );

    // check if an error occurred meaning the refresh token is invalid or expired
    if (refreshTokenResult.isErrorPresent) {
      // delete the user's tokens from storage
      await deleteToken();

      onError?.call(refreshTokenResult.getErrorMessage.toString());

      return ApiError(error: refreshTokenResult.getErrorMessage.toString());
    }

    final newTokenModel =
        refreshTokenResult.getData ?? const TokenModel.initial();

    // store the new token model
    await storeToken(newTokenModel);

    onSuccess?.call(newTokenModel);
    return ApiData(data: newTokenModel);
  }
}

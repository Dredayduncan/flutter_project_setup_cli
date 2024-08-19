import '../api_utils/api_result_model.dart';
import '../api_utils/api_service.dart';
import '../models/auth_models/token_model.dart';

class AuthService extends ApiService {
  AuthService({super.dio});

  Future<ApiResult<TokenModel, String>> refreshToken(
    Map<String, dynamic> data,
  ) async {
    // TODO: Implement this method
    throw UnimplementedError();
    
    // return post(
    //   '/', //TODO: Add your path
    //   (data) => TokenModel.fromJson(data as Map<String, dynamic>),
    //   data: data,
    // );
  }
}

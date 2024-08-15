import 'package:equatable/equatable.dart';

class TokenModel extends Equatable {

  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
  });

  const TokenModel.initial({this.refreshToken = '', this.accessToken = ''});

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access'].toString(),
      refreshToken: json['refresh'].toString(),
    );
  }
  final String accessToken;
  final String refreshToken;

  @override
  List<Object> get props => [accessToken, refreshToken];


  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
    };
  }

  TokenModel copyWith({
    String? accessToken,
    String? refreshToken,
  }) {
    return TokenModel(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  Map<String, String> get toHeader =>
      {'Authorization': 'Bearer $accessToken'};
}

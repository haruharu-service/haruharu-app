import 'package:dio/dio.dart';
import '../api/api_client.dart';

class TokenResponse {
  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }
}

class AuthRequests {
  static Future<TokenResponse> loginRequest({
    required String loginId,
    required String password,
  }) async {
    final client = ApiClient.instance;
    final response = await client.dio.post(
      '/v1/auth/login',
      data: {
        'loginId': loginId,
        'password': password,
      },
      options: Options(extra: {'skipAuth': true}),
    );

    final tokenData = _extractData(response.data);
    if (tokenData is Map<String, dynamic>) {
      final token = TokenResponse.fromJson(tokenData);
      if (token.accessToken.isEmpty || token.refreshToken.isEmpty) {
        throw ApiError(message: '토큰 응답이 비어 있습니다');
      }
      return token;
    }
    throw ApiError(message: '로그인 응답이 올바르지 않습니다');
  }

  static Future<TokenResponse> reissueTokenRequest({
    required String refreshToken,
  }) async {
    final client = ApiClient.instance;
    final response = await client.dio.post(
      '/v1/auth/reissue',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {'skipAuth': true}),
    );
    final tokenData = _extractData(response.data);
    if (tokenData is Map<String, dynamic>) {
      final token = TokenResponse.fromJson(tokenData);
      if (token.accessToken.isEmpty || token.refreshToken.isEmpty) {
        throw ApiError(message: '토큰 재발급 응답이 비어 있습니다');
      }
      return token;
    }
    throw ApiError(message: '토큰 재발급 응답이 올바르지 않습니다');
  }

  static Future<void> logoutRequest({String? accessToken}) async {
    final client = ApiClient.instance;
    final options = accessToken == null
        ? null
        : Options(headers: {'Authorization': 'Bearer $accessToken'});
    await client.dio.post(
      '/v1/auth/logout',
      data: {},
      options: options,
    );
  }
}

dynamic _extractData(dynamic responseData) {
  if (responseData is Map && responseData.containsKey('data')) {
    return responseData['data'];
  }
  return responseData;
}

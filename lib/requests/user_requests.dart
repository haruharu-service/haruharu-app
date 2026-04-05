import 'package:dio/dio.dart';
import '../api/api_client.dart';

class UserRequests {
  static Future<int> signupRequest({
    required Map<String, dynamic> data,
  }) async {
    final client = ApiClient.instance;
    final response = await client.dio.post(
      '/v1/members/sign-up',
      data: data,
      options: Options(extra: {'skipAuth': true}),
    );
    final value = _extractData(response.data);
    if (value is int) {
      return value;
    }
    throw ApiError(message: '회원가입 응답이 올바르지 않습니다');
  }

  static Future<bool> checkLoginIdAvailabilityRequest({
    required String loginId,
  }) async {
    final client = ApiClient.instance;
    final response = await client.dio.get(
      '/v1/members/login-id',
      queryParameters: {'loginId': loginId},
      options: Options(extra: {'skipAuth': true}),
    );
    final value = _extractData(response.data);
    if (value is bool) {
      return value;
    }
    throw ApiError(message: '아이디 중복 확인 응답이 올바르지 않습니다');
  }

  static Future<bool> checkNicknameAvailabilityRequest({
    required String nickname,
  }) async {
    final client = ApiClient.instance;
    final response = await client.dio.get(
      '/v1/members/nickname',
      queryParameters: {'nickname': nickname},
      options: Options(extra: {'skipAuth': true}),
    );
    final value = _extractData(response.data);
    if (value is bool) {
      return value;
    }
    throw ApiError(message: '닉네임 중복 확인 응답이 올바르지 않습니다');
  }
}

dynamic _extractData(dynamic responseData) {
  if (responseData is Map && responseData.containsKey('data')) {
    return responseData['data'];
  }
  return responseData;
}

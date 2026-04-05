import 'package:dio/dio.dart';
import '../api/api_client.dart';

class MemberRequests {
  static Future<Map<String, dynamic>> getProfileRequest() async {
    final client = ApiClient.instance;
    final response = await client.dio.get('/v1/members');
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiError(message: '프로필 응답이 올바르지 않습니다');
  }

  static Future<Map<String, dynamic>> updateProfileRequest({
    required Map<String, dynamic> data,
  }) async {
    final client = ApiClient.instance;
    final response = await client.dio.patch('/v1/members', data: data);
    final result = _extractData(response.data);
    if (result is Map<String, dynamic>) {
      return result;
    }
    throw ApiError(message: '프로필 수정 응답이 올바르지 않습니다');
  }

  static Future<void> updatePreferenceRequest({
    required Map<String, dynamic> data,
  }) async {
    final client = ApiClient.instance;
    await client.dio.patch('/v1/members/preferences', data: data);
  }

  static Future<void> deleteMemberRequest() async {
    final client = ApiClient.instance;
    await client.dio.delete('/v1/members');
  }
}

dynamic _extractData(dynamic responseData) {
  if (responseData is Map && responseData.containsKey('data')) {
    return responseData['data'];
  }
  return responseData;
}

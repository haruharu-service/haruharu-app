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

  static Future<List<Category>> getCategoriesRequest() async {
    final client = ApiClient.instance;
    final response = await client.dio.get(
      '/v1/categories',
    );
    // ignore: avoid_print
    print('raw response: ${response.data}');
    final value = _extractData(response.data);
    // ignore: avoid_print
    print('data extracted: $value');
    final rawCategories = value is Map ? value['categories'] : value;
    if (rawCategories is List) {
      final result = rawCategories
          .whereType<Map>()
          .map((item) => Category.fromJson(item))
          .toList();
      // Debug: log summary for console verification.
      final summary = result
          .map((c) => '${c.name}(${c.groups.length})')
          .join(', ');
      // ignore: avoid_print
      print('categories loaded: ${result.length} -> [$summary]');
      for (final category in result) {
        // ignore: avoid_print
        print(
          'category ${category.name}: groups=${category.groups.length} -> '
          '${category.groups.map((g) => g.name).join(', ')}',
        );
        for (final group in category.groups) {
          // ignore: avoid_print
          print(
            '  group ${group.name}: topics=${group.topics.length} -> '
            '${group.topics.map((t) => t.name).join(', ')}',
          );
        }
      }
      return result;
    }
    throw ApiError(message: '카테고리 목록 응답이 올바르지 않습니다');
  }
}

class Category {
  Category({
    required this.id,
    required this.name,
    required this.groups,
  });

  final int id;
  final String name;
  final List<CategoryGroup> groups;

  factory Category.fromJson(Map<dynamic, dynamic> json) {
    final groups = json['groups'];
    return Category(
      id: json['id'] is int ? json['id'] as int : 0,
      name: json['name'] is String ? json['name'] as String : '',
      groups: groups is List
          ? groups.whereType<Map>().map((item) => CategoryGroup.fromJson(item)).toList()
          : const [],
    );
  }
}

class CategoryGroup {
  CategoryGroup({
    required this.id,
    required this.name,
    required this.topics,
  });

  final int id;
  final String name;
  final List<CategoryTopic> topics;

  factory CategoryGroup.fromJson(Map<dynamic, dynamic> json) {
    final topics = json['topics'];
    return CategoryGroup(
      id: json['id'] is int ? json['id'] as int : 0,
      name: json['name'] is String ? json['name'] as String : '',
      topics: topics is List
          ? topics.whereType<Map>().map((item) => CategoryTopic.fromJson(item)).toList()
          : const [],
    );
  }
}

class CategoryTopic {
  CategoryTopic({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory CategoryTopic.fromJson(Map<dynamic, dynamic> json) {
    return CategoryTopic(
      id: json['id'] is int ? json['id'] as int : 0,
      name: json['name'] is String ? json['name'] as String : '',
    );
  }
}

dynamic _extractData(dynamic responseData) {
  if (responseData is Map && responseData.containsKey('data')) {
    return responseData['data'];
  }
  return responseData;
}

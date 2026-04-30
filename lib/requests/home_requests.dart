import 'package:dio/dio.dart';

import '../account/account_state.dart';
import '../api/api_client.dart';

class HomeRequests {
  static Future<MemberProfileResponse> fetchProfile() async {
    final response = await ApiClient.instance.dio.get('/v1/members');
    final data = _extractMap(response.data);
    return MemberProfileResponse.fromJson(data);
  }

  static Future<StreakResponse> fetchStreak() async {
    final response = await ApiClient.instance.dio.get('/v1/streaks');
    final data = _extractMap(response.data);
    return StreakResponse.fromJson(data);
  }

  static Future<List<TodayProblemResponse>> fetchTodayProblems() async {
    final response = await ApiClient.instance.dio.get(
      '/v1/daily-problem/today',
    );
    final data = _extractData(response.data);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => TodayProblemResponse.fromJson(_asStringMap(item)))
          .toList();
    }
    throw ApiError(message: '오늘의 문제 응답이 올바르지 않습니다');
  }

  static Future<List<DailyProblemPreviewResponse>> fetchDailyProblemsByDate({
    required DateTime date,
  }) async {
    final response = await ApiClient.instance.dio.get(
      '/v1/daily-problem',
      queryParameters: {'date': _formatDate(date)},
    );
    final data = _extractData(response.data);
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => DailyProblemPreviewResponse.fromJson(_asStringMap(item)),
          )
          .toList();
    }
    throw ApiError(message: '날짜별 문제 응답이 올바르지 않습니다');
  }

  static Future<DailyProblemDetailResponse> fetchProblemDetail({
    required int dailyProblemId,
  }) async {
    final response = await ApiClient.instance.dio.get(
      '/v1/daily-problem/$dailyProblemId',
    );
    final data = _extractMap(response.data);
    return DailyProblemDetailResponse.fromJson(data);
  }

  static Future<SubmissionResponse> submitSolution({
    required int dailyProblemId,
    required String userAnswer,
  }) async {
    final response = await ApiClient.instance.dio.post(
      '/v1/daily-problem/$dailyProblemId/submissions',
      data: {'userAnswer': userAnswer},
    );
    final data = _extractMap(response.data);
    return SubmissionResponse.fromJson(data);
  }

  static Future<void> updateProfile({
    required String nickname,
    String? profileImageKey,
  }) async {
    final data = <String, dynamic>{'nickname': nickname};
    if (profileImageKey != null) {
      data['profileImageKey'] = profileImageKey;
    }
    await ApiClient.instance.dio.patch('/v1/members', data: data);
  }

  static Future<PresignedUrlResponse> createProfileImageUploadUrl({
    required String fileName,
  }) async {
    final response = await ApiClient.instance.dio.post(
      '/v1/storage/presigned-url',
      data: {'fileName': fileName, 'uploadType': 'PROFILE_IMAGE'},
    );
    final data = _extractMap(response.data);
    return PresignedUrlResponse.fromJson(data);
  }

  static Future<void> uploadFileToPresignedUrl({
    required String presignedUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    await Dio().put(
      presignedUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {'Content-Length': bytes.length, 'Content-Type': contentType},
      ),
    );
  }

  static Future<void> completeUpload({required String objectKey}) async {
    await ApiClient.instance.dio.post(
      '/v1/storage/upload-complete',
      data: {'objectKey': objectKey},
    );
  }

  static Future<void> appendPreference({
    required int categoryTopicId,
    required String difficulty,
  }) async {
    await ApiClient.instance.dio.post(
      '/v1/members/preferences',
      data: {'categoryTopicId': categoryTopicId, 'difficulty': difficulty},
    );
  }

  static Future<void> updatePreference({
    required int preferenceId,
    required int categoryTopicId,
    required String difficulty,
  }) async {
    await ApiClient.instance.dio.patch(
      '/v1/members/preferences/$preferenceId',
      data: {'categoryTopicId': categoryTopicId, 'difficulty': difficulty},
    );
  }

  static Future<CategoryListResponse> fetchCategories() async {
    final response = await ApiClient.instance.dio.get('/v1/categories');
    final data = _extractMap(response.data);
    return CategoryListResponse.fromJson(data);
  }

  static Future<void> syncDeviceToken({required String deviceToken}) async {
    await ApiClient.instance.dio.patch(
      '/v1/members/devices',
      data: {'deviceToken': deviceToken},
    );
  }

  static Future<void> deleteDeviceToken({required String deviceToken}) async {
    await ApiClient.instance.dio.delete(
      '/v1/members/devices',
      queryParameters: {'deviceToken': deviceToken},
    );
  }

  static Future<void> withdrawMember() async {
    await ApiClient.instance.dio.delete('/v1/members');
  }
}

class MemberProfileResponse {
  const MemberProfileResponse({
    required this.loginId,
    required this.nickname,
    required this.createdAt,
    required this.profileImageUrl,
    required this.preferences,
  });

  final String loginId;
  final String nickname;
  final DateTime? createdAt;
  final String? profileImageUrl;
  final List<AccountPreference> preferences;

  factory MemberProfileResponse.fromJson(Map<String, dynamic> json) {
    final preferences = json['memberPreferences'];
    return MemberProfileResponse(
      loginId: json['loginId'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      createdAt: _asDate(json['createdAt']),
      profileImageUrl: json['profileImageUrl'] as String?,
      preferences: preferences is List
          ? preferences
                .whereType<Map>()
                .map((item) => _preferenceFromJson(_asStringMap(item)))
                .toList()
          : const [],
    );
  }
}

class PresignedUrlResponse {
  const PresignedUrlResponse({
    required this.presignedUrl,
    required this.objectKey,
  });

  final String presignedUrl;
  final String objectKey;

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      presignedUrl: json['presignedUrl'] as String? ?? '',
      objectKey: json['objectKey'] as String? ?? '',
    );
  }
}

class DailyProblemPreviewResponse {
  const DailyProblemPreviewResponse({
    required this.id,
    required this.difficulty,
    required this.categoryTopic,
    required this.title,
    required this.isSolved,
  });

  final int id;
  final String difficulty;
  final String categoryTopic;
  final String title;
  final bool isSolved;

  factory DailyProblemPreviewResponse.fromJson(Map<String, dynamic> json) {
    return DailyProblemPreviewResponse(
      id: _asInt(json['id']),
      difficulty: json['difficulty'] as String? ?? '',
      categoryTopic: json['categoryTopic'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isSolved: json['isSolved'] == true,
    );
  }
}

class CategoryListResponse {
  const CategoryListResponse({required this.categories});

  final List<CategoryResponse> categories;

  factory CategoryListResponse.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'];
    return CategoryListResponse(
      categories: categories is List
          ? categories
                .whereType<Map>()
                .map((item) => CategoryResponse.fromJson(_asStringMap(item)))
                .toList()
          : const [],
    );
  }

  List<CategoryTopicResponse> get allTopics {
    return [
      for (final category in categories)
        for (final group in category.groups) ...group.topics,
    ];
  }
}

class CategoryResponse {
  const CategoryResponse({
    required this.id,
    required this.name,
    required this.groups,
  });

  final int id;
  final String name;
  final List<CategoryGroupResponse> groups;

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    final groups = json['groups'];
    return CategoryResponse(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      groups: groups is List
          ? groups
                .whereType<Map>()
                .map(
                  (item) => CategoryGroupResponse.fromJson(_asStringMap(item)),
                )
                .toList()
          : const [],
    );
  }
}

class CategoryGroupResponse {
  const CategoryGroupResponse({
    required this.id,
    required this.name,
    required this.topics,
  });

  final int id;
  final String name;
  final List<CategoryTopicResponse> topics;

  factory CategoryGroupResponse.fromJson(Map<String, dynamic> json) {
    final topics = json['topics'];
    return CategoryGroupResponse(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      topics: topics is List
          ? topics
                .whereType<Map>()
                .map(
                  (item) => CategoryTopicResponse.fromJson(_asStringMap(item)),
                )
                .toList()
          : const [],
    );
  }
}

class CategoryTopicResponse {
  const CategoryTopicResponse({required this.id, required this.name});

  final int id;
  final String name;

  factory CategoryTopicResponse.fromJson(Map<String, dynamic> json) {
    return CategoryTopicResponse(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
    );
  }
}

class StreakResponse {
  const StreakResponse({
    required this.currentStreak,
    required this.maxStreak,
    required this.weeklySolvedStatus,
  });

  final int currentStreak;
  final int maxStreak;
  final List<WeeklySolvedStatusResponse> weeklySolvedStatus;

  factory StreakResponse.fromJson(Map<String, dynamic> json) {
    final weeklyStatus = json['weeklySolvedStatus'];
    return StreakResponse(
      currentStreak: _asInt(json['currentStreak']),
      maxStreak: _asInt(json['maxStreak']),
      weeklySolvedStatus: weeklyStatus is List
          ? weeklyStatus
                .whereType<Map>()
                .map(
                  (item) =>
                      WeeklySolvedStatusResponse.fromJson(_asStringMap(item)),
                )
                .toList()
          : const [],
    );
  }
}

class WeeklySolvedStatusResponse {
  const WeeklySolvedStatusResponse({
    required this.date,
    required this.isSolved,
  });

  final DateTime? date;
  final bool isSolved;

  factory WeeklySolvedStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    return WeeklySolvedStatusResponse(
      date: rawDate is String ? DateTime.tryParse(rawDate) : null,
      isSolved: json['isSolved'] == true,
    );
  }
}

class TodayProblemResponse {
  const TodayProblemResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.categoryTopicName,
    required this.isSolved,
  });

  final int id;
  final String title;
  final String description;
  final String difficulty;
  final String categoryTopicName;
  final bool isSolved;

  factory TodayProblemResponse.fromJson(Map<String, dynamic> json) {
    return TodayProblemResponse(
      id: _asInt(json['id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      categoryTopicName: json['categoryTopicName'] as String? ?? '',
      isSolved: json['isSolved'] == true,
    );
  }
}

class DailyProblemDetailResponse {
  const DailyProblemDetailResponse({
    required this.id,
    required this.difficulty,
    required this.categoryTopic,
    required this.assignedAt,
    required this.title,
    required this.description,
    required this.userAnswer,
    required this.submittedAt,
    required this.aiAnswer,
  });

  final int id;
  final String difficulty;
  final String categoryTopic;
  final DateTime? assignedAt;
  final String title;
  final String description;
  final String? userAnswer;
  final DateTime? submittedAt;
  final String? aiAnswer;

  factory DailyProblemDetailResponse.fromJson(Map<String, dynamic> json) {
    return DailyProblemDetailResponse(
      id: _asInt(json['id']),
      difficulty: json['difficulty'] as String? ?? '',
      categoryTopic: json['categoryTopic'] as String? ?? '',
      assignedAt: _asDate(json['assignedAt']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      userAnswer: json['userAnswer'] as String?,
      submittedAt: _asDate(json['submittedAt']),
      aiAnswer: json['aiAnswer'] as String?,
    );
  }

  DailyProblemDetailResponse copyWithSubmission(SubmissionResponse submission) {
    return DailyProblemDetailResponse(
      id: id,
      difficulty: difficulty,
      categoryTopic: categoryTopic,
      assignedAt: assignedAt,
      title: title,
      description: description,
      userAnswer: submission.userAnswer,
      submittedAt: submission.submittedAt,
      aiAnswer: submission.aiAnswer,
    );
  }
}

class SubmissionResponse {
  const SubmissionResponse({
    required this.submissionId,
    required this.dailyProblemId,
    required this.userAnswer,
    required this.submittedAt,
    required this.isOnTime,
    required this.aiAnswer,
  });

  final int submissionId;
  final int dailyProblemId;
  final String userAnswer;
  final DateTime? submittedAt;
  final bool isOnTime;
  final String aiAnswer;

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) {
    return SubmissionResponse(
      submissionId: _asInt(json['submissionId']),
      dailyProblemId: _asInt(json['dailyProblemId']),
      userAnswer: json['userAnswer'] as String? ?? '',
      submittedAt: _asDate(json['submittedAt']),
      isOnTime: json['isOnTime'] == true,
      aiAnswer: json['aiAnswer'] as String? ?? '',
    );
  }
}

AccountPreference _preferenceFromJson(Map<String, dynamic> json) {
  return AccountPreference(
    preferenceId: _asInt(json['preferenceId']),
    categoryTopicName: json['categoryTopicName'] as String? ?? '',
    difficulty: json['difficulty'] as String? ?? '',
  );
}

Map<String, dynamic> _extractMap(dynamic responseData) {
  final data = _extractData(responseData);
  if (data is Map) {
    return _asStringMap(data);
  }
  throw ApiError(message: 'API 응답이 올바르지 않습니다');
}

dynamic _extractData(dynamic responseData) {
  if (responseData is Map && responseData.containsKey('data')) {
    return responseData['data'];
  }
  return responseData;
}

Map<String, dynamic> _asStringMap(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _asDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

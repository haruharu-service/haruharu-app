import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiError implements Exception {
  ApiError({required this.message, this.code, this.details});

  final String message;
  final String? code;
  final dynamic details;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String baseUrl = 'https://api-staging.haruharu.online/';

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {
        'Content-Type': 'application/json',
      },
    ),
  );

  void initialize() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth) {
            final token = await TokenStorage.instance.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final response = error.response;
          final requestOptions = error.requestOptions;
          final skipAuth = requestOptions.extra['skipAuth'] == true;

          if (skipAuth) {
            return handler.reject(_toDioException(error, requestOptions, response));
          }

          if (response?.statusCode == 401 && requestOptions.extra['_retry'] != true) {
            requestOptions.extra['_retry'] = true;
            final refreshToken = await TokenStorage.instance.getRefreshToken();
            if (refreshToken == null || refreshToken.isEmpty) {
              await TokenStorage.instance.clearTokens();
              return handler.reject(_toDioException(error, requestOptions, response));
            }

            try {
              final refreshResponse = await dio.post(
                '/v1/auth/reissue',
                data: {'refreshToken': refreshToken},
                options: Options(extra: {'skipAuth': true}),
              );

              final data = refreshResponse.data;
              final tokenData = data is Map ? data['data'] : null;
              final newAccessToken =
                  tokenData is Map ? tokenData['accessToken'] as String? : null;
              final newRefreshToken =
                  tokenData is Map ? tokenData['refreshToken'] as String? : null;

              if (newAccessToken == null || newRefreshToken == null) {
                await TokenStorage.instance.clearTokens();
                return handler.reject(_toDioException(error, requestOptions, response));
              }

              await TokenStorage.instance.setTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(requestOptions);
              return handler.resolve(retryResponse);
            } catch (refreshError) {
              await TokenStorage.instance.clearTokens();
              return handler.reject(
                _toDioException(refreshError, requestOptions, response),
              );
            }
          }

          return handler.reject(_toDioException(error, requestOptions, response));
        },
      ),
    );
  }

  DioException _toDioException(
    Object error,
    RequestOptions requestOptions, [
    Response<dynamic>? response,
  ]) {
    if (error is DioException) {
      final apiError = _toApiError(error);
      return DioException(
        requestOptions: error.requestOptions,
        response: error.response ?? response,
        type: error.type,
        error: apiError,
        message: apiError.message,
      );
    }

    final apiError = _toApiError(error);
    return DioException(
      requestOptions: requestOptions,
      response: response,
      type: DioExceptionType.unknown,
      error: apiError,
      message: apiError.message,
    );
  }

  ApiError _toApiError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final errorData = data['error'];
        final message = (errorData is Map && errorData['message'] is String)
            ? errorData['message'] as String
            : (data['message'] is String ? data['message'] as String : '요청에 실패했습니다');
        final code =
            (errorData is Map && errorData['code'] is String) ? errorData['code'] as String : null;
        final details = (errorData is Map) ? errorData['data'] : data['details'];
        return ApiError(message: message, code: code, details: details);
      }
      return ApiError(message: error.message ?? '요청에 실패했습니다');
    }

    if (error is ApiError) {
      return error;
    }

    return ApiError(message: '요청에 실패했습니다');
  }
}

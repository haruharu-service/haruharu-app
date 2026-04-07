import 'package:dio/dio.dart';
import '../api/api_client.dart';

class QuoteRequests {
  static Future<List<String>> fetchQuotes() async {
    final client = ApiClient.instance;
    final response = await client.dio.get(
      '/v1/quotes',
      options: Options(extra: {'skipAuth': true}),
    );
    // ignore: avoid_print
    print('quotes raw: ${response.data}');

    final data = response.data;
    if (data is Map) {
      final result = data['result'];
      final payload = data['data'];
      if (result == 'SUCCESS' && payload is List) {
        final quotes = payload.whereType<String>().toList();
        if (quotes.isNotEmpty) {
          return quotes;
        }
      }
    }

    throw ApiError(message: '문구 응답이 올바르지 않습니다');
  }
}

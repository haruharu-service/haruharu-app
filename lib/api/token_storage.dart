import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static final TokenStorage instance = TokenStorage._();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _loginDatesKey = 'login_dates';
  static const _pushEnabledKey = 'push_enabled';
  static const _deviceTokenKey = 'device_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> recordLoginToday() async {
    final today = _formatDate(DateTime.now());
    final dates = await getLoginDates();
    if (dates.contains(today)) return;
    dates.add(today);
    dates.sort();
    await _storage.write(key: _loginDatesKey, value: dates.join(','));
  }

  Future<List<String>> getLoginDates() async {
    final value = await _storage.read(key: _loginDatesKey);
    if (value == null || value.isEmpty) return [];
    return value.split(',').where((date) => date.isNotEmpty).toList();
  }

  Future<void> setPushEnabled(bool enabled) async {
    await _storage.write(
      key: _pushEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> getPushEnabled() async {
    final value = await _storage.read(key: _pushEnabledKey);
    return value == 'true';
  }

  Future<void> setDeviceToken(String token) async {
    await _storage.write(key: _deviceTokenKey, value: token);
  }

  Future<String?> getDeviceToken() async {
    return _storage.read(key: _deviceTokenKey);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

import 'package:flutter/foundation.dart';

class AccountUser {
  const AccountUser({
    required this.loginId,
    this.nickname,
    this.createdAt,
    this.profileImageUrl,
    this.preferences = const [],
  });

  final String loginId;
  final String? nickname;
  final DateTime? createdAt;
  final String? profileImageUrl;
  final List<AccountPreference> preferences;
}

class AccountPreference {
  const AccountPreference({
    required this.preferenceId,
    required this.categoryTopicName,
    required this.difficulty,
  });

  final int preferenceId;
  final String categoryTopicName;
  final String difficulty;
}

class AccountState extends ValueNotifier<AccountUser?> {
  AccountState._() : super(null);

  static final AccountState instance = AccountState._();

  AccountUser? get currentUser => value;

  void setLoggedInUser({
    required String loginId,
    String? nickname,
    DateTime? createdAt,
    String? profileImageUrl,
    List<AccountPreference> preferences = const [],
  }) {
    value = AccountUser(
      loginId: loginId,
      nickname: nickname,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl,
      preferences: preferences,
    );
  }

  void clear() {
    value = null;
  }
}

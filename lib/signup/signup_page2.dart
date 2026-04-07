import 'dart:async';

import 'package:flutter/material.dart';
import '../requests/user_requests.dart';
import 'signup_widgets.dart';

class SignupPage2 extends StatefulWidget {
  const SignupPage2({
    super.key,
    required this.onNext,
    required this.onPrev,
    required this.onLogin,
  });

  final void Function(String nickname) onNext;
  final VoidCallback onPrev;
  final VoidCallback onLogin;

  @override
  State<SignupPage2> createState() => _SignupPage2State();
}

class _SignupPage2State extends State<SignupPage2> {
  static const _debounceDuration = Duration(milliseconds: 400);

  final TextEditingController _nicknameController = TextEditingController();
  Timer? _debounce;
  bool? _isNicknameAvailable;
  bool _isCheckingNickname = false;
  String? _nicknameError;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nicknameController.dispose();
    super.dispose();
  }

  void _onNicknameChanged() {
    final nickname = _nicknameController.text.trim();
    _debounce?.cancel();

    if (nickname.isEmpty) {
      setState(() {
        _isCheckingNickname = false;
        _isNicknameAvailable = null;
        _nicknameError = null;
      });
      return;
    }

    setState(() {
      _isCheckingNickname = true;
      _isNicknameAvailable = null;
      _nicknameError = null;
    });

    _debounce = Timer(_debounceDuration, () {
      _checkNicknameAvailability(nickname);
    });
  }

  Future<void> _checkNicknameAvailability(String nickname) async {
    try {
      final available = await UserRequests.checkNicknameAvailabilityRequest(
        nickname: nickname,
      );
      // 임시 로그: 콘솔에서 닉네임 중복 여부 확인용
      // TODO: 확인 후 제거
      // ignore: avoid_print
      print('nickname="$nickname" available=$available');
      if (!mounted) return;
      if (_nicknameController.text.trim() != nickname) return;
      setState(() {
        _isCheckingNickname = false;
        _isNicknameAvailable = available;
      });
    } catch (_) {
      if (!mounted) return;
      if (_nicknameController.text.trim() != nickname) return;
      setState(() {
        _isCheckingNickname = false;
        _nicknameError = '닉네임 확인에 실패했어요';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _nicknameController.text.trim();
    final nicknameStatusText = _nicknameError ??
        (_isCheckingNickname
            ? '닉네임 확인 중...'
            : _isNicknameAvailable == null
                ? null
                : _isNicknameAvailable == true
                    ? '사용 가능한 닉네임입니다'
                    : '이미 사용 중인 닉네임입니다');

    final nicknameStatusColor = _nicknameError != null
        ? const Color(0xFFFF6B6B)
        : _isCheckingNickname
            ? textMuted
            : _isNicknameAvailable == true
                ? const Color(0xFF2DBE7C)
                : const Color(0xFFFF6B6B);

    final canProceed = nickname.isNotEmpty &&
        _isNicknameAvailable == true &&
        !_isCheckingNickname;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '프로필을\n설정해볼까요?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
          ),
          const SizedBox(height: 28),
          const FieldLabel(text: '닉네임'),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            style: fieldTextStyle(),
            cursorColor: primaryBlue,
            decoration: buildFieldDecoration('활동할 닉네임을 입력하세요'),
          ),
          if (nicknameStatusText != null) ...[
            const SizedBox(height: 8),
            Text(
              nicknameStatusText,
              style: TextStyle(
                color: nicknameStatusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 260),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: canProceed
                  ? () {
                      widget.onNext(_nicknameController.text.trim());
                    }
                  : null,
              child: const Text(
                '다음 단계로',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: widget.onPrev,
              child: Text(
                '이전 단계로',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: widget.onLogin,
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: textMuted),
                  children: const [
                    TextSpan(text: '이미 계정이 있으신가요? '),
                    TextSpan(
                      text: '로그인',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

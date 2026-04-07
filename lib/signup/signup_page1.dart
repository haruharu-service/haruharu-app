import 'dart:async';

import 'package:flutter/material.dart';
import '../requests/user_requests.dart';
import 'signup_widgets.dart';

class SignupPage1 extends StatefulWidget {
  const SignupPage1({super.key, required this.onNext, required this.onLogin});

  final void Function(String loginId, String password) onNext;
  final VoidCallback onLogin;

  @override
  State<SignupPage1> createState() => _SignupPage1State();
}

class _SignupPage1State extends State<SignupPage1> {
  static const _debounceDuration = Duration(milliseconds: 400);

  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  Timer? _debounce;
  bool? _isLoginIdAvailable;
  bool _isCheckingLoginId = false;
  String? _loginIdError;
  String? _passwordError;
  String? _passwordConfirmError;

  @override
  void initState() {
    super.initState();
    _loginIdController.addListener(_onLoginIdChanged);
    _passwordController.addListener(_validatePasswords);
    _passwordConfirmController.addListener(_validatePasswords);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _loginIdController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _onLoginIdChanged() {
    final loginId = _loginIdController.text.trim();
    _debounce?.cancel();

    if (loginId.isEmpty) {
      setState(() {
        _isCheckingLoginId = false;
        _isLoginIdAvailable = null;
        _loginIdError = null;
      });
      return;
    }

    setState(() {
      _isCheckingLoginId = true;
      _isLoginIdAvailable = null;
      _loginIdError = null;
    });

    _debounce = Timer(_debounceDuration, () {
      _checkLoginIdAvailability(loginId);
    });
  }

  Future<void> _checkLoginIdAvailability(String loginId) async {
    try {
      final available = await UserRequests.checkLoginIdAvailabilityRequest(
        loginId: loginId,
      );
      // 임시 로그: 콘솔에서 아이디 중복 여부 확인용
      // TODO: 확인 후 제거
      // ignore: avoid_print
      print('loginId="$loginId" available=$available');
      if (!mounted) return;
      if (_loginIdController.text.trim() != loginId) return;
      setState(() {
        _isCheckingLoginId = false;
        _isLoginIdAvailable = available;
      });
    } catch (_) {
      if (!mounted) return;
      if (_loginIdController.text.trim() != loginId) return;
      setState(() {
        _isCheckingLoginId = false;
        _loginIdError = '아이디 확인에 실패했어요';
      });
    }
  }

  void _validatePasswords() {
    final password = _passwordController.text;
    final confirm = _passwordConfirmController.text;
    final hasMinLength = password.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final passwordValid = hasMinLength && hasUpper && hasLower && hasDigit;

    setState(() {
      _passwordError = password.isEmpty
          ? null
          : passwordValid
              ? null
              : '8자 이상, 대소문자+숫자를 포함해 주세요';
      _passwordConfirmError = confirm.isEmpty
          ? null
          : (password == confirm ? null : '비밀번호가 일치하지 않아요');
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginId = _loginIdController.text.trim();
    final loginIdStatusText = _loginIdError ??
        (_isCheckingLoginId
            ? '아이디 확인 중...'
            : _isLoginIdAvailable == null
                ? null
                : _isLoginIdAvailable == true
                    ? '사용 가능한 아이디입니다'
                    : '이미 사용 중인 아이디입니다');

    final loginIdStatusColor = _loginIdError != null
        ? const Color(0xFFFF6B6B)
        : _isCheckingLoginId
            ? textMuted
            : _isLoginIdAvailable == true
                ? const Color(0xFF2DBE7C)
                : const Color(0xFFFF6B6B);

    final canProceed =
        loginId.isNotEmpty &&
        _isLoginIdAvailable == true &&
        !_isCheckingLoginId &&
        _passwordError == null &&
        _passwordConfirmError == null &&
        _passwordController.text.isNotEmpty &&
        _passwordConfirmController.text.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '반가워요!\n계정을 만들어주세요',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
          ),
          const SizedBox(height: 28),
          const FieldLabel(text: '아이디'),
          const SizedBox(height: 8),
          TextField(
            controller: _loginIdController,
            style: fieldTextStyle(),
            cursorColor: primaryBlue,
            decoration: buildFieldDecoration('아이디'),
          ),
          if (loginIdStatusText != null) ...[
            const SizedBox(height: 8),
            Text(
              loginIdStatusText,
              style: TextStyle(
                color: loginIdStatusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const FieldLabel(text: '비밀번호'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: fieldTextStyle(),
            cursorColor: primaryBlue,
            decoration: buildFieldDecoration('8자 이상, 대소문자+숫자 포함'),
          ),
          if (_passwordError != null) ...[
            const SizedBox(height: 8),
            Text(
              _passwordError!,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const FieldLabel(text: '비밀번호 확인'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordConfirmController,
            obscureText: true,
            style: fieldTextStyle(),
            cursorColor: primaryBlue,
            decoration: buildFieldDecoration('비밀번호를 다시 입력하세요'),
          ),
          if (_passwordConfirmError != null) ...[
            const SizedBox(height: 8),
            Text(
              _passwordConfirmError!,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 32),
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
                      widget.onNext(
                        _loginIdController.text.trim(),
                        _passwordController.text,
                      );
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

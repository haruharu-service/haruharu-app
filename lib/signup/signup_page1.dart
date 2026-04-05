import 'package:flutter/material.dart';
import 'signup_widgets.dart';

class SignupPage1 extends StatelessWidget {
  const SignupPage1({super.key, required this.onNext, required this.onLogin});

  final VoidCallback onNext;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
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
            style: fieldTextStyle(),
            cursorColor: primaryBlue,
            decoration: buildFieldDecoration('아이디'),
          ),
          const SizedBox(height: 20),
          const FieldLabel(text: '비밀번호'),
          const SizedBox(height: 8),
          TextField(
            obscureText: true,
            style: fieldTextStyle(),
            cursorColor: primaryBlue,
            decoration: buildFieldDecoration('8자 이상, 대소문자+숫자 포함'),
          ),
          const SizedBox(height: 20),
          const FieldLabel(text: '비밀번호 확인'),
          const SizedBox(height: 8),
          TextField(
            obscureText: true,
            style: fieldTextStyle(),
            cursorColor: primaryBlue,
            decoration: buildFieldDecoration('비밀번호를 다시 입력하세요'),
          ),
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
              onPressed: onNext,
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
              onTap: onLogin,
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

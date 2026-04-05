import 'package:flutter/material.dart';
import 'signup_widgets.dart';

class SignupPage2 extends StatelessWidget {
  const SignupPage2({
    super.key,
    required this.onNext,
    required this.onPrev,
    required this.onLogin,
  });

  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
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
            style: fieldTextStyle(),
            cursorColor: primaryBlue,
            decoration: buildFieldDecoration('활동할 닉네임을 입력하세요'),
          ),
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
              onTap: onPrev,
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

import 'package:flutter/material.dart';
import 'signup_widgets.dart';

class SignupPage3 extends StatelessWidget {
  const SignupPage3({super.key, required this.onPrev, required this.onLogin});

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
            '나에게 딱 맞는\n학습 설정',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle(text: '카테고리 선택'),
          const SizedBox(height: 8),
          const _StepLabel(text: '1. 분야'),
          const SizedBox(height: 8),
          _SelectBox(text: '분야를 선택하세요'),
          const SizedBox(height: 12),
          const _StepLabel(text: '2. 분류'),
          const SizedBox(height: 8),
          _SelectBox(text: '먼저 분야를 선택하세요'),
          const SizedBox(height: 12),
          const _StepLabel(text: '3. 주제'),
          const SizedBox(height: 8),
          _SelectBox(text: '분류를 먼저 선택하세요'),
          const SizedBox(height: 20),
          const _SectionTitle(text: '난이도 선택'),
          const SizedBox(height: 8),
          const _LevelCard(
            title: '쉬움',
            subtitle: '기초적인 개념과 간단한 문제',
          ),
          const SizedBox(height: 12),
          const _LevelCard(
            title: '보통',
            subtitle: '실무에 필요한 중급 수준의 문제',
          ),
          const SizedBox(height: 12),
          const _LevelCard(
            title: '어려움',
            subtitle: '심화 학습과 복잡한 문제',
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA7B6FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {},
              child: const Text(
                '하루하루 시작하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '분야와 난이도를 선택하면 시작할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF1A259),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: primaryBlue,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6EBF5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB7C0D9),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

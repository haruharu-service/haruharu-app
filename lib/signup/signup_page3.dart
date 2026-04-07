import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../requests/user_requests.dart';
import 'signup_widgets.dart';

class SignupPage3 extends StatefulWidget {
  const SignupPage3({
    super.key,
    required this.onPrev,
    required this.onLogin,
    required this.loginId,
    required this.password,
    required this.nickname,
  });

  final VoidCallback onPrev;
  final VoidCallback onLogin;
  final String? loginId;
  final String? password;
  final String? nickname;

  @override
  State<SignupPage3> createState() => _SignupPage3State();
}

class _SignupPage3State extends State<SignupPage3> {
  late final Future<List<Category>> _categoriesFuture;
  Category? _selectedCategory;
  CategoryGroup? _selectedGroup;
  CategoryTopic? _selectedTopic;
  String? _selectedLevel;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = UserRequests.getCategoriesRequest();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = widget.loginId != null &&
        widget.password != null &&
        widget.nickname != null &&
        _selectedTopic != null &&
        _selectedLevel != null &&
        !_isSubmitting;

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
          FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _StepLabel(text: '1. 분야'),
                    SizedBox(height: 8),
                    _SelectBox(text: '카테고리 불러오는 중...'),
                    SizedBox(height: 12),
                    _StepLabel(text: '2. 분류'),
                    SizedBox(height: 8),
                    _SelectBox(text: '먼저 분야를 선택하세요'),
                    SizedBox(height: 12),
                    _StepLabel(text: '3. 주제'),
                    SizedBox(height: 8),
                    _SelectBox(text: '분류를 먼저 선택하세요'),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '카테고리를 불러오지 못했습니다',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    _StepLabel(text: '1. 분야'),
                    SizedBox(height: 8),
                    _SelectBox(text: '분야를 선택하세요'),
                    SizedBox(height: 12),
                    _StepLabel(text: '2. 분류'),
                    SizedBox(height: 8),
                    _SelectBox(text: '먼저 분야를 선택하세요'),
                    SizedBox(height: 12),
                    _StepLabel(text: '3. 주제'),
                    SizedBox(height: 8),
                    _SelectBox(text: '분류를 먼저 선택하세요'),
                  ],
                );
              }

              final categories = snapshot.data ?? [];
              final groups = _selectedCategory?.groups ?? const <CategoryGroup>[];
              final topics = _selectedGroup?.topics ?? const <CategoryTopic>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepLabel(text: '1. 분야'),
                  const SizedBox(height: 8),
                  _SelectDropdown<Category>(
                    value: _selectedCategory,
                    hint: '분야를 선택하세요',
                    items: categories,
                    labelBuilder: (item) => item.name,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _selectedGroup = null;
                        _selectedTopic = null;
                      });
                      // ignore: avoid_print
                      print('selected category: ${value?.name}');
                    },
                  ),
                  const SizedBox(height: 12),
                  const _StepLabel(text: '2. 분류'),
                  const SizedBox(height: 8),
                  _SelectDropdown<CategoryGroup>(
                    value: _selectedGroup,
                    hint: _selectedCategory == null
                        ? '먼저 분야를 선택하세요'
                        : '분류를 선택하세요',
                    items: groups,
                    labelBuilder: (item) => item.name,
                    onChanged: _selectedCategory == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedGroup = value;
                              _selectedTopic = null;
                            });
                            // ignore: avoid_print
                            print('selected group: ${value?.name}');
                          },
                  ),
                  const SizedBox(height: 12),
                  const _StepLabel(text: '3. 주제'),
                  const SizedBox(height: 8),
                  _SelectDropdown<CategoryTopic>(
                    value: _selectedTopic,
                    hint: _selectedGroup == null ? '분류를 먼저 선택하세요' : '주제를 선택하세요',
                    items: topics,
                    labelBuilder: (item) => item.name,
                    onChanged: _selectedGroup == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedTopic = value;
                            });
                            // ignore: avoid_print
                            print('selected topic: ${value?.name}');
                          },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const _SectionTitle(text: '난이도 선택'),
          const SizedBox(height: 8),
          _LevelCard(
            title: '쉬움',
            subtitle: '기초적인 개념과 간단한 문제',
            isSelected: _selectedLevel == '쉬움',
            onTap: () {
              setState(() {
                _selectedLevel = '쉬움';
              });
            },
          ),
          const SizedBox(height: 12),
          _LevelCard(
            title: '보통',
            subtitle: '실무에 필요한 중급 수준의 문제',
            isSelected: _selectedLevel == '보통',
            onTap: () {
              setState(() {
                _selectedLevel = '보통';
              });
            },
          ),
          const SizedBox(height: 12),
          _LevelCard(
            title: '어려움',
            subtitle: '심화 학습과 복잡한 문제',
            isSelected: _selectedLevel == '어려움',
            onTap: () {
              setState(() {
                _selectedLevel = '어려움';
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA7B6FF),
                disabledBackgroundColor: const Color(0xFFD7DDF2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: canSubmit
                  ? () async {
                      setState(() {
                        _isSubmitting = true;
                      });
                      try {
                        final difficulty = _mapDifficulty(_selectedLevel);
                        if (difficulty == null) {
                          throw ApiError(message: '난이도 선택이 올바르지 않습니다');
                        }
                        await UserRequests.signupRequest(
                          data: {
                            'loginId': widget.loginId!,
                            'password': widget.password!,
                            'nickname': widget.nickname!,
                            'categoryTopicId': _selectedTopic!.id,
                            'difficulty': difficulty,
                          },
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('회원가입이 완료되었습니다')),
                        );
                        widget.onLogin();
                      } catch (error) {
                        if (!mounted) return;
                        final message = error is ApiError
                            ? error.message
                            : '회원가입에 실패했습니다';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSubmitting = false;
                          });
                        }
                      }
                    }
                  : null,
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

String? _mapDifficulty(String? level) {
  switch (level) {
    case '쉬움':
      return 'EASY';
    case '보통':
      return 'NORMAL';
    case '어려움':
      return 'HARD';
    default:
      return null;
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

class _SelectDropdown<T> extends StatelessWidget {
  const _SelectDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T?>? onChanged;
  // final Text test;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6EBF5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          style: const TextStyle(
            color: textDark,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: textMuted,
            size: 20,
          ),
          dropdownColor: Colors.white,
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              color: Color(0xFFB7C0D9),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    style: const TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? primaryBlue : const Color(0xFFE6EBF5);
    final backgroundColor = isSelected ? const Color(0xFFEFF2FF) : Colors.white;
    final titleColor = isSelected ? primaryBlue : textDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: titleColor,
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
      ),
    );
  }
}

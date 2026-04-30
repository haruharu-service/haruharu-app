import 'package:flutter/material.dart';

import '../requests/home_requests.dart';

class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key, required this.dailyProblemId});

  final int dailyProblemId;

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  final TextEditingController _answerController = TextEditingController();
  late Future<DailyProblemDetailResponse> _detailFuture;
  DailyProblemDetailResponse? _detail;
  bool _isSubmitting = false;
  String? _submitError;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<DailyProblemDetailResponse> _loadDetail() async {
    final detail = await HomeRequests.fetchProblemDetail(
      dailyProblemId: widget.dailyProblemId,
    );
    _detail = detail;
    _answerController.text = detail.userAnswer ?? '';
    return detail;
  }

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      setState(() {
        _submitError = '답변을 입력해주세요';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final submission = await HomeRequests.submitSolution(
        dailyProblemId: widget.dailyProblemId,
        userAnswer: answer,
      );
      if (!mounted) return;
      setState(() {
        _detail = (_detail ?? _fallbackDetail()).copyWithSubmission(submission);
        _isSubmitting = false;
        _hasSubmitted = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.toString();
        _isSubmitting = false;
      });
    }
  }

  DailyProblemDetailResponse _fallbackDetail() {
    return DailyProblemDetailResponse(
      id: widget.dailyProblemId,
      difficulty: '',
      categoryTopic: '',
      assignedAt: null,
      title: '',
      description: '',
      userAnswer: null,
      submittedAt: null,
      aiAnswer: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_hasSubmitted);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FD),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F9FD),
          foregroundColor: const Color(0xFF172033),
          elevation: 0,
          title: const Text(
            '오늘의 챌린지',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: FutureBuilder<DailyProblemDetailResponse>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _detail == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && _detail == null) {
              return _ChallengeError(
                message: snapshot.error.toString(),
                onRetry: () {
                  setState(() {
                    _detailFuture = _loadDetail();
                  });
                },
              );
            }

            final detail = _detail ?? snapshot.data ?? _fallbackDetail();
            final aiAnswer = detail.aiAnswer;

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProblemCard(detail: detail),
                    const SizedBox(height: 18),
                    _AnswerEditor(
                      controller: _answerController,
                      errorText: _submitError,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 58,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submitAnswer,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          _isSubmitting ? '제출 중...' : '답변 제출',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3F57FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    if (aiAnswer != null && aiAnswer.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _AiAnswerCard(aiAnswer: aiAnswer),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({required this.detail});

  final DailyProblemDetailResponse detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10121B40),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                label: detail.categoryTopic.isEmpty
                    ? 'Topic'
                    : detail.categoryTopic,
                color: const Color(0xFF3F57FF),
                backgroundColor: const Color(0xFFF1F3FF),
              ),
              const Spacer(),
              _Pill(
                label: _difficultyLabel(detail.difficulty),
                color: const Color(0xFF0F9F45),
                backgroundColor: const Color(0xFFDFFBE8),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            detail.title.isEmpty ? '오늘의 문제' : detail.title,
            style: const TextStyle(
              color: Color(0xFF11182C),
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            detail.description,
            style: const TextStyle(
              color: Color(0xFF687794),
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerEditor extends StatelessWidget {
  const _AnswerEditor({required this.controller, required this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 8,
      maxLines: 14,
      maxLength: 5000,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: '나의 답변을 작성해주세요',
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF3F57FF), width: 1.4),
        ),
      ),
      style: const TextStyle(
        color: Color(0xFF172033),
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AiAnswerCard extends StatelessWidget {
  const _AiAnswerCard({required this.aiAnswer});

  final String aiAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF11182C),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI 모범 답안',
            style: TextStyle(
              color: Color(0xFF9DB1FF),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            aiAnswer,
            style: const TextStyle(
              color: Color(0xFFE7E9FF),
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeError extends StatelessWidget {
  const _ChallengeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFE35B5B),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF687794),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 불러오기')),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _difficultyLabel(String difficulty) {
  switch (difficulty.toUpperCase()) {
    case 'EASY':
      return '쉬움';
    case 'MEDIUM':
      return '보통';
    case 'HARD':
      return '어려움';
    default:
      return difficulty.isEmpty ? '난이도' : difficulty;
  }
}

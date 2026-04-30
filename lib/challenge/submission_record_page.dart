import 'package:flutter/material.dart';

import '../requests/home_requests.dart';

class SubmissionRecordPage extends StatefulWidget {
  const SubmissionRecordPage({super.key, required this.dailyProblemId});

  final int dailyProblemId;

  @override
  State<SubmissionRecordPage> createState() => _SubmissionRecordPageState();
}

class _SubmissionRecordPageState extends State<SubmissionRecordPage> {
  late Future<DailyProblemDetailResponse> _detailFuture;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<DailyProblemDetailResponse> _loadDetail() {
    return HomeRequests.fetchProblemDetail(
      dailyProblemId: widget.dailyProblemId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: SafeArea(
        child: FutureBuilder<DailyProblemDetailResponse>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _RecordError(
                message: snapshot.error.toString(),
                onRetry: () {
                  setState(() {
                    _detailFuture = _loadDetail();
                  });
                },
              );
            }

            final detail = snapshot.data;
            if (detail == null) {
              return const _RecordError(message: '제출 기록을 찾을 수 없습니다.');
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left_rounded, size: 34),
                      color: const Color(0xFF8FA0B8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _formatDate(detail.assignedAt),
                    style: const TextStyle(
                      color: Color(0xFF95A1B5),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 44),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _RecordPill(
                        label: detail.categoryTopic,
                        color: const Color(0xFF3F57FF),
                        backgroundColor: const Color(0xFFF1F3FF),
                      ),
                      _RecordPill(
                        label: _difficultyLabel(detail.difficulty),
                        color: const Color(0xFF687794),
                        backgroundColor: const Color(0xFFF0F3F8),
                      ),
                      const _RecordPill(
                        label: '✓ 제출 완료',
                        color: Color(0xFF0F9F45),
                        backgroundColor: Color(0xFFE8FFF0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFF5D74FF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          detail.title,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  _ProblemDescriptionCard(description: detail.description),
                  const SizedBox(height: 28),
                  _SubmissionCard(
                    detail: detail,
                    selectedTab: _selectedTab,
                    onTabChanged: (index) {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 60,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C86FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '대시보드로 돌아가기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProblemDescriptionCard extends StatelessWidget {
  const _ProblemDescriptionCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F121B40),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: Text(
              '• 문제 설명',
              style: TextStyle(
                color: Color(0xFF5D62FF),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8ECF5)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              description,
              style: const TextStyle(
                color: Color(0xFF42516A),
                fontSize: 19,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.detail,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final DailyProblemDetailResponse detail;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final submittedAt = detail.submittedAt;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10121B40),
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '제출한 답변',
                    style: TextStyle(
                      color: Color(0xFF11182C),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFFC4CDDA),
                  size: 26,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Text(
              detail.userAnswer?.isNotEmpty == true
                  ? detail.userAnswer!
                  : '제출한 답변이 없습니다.',
              style: const TextStyle(
                color: Color(0xFF42516A),
                fontSize: 17,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (submittedAt != null) ...[
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(
                '제출 시간: ${_formatDateTime(submittedAt)}',
                style: const TextStyle(
                  color: Color(0xFFC4CDDA),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 26),
          const Divider(height: 1, color: Color(0xFFE8ECF5)),
          Row(
            children: [
              _TabButton(
                title: 'AI 모범 답안',
                selected: selectedTab == 0,
                onTap: () => onTabChanged(0),
              ),
              _TabButton(
                title: 'AI 피드백',
                selected: selectedTab == 1,
                onTap: () => onTabChanged(1),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFE8ECF5)),
          Padding(
            padding: const EdgeInsets.all(26),
            child: selectedTab == 0
                ? _AiAnswerPanel(aiAnswer: detail.aiAnswer)
                : const _FeedbackPlaceholder(),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFF5D62FF) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF5D62FF)
                  : const Color(0xFF42516A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AiAnswerPanel extends StatelessWidget {
  const _AiAnswerPanel({required this.aiAnswer});

  final String? aiAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF171D34),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF303675),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFDDE4FF),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 멘토의 조언',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '문제 풀이에 도움이 되는 피드백입니다',
                      style: TextStyle(
                        color: Color(0xFF9AA4C4),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0x334A5578)),
          const SizedBox(height: 24),
          Text(
            aiAnswer?.isNotEmpty == true ? aiAnswer! : 'AI 모범 답안이 아직 없습니다.',
            style: const TextStyle(
              color: Color(0xFFE6E9F4),
              fontSize: 17,
              height: 1.65,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackPlaceholder extends StatelessWidget {
  const _FeedbackPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'AI 피드백은 제출 ID가 응답에 포함되면 연결할 수 있습니다.',
        style: TextStyle(
          color: Color(0xFF687794),
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecordPill extends StatelessWidget {
  const _RecordPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.isEmpty ? '-' : label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RecordError extends StatelessWidget {
  const _RecordError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF687794),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('다시 불러오기')),
            ],
          ],
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
      return difficulty.isEmpty ? '-' : difficulty;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final ampm = local.hour < 12 ? '오전' : '오후';
  return '$year.$month.$day. $ampm $hour:$minute';
}

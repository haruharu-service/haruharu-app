import 'package:flutter/material.dart';

import '../api/token_storage.dart';
import '../requests/home_requests.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key, required this.profile});

  final MemberProfileResponse profile;

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  late Future<_MonthRecordData> _monthFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = widget.profile.createdAt ?? now;
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    if (_selectedDate.isBefore(_dateOnly(start))) {
      _selectedDate = _dateOnly(start);
      _visibleMonth = DateTime(start.year, start.month);
    }
    _monthFuture = _loadMonth();
  }

  Future<_MonthRecordData> _loadMonth() async {
    final days = _daysInMonth(_visibleMonth);
    final startDate = _dateOnly(widget.profile.createdAt ?? _visibleMonth);
    final today = _dateOnly(DateTime.now());
    final loginDates = await TokenStorage.instance.getLoginDates();
    final futures = <Future<List<DailyProblemPreviewResponse>>>[];
    final queryDates = <DateTime>[];

    for (var day = 1; day <= days; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      if (date.isBefore(startDate) || date.isAfter(today)) continue;
      queryDates.add(date);
      futures.add(HomeRequests.fetchDailyProblemsByDate(date: date));
    }

    final results = await Future.wait(futures);
    final problemsByDate = <String, List<DailyProblemPreviewResponse>>{};
    for (var i = 0; i < queryDates.length; i++) {
      problemsByDate[_formatDate(queryDates[i])] = results[i];
    }

    return _MonthRecordData(
      loginDates: loginDates.toSet(),
      problemsByDate: problemsByDate,
    );
  }

  void _moveMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final start = widget.profile.createdAt;
    if (start != null && next.isBefore(DateTime(start.year, start.month))) {
      return;
    }
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;

    setState(() {
      _visibleMonth = next;
      _selectedDate = DateTime(next.year, next.month, 1);
      _monthFuture = _loadMonth();
    });
  }

  void _selectDate(DateTime date) {
    final start = _dateOnly(widget.profile.createdAt ?? date);
    final today = _dateOnly(DateTime.now());
    if (date.isBefore(start) || date.isAfter(today)) return;
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _showProblemDetail(int problemId) async {
    final detail = await HomeRequests.fetchProblemDetail(
      dailyProblemId: problemId,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => _ProblemDetailSheet(detail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MonthRecordData>(
      future: _monthFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _MonthRecordData.empty();
        final selectedKey = _formatDate(_selectedDate);
        final selectedProblems = data.problemsByDate[selectedKey] ?? const [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '나의 기록',
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '날짜를 선택하여 문제와 답변을 확인하세요.',
              style: TextStyle(
                color: Color(0xFF687794),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            _CalendarCard(
              visibleMonth: _visibleMonth,
              selectedDate: _selectedDate,
              joinedAt: widget.profile.createdAt,
              data: data,
              isLoading: isLoading,
              onPrevious: () => _moveMonth(-1),
              onNext: () => _moveMonth(1),
              onSelectDate: _selectDate,
            ),
            const SizedBox(height: 28),
            _SelectedDateProblems(
              date: _selectedDate,
              problems: selectedProblems,
              onTapProblem: _showProblemDetail,
            ),
          ],
        );
      },
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.visibleMonth,
    required this.selectedDate,
    required this.joinedAt,
    required this.data,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectDate,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime? joinedAt;
  final _MonthRecordData data;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final cells = _calendarCells(visibleMonth);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10121B40),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded, size: 32),
                color: const Color(0xFF6D7A90),
              ),
              Expanded(
                child: Text(
                  '${visibleMonth.year}년 ${visibleMonth.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF11182C),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded, size: 32),
                color: const Color(0xFFB7C0CF),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: const ['일', '월', '화', '수', '목', '금', '토']
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF92A0B6),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 72),
              child: CircularProgressIndicator(),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.86,
              ),
              itemCount: cells.length,
              itemBuilder: (context, index) {
                final date = cells[index];
                if (date == null) return const SizedBox.shrink();
                final key = _formatDate(date);
                final problems = data.problemsByDate[key] ?? const [];
                final joinedDate = joinedAt == null
                    ? null
                    : _dateOnly(joinedAt!);
                if (joinedDate != null && date.isBefore(joinedDate)) {
                  return const SizedBox.shrink();
                }
                final disabled = date.isAfter(_dateOnly(DateTime.now()));
                return _CalendarDay(
                  date: date,
                  isSelected: _isSameDate(date, selectedDate),
                  isDisabled: disabled,
                  didLogin: data.loginDates.contains(key),
                  hasProblem: problems.isNotEmpty,
                  solvedCount: problems
                      .where((problem) => problem.isSolved)
                      .length,
                  onTap: () => onSelectDate(date),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.isSelected,
    required this.isDisabled,
    required this.didLogin,
    required this.hasProblem,
    required this.solvedCount,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isDisabled;
  final bool didLogin;
  final bool hasProblem;
  final int solvedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isDisabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4B63FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x334B63FF),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isDisabled
                    ? const Color(0xFFC8D1DE)
                    : const Color(0xFF2E3A50),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TinyDot(active: didLogin, color: const Color(0xFF7C8DFF)),
                const SizedBox(width: 4),
                _TinyDot(
                  active: hasProblem,
                  color: solvedCount > 0
                      ? const Color(0xFF21BD63)
                      : const Color(0xFFFFB84D),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyDot extends StatelessWidget {
  const _TinyDot({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: active ? color : const Color(0xFFE1E6EF),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SelectedDateProblems extends StatelessWidget {
  const _SelectedDateProblems({
    required this.date,
    required this.problems,
    required this.onTapProblem,
  });

  final DateTime date;
  final List<DailyProblemPreviewResponse> problems;
  final ValueChanged<int> onTapProblem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_formatDate(date)} 문제',
          style: const TextStyle(
            color: Color(0xFF11182C),
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        if (problems.isEmpty)
          const Text(
            '이 날짜에는 기록된 문제가 없습니다.',
            style: TextStyle(
              color: Color(0xFF8B97AD),
              fontWeight: FontWeight.w700,
            ),
          )
        else
          ...problems.map(
            (problem) => _ProblemRecordTile(
              problem: problem,
              onTap: () => onTapProblem(problem.id),
            ),
          ),
      ],
    );
  }
}

class _ProblemRecordTile extends StatelessWidget {
  const _ProblemRecordTile({required this.problem, required this.onTap});

  final DailyProblemPreviewResponse problem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: const Color(0x14121B40),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RecordPill(
                            label: problem.categoryTopic,
                            color: const Color(0xFF3F57FF),
                            backgroundColor: const Color(0xFFF1F3FF),
                          ),
                          _RecordPill(
                            label: _difficultyLabel(problem.difficulty),
                            color: const Color(0xFF687794),
                            backgroundColor: const Color(0xFFF0F3F8),
                          ),
                          if (problem.isSolved)
                            const _RecordPill(
                              label: '완료',
                              color: Color(0xFF0F9F45),
                              backgroundColor: Color(0xFFDFFBE8),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        problem.title,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC4CDDA),
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProblemDetailSheet extends StatelessWidget {
  const _ProblemDetailSheet({required this.detail});

  final DailyProblemDetailResponse detail;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E0EA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
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
              ],
            ),
            const SizedBox(height: 18),
            Text(
              detail.title,
              style: const TextStyle(
                color: Color(0xFF11182C),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              detail.description,
              style: const TextStyle(
                color: Color(0xFF687794),
                fontSize: 16,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _DetailBlock(
              title: '내 답변',
              body: detail.userAnswer?.isNotEmpty == true
                  ? detail.userAnswer!
                  : '아직 제출한 답변이 없습니다.',
            ),
            const SizedBox(height: 16),
            _DetailBlock(
              title: 'AI 모범 답안',
              body: detail.aiAnswer?.isNotEmpty == true
                  ? detail.aiAnswer!
                  : '아직 AI 답안이 없습니다.',
              dark: true,
            ),
          ],
        );
      },
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.body,
    this.dark = false,
  });

  final String title;
  final String body;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF11182C) : const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: dark ? const Color(0xFF9DB1FF) : const Color(0xFF3F57FF),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              color: dark ? const Color(0xFFE7E9FF) : const Color(0xFF172033),
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label.isEmpty ? '-' : label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MonthRecordData {
  const _MonthRecordData({
    required this.loginDates,
    required this.problemsByDate,
  });

  const _MonthRecordData.empty()
    : loginDates = const {},
      problemsByDate = const {};

  final Set<String> loginDates;
  final Map<String, List<DailyProblemPreviewResponse>> problemsByDate;
}

List<DateTime?> _calendarCells(DateTime month) {
  final firstDay = DateTime(month.year, month.month);
  final days = _daysInMonth(month);
  final leadingEmptyCount = firstDay.weekday % 7;
  return [
    ...List<DateTime?>.filled(leadingEmptyCount, null),
    ...List.generate(
      days,
      (index) => DateTime(month.year, month.month, index + 1),
    ),
  ];
}

int _daysInMonth(DateTime month) {
  return DateTime(month.year, month.month + 1, 0).day;
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
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

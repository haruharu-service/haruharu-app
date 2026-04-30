import 'package:flutter/material.dart';

import 'account/account_state.dart';
import 'api/token_storage.dart';
import 'challenge/challenge_page.dart';
import 'challenge/submission_record_page.dart';
import 'login_root.dart';
import 'record/record_page.dart';
import 'requests/auth_requests.dart';
import 'requests/home_requests.dart';
import 'settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _fallbackAttendanceDays = [
    _AttendanceDay(label: '금', isChecked: true),
    _AttendanceDay(label: '토', isChecked: true),
    _AttendanceDay(label: '일', isChecked: false),
    _AttendanceDay(label: '월', isChecked: true),
    _AttendanceDay(label: '화', isChecked: false),
    _AttendanceDay(label: '수', isChecked: false),
    _AttendanceDay(label: '목', isChecked: false),
  ];

  late Future<_HomeData> _homeFuture;
  bool _hasShownTodayProblemModal = false;
  bool _isLoggingOut = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();
  }

  Future<_HomeData> _loadHomeData() async {
    final results = await Future.wait<Object>([
      HomeRequests.fetchProfile(),
      HomeRequests.fetchStreak(),
      HomeRequests.fetchTodayProblems(),
    ]);

    final profile = results[0] as MemberProfileResponse;
    final streak = results[1] as StreakResponse;
    final todayProblems = results[2] as List<TodayProblemResponse>;

    AccountState.instance.setLoggedInUser(
      loginId: profile.loginId,
      nickname: profile.nickname,
      createdAt: profile.createdAt,
      profileImageUrl: profile.profileImageUrl,
      preferences: profile.preferences,
    );

    final data = _HomeData(
      profile: profile,
      streak: streak,
      todayProblems: todayProblems,
    );
    _showTodayProblemModalIfNeeded(data);
    return data;
  }

  Future<void> _reloadHomeData() async {
    final nextFuture = _loadHomeData();
    setState(() {
      _homeFuture = nextFuture;
    });
    try {
      await nextFuture;
    } catch (_) {
      // FutureBuilder displays the error state.
    }
  }

  void _showTodayProblemModalIfNeeded(_HomeData data) {
    if (_hasShownTodayProblemModal || !mounted) return;

    final unsolvedProblems = data.todayProblems.where(
      (problem) => !problem.isSolved,
    );
    if (unsolvedProblems.isEmpty) return;

    _hasShownTodayProblemModal = true;
    final problem = unsolvedProblems.first;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final shouldStart = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => _TodayProblemDialog(problem: problem),
      );

      if (!mounted || shouldStart != true) return;
      final shouldRefresh = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => ChallengePage(dailyProblemId: problem.id),
        ),
      );
      if (shouldRefresh == true) {
        await _reloadHomeData();
      }
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    final accessToken = await TokenStorage.instance.getAccessToken();
    try {
      await AuthRequests.logoutRequest(accessToken: accessToken);
    } catch (_) {
      // Even if the server logout fails, remove local credentials.
    }

    await TokenStorage.instance.clearTokens();
    AccountState.instance.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginRootPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<AccountUser?>(
          valueListenable: AccountState.instance,
          builder: (context, user, _) {
            return FutureBuilder<_HomeData>(
              future: _homeFuture,
              builder: (context, snapshot) {
                final data = snapshot.data ?? _HomeData.fallback(user);
                final firstProblem = data.todayProblems.isEmpty
                    ? null
                    : data.todayProblems.first;
                final completedCount = data.todayProblems
                    .where((problem) => problem.isSolved)
                    .length;
                final totalCount = data.todayProblems.isEmpty
                    ? 1
                    : data.todayProblems.length;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;
                final error = snapshot.hasError
                    ? snapshot.error.toString()
                    : null;

                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _reloadHomeData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HomeHeader(
                                user: user,
                                isLoggingOut: _isLoggingOut,
                                onLogout: _logout,
                              ),
                              if (isLoading || error != null) ...[
                                const SizedBox(height: 18),
                                _HomeStatusBanner(
                                  isLoading: isLoading,
                                  message: error,
                                  onRetry: () {
                                    _reloadHomeData();
                                  },
                                ),
                              ],
                              const SizedBox(height: 28),
                              if (_selectedTabIndex == 0) ...[
                                _StreakCard(
                                  currentStreak: data.streak.currentStreak,
                                  maxStreak: data.streak.maxStreak,
                                  attendanceDays: data.attendanceDays,
                                ),
                                const SizedBox(height: 22),
                                _LearningSummary(
                                  problem: firstProblem,
                                  user: user,
                                ),
                                const SizedBox(height: 36),
                                _ChallengeHeader(
                                  completedCount: completedCount,
                                  totalCount: totalCount,
                                ),
                                const SizedBox(height: 18),
                                _ChallengeCard(
                                  problem: firstProblem,
                                  onFinished: _reloadHomeData,
                                ),
                              ] else if (_selectedTabIndex == 1) ...[
                                RecordPage(profile: data.profile),
                              ] else ...[
                                SettingsPage(
                                  profile: data.profile,
                                  onProfileChanged: _reloadHomeData,
                                  onLogout: _logout,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    _HomeBottomNavigation(
                      selectedIndex: _selectedTabIndex,
                      onSelected: (index) {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.user,
    required this.isLoggingOut,
    required this.onLogout,
  });

  final AccountUser? user;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.nickname?.isNotEmpty == true
        ? user!.nickname!
        : user?.loginId ?? '알 수 없음';

    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6172FF), Color(0xFF3152FF)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334B63FF),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'H',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'haru:',
                style: TextStyle(
                  color: Color(0xFF11182C),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$displayName님, 오늘도 가볍게 시작해요',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8B97AD),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _IconSurfaceButton(
          icon: Icons.logout_rounded,
          isLoading: isLoggingOut,
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _HomeStatusBanner extends StatelessWidget {
  const _HomeStatusBanner({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isLoading ? const Color(0xFFEFF3FF) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          else
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFE35B5B),
              size: 20,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoading ? '오늘의 학습 정보를 불러오는 중입니다' : message ?? '정보를 불러오지 못했습니다',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLoading
                    ? const Color(0xFF4B63FF)
                    : const Color(0xFFE35B5B),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!isLoading)
            TextButton(onPressed: onRetry, child: const Text('재시도')),
        ],
      ),
    );
  }
}

class _TodayProblemDialog extends StatelessWidget {
  const _TodayProblemDialog({required this.problem});

  final TodayProblemResponse problem;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3FF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Color(0xFF3F57FF),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '오늘의 문제가 기다리고 있어요',
                    style: TextStyle(
                      color: Color(0xFF11182C),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _TopicPill(label: problem.categoryTopicName),
            const SizedBox(height: 14),
            Text(
              problem.title,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              problem.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF687794),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      '나중에',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3F57FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '바로 풀기',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.currentStreak,
    required this.maxStreak,
    required this.attendanceDays,
  });

  final int currentStreak;
  final int maxStreak;
  final List<_AttendanceDay> attendanceDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF121631), Color(0xFF202161), Color(0xFF14184A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30131A4E),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _StreakBadge(),
                        const SizedBox(height: 14),
                        const Text(
                          '연속 학습 리듬',
                          style: TextStyle(
                            color: Color(0xFFB6BED9),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$currentStreak',
                              style: const TextStyle(
                                color: Color(0xFFE7E9FF),
                                fontSize: 58,
                                height: 0.95,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                '일째',
                                style: TextStyle(
                                  color: Color(0xFFE7E9FF),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const _FlameMark(),
                ],
              ),
              const SizedBox(height: 26),
              Container(height: 1, color: const Color(0x14FFFFFF)),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;
                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AttendanceStrip(days: attendanceDays),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _LiveStatus(bestCount: maxStreak),
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _AttendanceStrip(days: attendanceDays)),
                      const SizedBox(width: 18),
                      _LiveStatus(bestCount: maxStreak),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x20FFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '입문자',
        style: TextStyle(
          color: Color(0xFF9DB1FF),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FlameMark extends StatelessWidget {
  const _FlameMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x33FFDF5D), Color(0x00FFDF5D)],
        ),
      ),
      child: const Icon(
        Icons.local_fire_department_rounded,
        color: Color(0xFFFFA63D),
        size: 48,
      ),
    );
  }
}

class _AttendanceStrip extends StatelessWidget {
  const _AttendanceStrip({required this.days});

  final List<_AttendanceDay> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) => _AttendanceDot(day: day)).toList(),
    );
  }
}

class _AttendanceDot extends StatelessWidget {
  const _AttendanceDot({required this.day});

  final _AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final checked = day.isChecked;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: checked ? const Color(0xFF5D74FF) : const Color(0x10FFFFFF),
            border: Border.all(
              color: checked
                  ? const Color(0xFF8FA0FF)
                  : const Color(0x14FFFFFF),
            ),
            boxShadow: checked
                ? const [
                    BoxShadow(
                      color: Color(0x665D74FF),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: checked
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
        const SizedBox(height: 9),
        Text(
          day.label,
          style: TextStyle(
            color: checked ? const Color(0xFFDBE1FF) : const Color(0xFF8B91B5),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LiveStatus extends StatelessWidget {
  const _LiveStatus({required this.bestCount});

  final int bestCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '최고 $bestCount일 기록 중',
          style: const TextStyle(
            color: Color(0xFFADB5D6),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x12FFFFFF)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulseDot(),
              SizedBox(width: 8),
              Text(
                'LIVE STATUS',
                style: TextStyle(
                  color: Color(0xFF85A1FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF5D74FF),
      ),
    );
  }
}

class _LearningSummary extends StatelessWidget {
  const _LearningSummary({required this.problem, required this.user});

  final TodayProblemResponse? problem;
  final AccountUser? user;

  @override
  Widget build(BuildContext context) {
    final preference = user?.preferences.isEmpty == false
        ? user!.preferences.first
        : null;
    final topic =
        problem?.categoryTopicName ?? preference?.categoryTopicName ?? '학습 주제';
    final difficulty = _difficultyLabel(
      problem?.difficulty ?? preference?.difficulty ?? '',
    );

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'TOPIC',
            title: topic,
            icon: Icons.circle,
            iconSize: 12,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryTile(label: 'LEVEL', title: difficulty, badge: 'LV'),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.title,
    this.icon,
    this.iconSize = 18,
    this.badge,
  });

  final String label;
  final String title;
  final IconData? icon;
  final double iconSize;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12121B40),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryIcon(icon: icon, iconSize: iconSize, badge: badge),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF93A0B6),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryIcon extends StatelessWidget {
  const _SummaryIcon({
    required this.icon,
    required this.iconSize,
    required this.badge,
  });

  final IconData? icon;
  final double iconSize;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A4B63FF),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: badge == null
            ? Icon(icon, color: const Color(0xFF4B63FF), size: iconSize)
            : Text(
                badge!,
                style: const TextStyle(
                  color: Color(0xFF4B63FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _ChallengeHeader extends StatelessWidget {
  const _ChallengeHeader({
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '오늘의 챌린지',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '$completedCount/$totalCount 완료',
          style: const TextStyle(
            color: Color(0xFF95A1B5),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.problem, required this.onFinished});

  final TodayProblemResponse? problem;
  final Future<void> Function() onFinished;

  @override
  Widget build(BuildContext context) {
    final hasProblem = problem != null;
    final topic = problem?.categoryTopicName ?? 'Spring';
    final difficulty = _difficultyLabel(problem?.difficulty ?? 'EASY');
    final title = hasProblem ? problem!.title : '오늘의 문제가 아직 없습니다';
    final description = hasProblem
        ? problem!.description
        : '백엔드에서 오늘의 문제가 내려오면 이 영역에 자동으로 표시됩니다.';
    final isSolved = problem?.isSolved == true;

    return Container(
      padding: const EdgeInsets.all(28),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TopicPill(label: topic),
              const Spacer(),
              _LevelPill(label: difficulty),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF11182C),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF687794),
              fontSize: 17,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: hasProblem
                  ? () async {
                      if (isSolved) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SubmissionRecordPage(
                              dailyProblemId: problem!.id,
                            ),
                          ),
                        );
                        return;
                      }

                      final shouldRefresh = await Navigator.of(context)
                          .push<bool>(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChallengePage(dailyProblemId: problem!.id),
                            ),
                          );
                      if (shouldRefresh == true) {
                        await onFinished();
                      }
                    }
                  : null,
              icon: Icon(
                isSolved
                    ? Icons.fact_check_rounded
                    : Icons.arrow_forward_rounded,
                size: 22,
              ),
              label: Text(
                isSolved ? '제출 기록 확인' : '챌린지 시작',
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
        ],
      ),
    );
  }
}

class _TopicPill extends StatelessWidget {
  const _TopicPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF3F57FF),
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDFFBE8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0F9F45),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HomeBottomNavigation extends StatelessWidget {
  const _HomeBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D121B40),
            blurRadius: 20,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _NavigationItem(
                icon: Icons.home_rounded,
                label: '챌린지',
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                icon: Icons.bar_chart_rounded,
                label: '성장 기록',
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                icon: Icons.tune_rounded,
                label: '설정',
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F1FF) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: selected ? const Color(0xFF3F57FF) : const Color(0xFF9BA8BC),
            size: 30,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF3F57FF) : const Color(0xFF9BA8BC),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );

    final wrapped = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );

    if (!selected) return wrapped;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F3FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: wrapped,
    );
  }
}

class _IconSurfaceButton extends StatelessWidget {
  const _IconSurfaceButton({
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      shadowColor: const Color(0x22121B40),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.3),
              )
            : Icon(icon, color: const Color(0xFF637087)),
        tooltip: '로그아웃',
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x12FFFFFF);
    const step = 30.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AttendanceDay {
  const _AttendanceDay({required this.label, required this.isChecked});

  final String label;
  final bool isChecked;
}

class _HomeData {
  const _HomeData({
    required this.profile,
    required this.streak,
    required this.todayProblems,
  });

  factory _HomeData.fallback(AccountUser? user) {
    final preferences = user?.preferences ?? const <AccountPreference>[];
    return _HomeData(
      profile: MemberProfileResponse(
        loginId: user?.loginId ?? '',
        nickname: user?.nickname ?? '',
        createdAt: user?.createdAt,
        profileImageUrl: user?.profileImageUrl,
        preferences: preferences,
      ),
      streak: const StreakResponse(
        currentStreak: 0,
        maxStreak: 0,
        weeklySolvedStatus: [],
      ),
      todayProblems: const [],
    );
  }

  final MemberProfileResponse profile;
  final StreakResponse streak;
  final List<TodayProblemResponse> todayProblems;

  List<_AttendanceDay> get attendanceDays {
    if (streak.weeklySolvedStatus.isEmpty) {
      return _HomePageState._fallbackAttendanceDays;
    }

    return streak.weeklySolvedStatus.map((status) {
      return _AttendanceDay(
        label: _weekdayLabel(status.date),
        isChecked: status.isSolved,
      );
    }).toList();
  }
}

String _weekdayLabel(DateTime? date) {
  if (date == null) return '';
  const labels = ['월', '화', '수', '목', '금', '토', '일'];
  return labels[date.weekday - 1];
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
      return difficulty.isEmpty ? '쉬움' : difficulty;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'requests/auth_requests.dart';
import 'api/api_client.dart';
import 'api/token_storage.dart';
import 'signup/signup_flow.dart';
import 'requests/quote_requests.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _fallbackQuotes = [
    '나랑 같이 챌린지 안할래??',
    '오늘도 한 걸음, 같이 가요',
    '작은 습관이 큰 변화를 만들어요',
    '지금 시작하면 내일이 달라져요',
    '하루 1%의 변화, 함께 해요',
    '오늘의 나를 조금만 더 돌봐요',
    '5분만 투자해볼래요?',
    '지금이 가장 빠른 시작이에요',
    '혼자보다 같이면 더 쉬워요',
    '작게 시작하고 크게 자라요',
    '꾸준함은 언제나 이겨요',
    '오늘 시작하면 내일이 가벼워요',
    '내일의 나에게 선물하기',
    '지금 한 번, 충분해요',
    '나를 위한 작은 약속',
    '다음 버전의 나를 만나봐요',
    '오늘도 잘하고 있어요',
    '천천히 가도 괜찮아요',
    '포기하지 않으면 실패가 아니에요',
    '매일 조금씩, 분명히 달라져요',
    '오늘의 노력이 내일의 나를 만들어요',
    '완벽하지 않아도 시작할 수 있어요',
    '작은 성공이 쌓여 큰 변화가 돼요',
    '쉬어가도 괜찮아요, 포기만 하지 마요',
  ];

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  Timer? _quoteTimer;
  List<String> _quotes = List.of(_fallbackQuotes);
  int _quoteIndex = 0;
  bool _isSubmitting = false;
  String? _apiError;
  bool _showConnectionModal = true;
  _ServerConnectionState _connectionState = _ServerConnectionState.checking;
  bool _fadeOutConnectionModal = false;
  late final AnimationController _glassController;

  bool get _showPassword => _idController.text.trim().isNotEmpty;
  String get _currentQuote {
    if (_quotes.isEmpty) {
      return _fallbackQuotes.first;
    }
    return _quotes[_quoteIndex % _quotes.length];
  }

  @override
  void initState() {
    super.initState();
    _glassController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _idController.addListener(() {
      setState(() {});
    });
    _checkServerConnection();
    _loadQuotes();
  }

  @override
  void dispose() {
    _glassController.dispose();
    _quoteTimer?.cancel();
    _idController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _checkServerConnection() async {
    setState(() {
      _showConnectionModal = true;
      _connectionState = _ServerConnectionState.checking;
    });

    try {
      final client = ApiClient.instance;
      await client.dio.get(
        '',
        options: Options(
          validateStatus: (_) => true,
        ),
      );
      if (!mounted) return;
      setState(() {
        _connectionState = _ServerConnectionState.success;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _fadeOutConnectionModal = true;
      });
      await Future.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      setState(() {
        _showConnectionModal = false;
        _fadeOutConnectionModal = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connectionState = _ServerConnectionState.failed;
      });
    }
  }

  Future<void> _submitLogin() async {
    final loginId = _idController.text.trim();
    final password = _passwordController.text;

    if (loginId.isEmpty || password.isEmpty) {
      setState(() {
        _apiError = '아이디와 비밀번호를 입력하세요';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _apiError = null;
    });

    try {
      final token = await AuthRequests.loginRequest(
        loginId: loginId,
        password: password,
      );
      await TokenStorage.instance.setTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );
      if (!mounted) return;
      // TODO: 로그인 성공 후 이동 처리
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _apiError = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _loadQuotes() async {
    try {
      final quotes = await QuoteRequests.fetchQuotes();
      if (!mounted) return;
      setState(() {
        _quotes = quotes;
        _quoteIndex = 0;
      });
      _startQuoteRotation();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quotes = List.of(_fallbackQuotes);
        _quoteIndex = 0;
      });
      _startQuoteRotation();
    }
  }

  void _startQuoteRotation() {
    _quoteTimer?.cancel();
    if (_quotes.isEmpty) return;
    _quoteTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _quotes.isEmpty) return;
      setState(() {
        _quoteIndex = (_quoteIndex + 1) % _quotes.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const _BackgroundGlow(),
            if (!_showConnectionModal)
              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        '나를 지키는 작은 습관',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF9DA6C8)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      _GlassText(
                        text: 'haru:',
                        animation: _glassController,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -0.5,
                                  color: const Color(0xFFB5BFE4),
                                ),
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.98, end: 1)
                                    .animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _SpeechBubble(
                            key: ValueKey(_currentQuote),
                            text: _currentQuote,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '아이디',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: const Color(0xFF9DA6C8)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _idController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          if (_showPassword) {
                            _passwordFocus.requestFocus();
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: '아이디를 입력하세요',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_apiError != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x33FF6B6B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66FF6B6B)),
                          ),
                          child: Text(
                            _apiError!,
                            style: const TextStyle(
                              color: Color(0xFFFFB3B3),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: _showPassword
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '비밀번호',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: const Color(0xFF9DA6C8)),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: '비밀번호를 입력하세요',
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _isSubmitting ? null : _submitLogin,
                              child: Text(
                                _isSubmitting ? '로그인 중...' : '챌린지 시작하기',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupFlowPage(),
                            ),
                          );
                        },
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(color: Color(0xFF8FA3FF)),
                            children: [
                              TextSpan(text: '아직 계정이 없으신가요? '),
                              TextSpan(
                                text: '회원가입',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showConnectionModal)
              _ServerConnectionModal(
                state: _connectionState,
                onRetry: _checkServerConnection,
                fadeOut: _fadeOutConnectionModal,
              ),
          ],
        ),
      ),
    );
  }
}

enum _ServerConnectionState { checking, success, failed }

class _ServerConnectionModal extends StatelessWidget {
  const _ServerConnectionModal({
    required this.state,
    required this.onRetry,
    required this.fadeOut,
  });

  final _ServerConnectionState state;
  final VoidCallback onRetry;
  final bool fadeOut;

  @override
  Widget build(BuildContext context) {
    final isChecking = state == _ServerConnectionState.checking;
    final isSuccess = state == _ServerConnectionState.success;
    final title = switch (state) {
      _ServerConnectionState.checking => '서버에 접속중입니다.',
      _ServerConnectionState.success => '접속되었습니다.',
      _ServerConnectionState.failed => '서버에 접속할 수 없습니다.',
    };
    final subtitle = switch (state) {
      _ServerConnectionState.checking => '연결 상태를 확인하고 있어요.',
      _ServerConnectionState.success => '로그인 화면을 불러오는 중이에요.',
      _ServerConnectionState.failed => '서버가 응답하지 않습니다. 잠시 후 다시 시도해 주세요.',
    };

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: fadeOut ? 0 : 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xCC0E1227),
          ),
          child: Center(
            child: AnimatedScale(
              scale: fadeOut ? 0.98 : 1,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              child: Container(
                width: 280,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2546),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B4674)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x88000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isChecking) ...[
                      const SizedBox(
                        height: 36,
                        width: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF8FA3FF),
                        ),
                      ),
                    ] else
                      Icon(
                        isSuccess
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: isSuccess
                            ? const Color(0xFF6CE6B5)
                            : const Color(0xFFFF8B8B),
                        size: 42,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE8ECFF),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFB3BBE0),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (state == _ServerConnectionState.failed) ...[
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 180, height: 180),
      child: CustomPaint(
        painter: _BubblePainter(),
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bubbleColor = const Color(0xFF4B63FF);
    final paint = Paint()..color = bubbleColor;
    final radius = 22.0;
    final tailWidth = 18.0;
    final tailHeight = 10.0;
    final tailCenterX = size.width / 2;

    final bubbleRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height - tailHeight,
    );
    final rrect = RRect.fromRectAndRadius(
      bubbleRect,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    path.moveTo(tailCenterX - tailWidth / 2, bubbleRect.bottom);
    path.lineTo(tailCenterX, bubbleRect.bottom + tailHeight);
    path.lineTo(tailCenterX + tailWidth / 2, bubbleRect.bottom);
    path.close();

    canvas.drawShadow(path, const Color(0xFF2A3470), 6, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.2, -0.6),
            radius: 1.1,
            colors: [
              Color(0xFF202A5A),
              Color(0xFF151C38),
            ],
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _GlassText extends StatelessWidget {
  const _GlassText({
    required this.text,
    required this.animation,
    this.style,
  });

  final String text;
  final Animation<double> animation;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        style ?? Theme.of(context).textTheme.headlineMedium ?? const TextStyle();

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0x66FFFFFF),
                Color(0xEEFFFFFF),
                Color(0x66FFFFFF),
              ],
              stops: const [0.2, 0.5, 0.8],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlidingGradientTransform(animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Text(
            text,
            style: resolvedStyle.copyWith(
              shadows: const [
                Shadow(
                  blurRadius: 12,
                  color: Color(0x66D6E4FF),
                  offset: Offset(0, 4),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = (bounds.width * 1.6) * (slidePercent - 0.5);
    return Matrix4.translationValues(dx, 0, 0);
  }
}

import 'package:flutter/material.dart';
import 'requests/auth_requests.dart';
import 'api/token_storage.dart';
import 'signup/signup_flow.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _isSubmitting = false;
  String? _apiError;

  bool get _showPassword => _idController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _idController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    if (_showPassword) {
      Future.microtask(() {
        if (!_passwordFocus.hasFocus) {
          _passwordFocus.requestFocus();
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const _BackgroundGlow(),
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
                    Text(
                      'haru:',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.5,
                            color: const Color(0xFFB5BFE4),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.center,
                      child: _SpeechBubble(
                        text: '나랑 같이 챌린지\n안할래??',
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
          ],
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

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

import 'package:flutter/material.dart';
import 'signup_page1.dart';
import 'signup_page2.dart';
import 'signup_page3.dart';
import 'signup_widgets.dart';

class SignupFlowPage extends StatefulWidget {
  const SignupFlowPage({super.key});

  @override
  State<SignupFlowPage> createState() => _SignupFlowPageState();
}

class _SignupFlowPageState extends State<SignupFlowPage> {
  final PageController _controller = PageController();
  int _stepIndex = 0;
  String? _loginId;
  String? _password;
  String? _nickname;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    if (index < 0 || index > 2) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _goNext() {
    if (_stepIndex >= 2) return;
    _goToStep(_stepIndex + 1);
  }

  void _goPrev() {
    if (_stepIndex <= 0) return;
    _goToStep(_stepIndex - 1);
  }

  void _goLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: _stepIndex == 0
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: _goPrev,
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ProgressBar(activeIndex: _stepIndex),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _stepIndex = index;
                  });
                },
                children: [
                  SignupPage1(
                    onNext: (loginId, password) {
                      setState(() {
                        _loginId = loginId;
                        _password = password;
                      });
                      _goNext();
                    },
                    onLogin: _goLogin,
                  ),
                  SignupPage2(
                    onNext: (nickname) {
                      setState(() {
                        _nickname = nickname;
                      });
                      _goNext();
                    },
                    onPrev: _goPrev,
                    onLogin: _goLogin,
                  ),
                  SignupPage3(
                    onPrev: _goPrev,
                    onLogin: _goLogin,
                    loginId: _loginId,
                    password: _password,
                    nickname: _nickname,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

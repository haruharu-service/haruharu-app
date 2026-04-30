import 'package:flutter/material.dart';

import 'api/token_storage.dart';
import 'home.dart';
import 'login_root.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasStoredToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AuthLoadingPage();
        }

        if (snapshot.data == true) {
          TokenStorage.instance.recordLoginToday();
          return const HomePage();
        }

        return const LoginRootPage();
      },
    );
  }

  Future<bool> _hasStoredToken() async {
    final accessToken = await TokenStorage.instance.getAccessToken();
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    return (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF151C38),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF4B63FF))),
    );
  }
}

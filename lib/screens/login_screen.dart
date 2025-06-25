import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleLogin(BuildContext context) async {
    final authService = AuthService();
    final role = await authService.signInWithGoogle();

    if (role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed or invalid email.')),
      );
    } else if (role == 'ca') {
      Navigator.pushReplacementNamed(context, '/ca_dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/recipient_dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleLogin(context),
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}

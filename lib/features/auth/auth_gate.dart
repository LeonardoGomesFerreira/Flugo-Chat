import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../chat/chat_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // idTokenChanges é mais confiável que authStateChanges
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {
        // Aguardando conexão inicial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF22C55E)),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginPage();
        return const ChatPage();
      },
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_loginError(e.code));
    }
  }

  // Cadastra e JÁ DEIXA o usuário logado — o register_page faz signOut depois
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.reload();
      // NÃO faz signOut aqui — o register_page controla isso
    } on FirebaseAuthException catch (e) {
      throw Exception(_registerError(e.code));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) => signUp(email: email, password: password, displayName: displayName);

  Future<void> signOut() async => _auth.signOut();

  String _loginError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'E-mail ou senha inválidos. Verifique seus dados.';
      case 'invalid-email':
        return 'Endereço de e-mail inválido.';
      case 'user-disabled':
        return 'Conta desativada. Entre em contato com o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro ao entrar. Tente novamente.';
    }
  }

  String _registerError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Faça login.';
      case 'invalid-email':
        return 'Endereço de e-mail inválido.';
      case 'weak-password':
        return 'Senha muito fraca. Use no mínimo 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro ao criar conta. Tente novamente.';
    }
  }
}

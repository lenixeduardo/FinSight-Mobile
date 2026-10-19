/// Contrato da autenticação local, independente da interface.
abstract class FinSightAuthService {
  Future<bool> restoreSession();
  Future<void> signUp(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> signOut();
}

class FinSightAuthFailure implements Exception {
  const FinSightAuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

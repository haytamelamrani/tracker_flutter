import 'package:firebase_auth/firebase_auth.dart';

/// Service d'authentification basé sur Firebase Auth.
///
/// Gère l'inscription, la connexion et la déconnexion par email/password.
/// Expose également un [Stream] d'état d'authentification et l'UID du
/// client actuellement connecté.
class AuthService {
  final FirebaseAuth _auth;

  /// Permet l'injection de dépendance pour les tests.
  AuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  // -------------------------------------------------------------------------
  // Getters
  // -------------------------------------------------------------------------

  /// Utilisateur Firebase actuellement connecté, ou `null`.
  User? get currentUser => _auth.currentUser;

  /// UID du client connecté.
  ///
  /// Lève une [StateError] si aucun utilisateur n'est connecté.
  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Aucun utilisateur connecté.');
    }
    return user.uid;
  }

  /// `true` si un utilisateur est connecté.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream réactif des changements d'état d'authentification.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // -------------------------------------------------------------------------
  // Inscription
  // -------------------------------------------------------------------------

  /// Crée un nouveau compte avec [email] et [password].
  ///
  /// Retourne le [UserCredential] en cas de succès.
  /// Lève une [FirebaseAuthException] en cas d'erreur.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // -------------------------------------------------------------------------
  // Connexion
  // -------------------------------------------------------------------------

  /// Connecte un utilisateur existant avec [email] et [password].
  ///
  /// Retourne le [UserCredential] en cas de succès.
  /// Lève une [FirebaseAuthException] en cas d'erreur.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // -------------------------------------------------------------------------
  // Déconnexion
  // -------------------------------------------------------------------------

  /// Déconnecte l'utilisateur courant.
  Future<void> signOut() async {
    return _auth.signOut();
  }

  // -------------------------------------------------------------------------
  // Réinitialisation du mot de passe
  // -------------------------------------------------------------------------

  /// Envoie un email de réinitialisation de mot de passe à [email].
  Future<void> resetPassword({required String email}) async {
    return _auth.sendPasswordResetEmail(email: email);
  }
}

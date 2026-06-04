import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';

// =============================================================================
// Services — Singletons injectés via Provider
// =============================================================================

/// Provider du service d'authentification.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider du service Firestore.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// =============================================================================
// Auth State
// =============================================================================

/// État d'authentification de l'utilisateur.
sealed class AuthState {
  const AuthState();
}

/// État initial : vérification en cours.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Utilisateur authentifié.
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

/// Utilisateur non authentifié.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Erreur d'authentification.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// =============================================================================
// AuthNotifier — StateNotifier pour gérer l'état auth
// =============================================================================

/// Notifier qui gère l'ensemble du cycle de vie d'authentification.
///
/// Écoute le stream [authStateChanges] de Firebase Auth pour maintenir
/// l'état synchronisé automatiquement.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthLoading()) {
    _listenAuthChanges();
  }

  /// Écoute les changements d'état Firebase Auth en temps réel.
  void _listenAuthChanges() {
    _authService.authStateChanges.listen(
      (user) {
        if (user != null) {
          state = AuthAuthenticated(user);
        } else {
          state = const AuthUnauthenticated();
        }
      },
      onError: (Object error) {
        state = AuthError(error.toString());
      },
    );
  }

  /// Inscription par email/password.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      await _authService.signUp(email: email, password: password);
      // L'état sera mis à jour automatiquement via le stream.
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Erreur lors de l\'inscription.');
    }
  }

  /// Connexion par email/password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      await _authService.signIn(email: email, password: password);
      // L'état sera mis à jour automatiquement via le stream.
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Erreur lors de la connexion.');
    }
  }

  /// Déconnexion.
  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _authService.signOut();
      // L'état sera mis à jour automatiquement via le stream.
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Erreur lors de la déconnexion.');
    }
  }

  /// Réinitialisation du mot de passe.
  Future<void> resetPassword({required String email}) async {
    try {
      await _authService.resetPassword(email: email);
    } on FirebaseAuthException catch (e) {
      state = AuthError(
        e.message ?? 'Erreur lors de la réinitialisation du mot de passe.',
      );
    }
  }
}

// =============================================================================
// Providers publics
// =============================================================================

/// Provider principal de l'état d'authentification.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Provider qui expose l'UID de l'utilisateur connecté, ou `null`.
///
/// Utilisé comme dépendance par les providers de données (véhicules,
/// maintenances, etc.) pour scoper les requêtes Firestore.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user.uid;
  }
  return null;
});

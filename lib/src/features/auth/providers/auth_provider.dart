import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/app_user.dart';
import '../services/auth_service.dart';

/// Provider for Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

/// Provider for auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Provider for current user data
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;

  return AppUser(
    id: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );
});

/// Auth notifier state
class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

/// Auth state notifier for managing auth operations
class AuthNotifier extends Notifier<AuthState> {
  late AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);

    // Listen to auth state changes
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          state = state.copyWith(user: user, isLoading: false, error: null);
        },
        loading: () {
          state = state.copyWith(isLoading: true);
        },
        error: (e, _) {
          state = state.copyWith(error: e.toString(), isLoading: false);
        },
      );
    });

    return AuthState();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword(
      String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.createUserWithEmailAndPassword(email, password);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithApple();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }
}

/// Provider for AuthNotifier
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

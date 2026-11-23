// AuthCubit = who is signed in. There is ONE for the whole app
// (created in injection.dart, provided in app.dart).
//
// It listens to the repository, so it always knows the real session:
//   - signed in  -> Authenticated(profile)
//   - signed out -> Unauthenticated
//
// Actions (each one shows AuthLoading while it runs):
//   context.read<AuthCubit>().signIn(email: e, password: p);
//   context.read<AuthCubit>().register(displayName: n, email: e, password: p);
//   context.read<AuthCubit>().signInWithGoogle();
//   context.read<AuthCubit>().sendPasswordReset(email: e);
//   context.read<AuthCubit>().signOut();
//
// When an action fails the state becomes AuthError(failure). Listen to it
// with a BlocListener and show failure.userMessage.
//
// Rules:
//   - A second action is ignored while one is running (no double submit).
//   - This Cubit does not navigate. The router redirects by itself
//     (see app.dart and auth_status_mapper.dart).
//   - Field validation (email format, password length) is done by the
//     screen before it calls these methods.

import 'dart:async';

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(AuthRepository repository)
      : _repository = repository,
        super(const AuthInitial()) {
    _subscription = _repository.authStateChanges().listen(_onSessionChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<Result<UserProfile?>> _subscription;

  /// The last known session (signed in or signed out).
  AuthState _session = const AuthInitial();

  void _onSessionChanged(Result<UserProfile?> result) {
    result.fold(
      onSuccess: (profile) => _setSession(
        profile == null ? const Unauthenticated() : Authenticated(profile),
      ),
      onFailure: (failure) => emit(AuthError(failure)),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());

    final result = await _repository.signInWithEmail(
      email: email,
      password: password,
    );
    if (isClosed) return;

    result.fold(
      onSuccess: (profile) => _setSession(Authenticated(profile)),
      onFailure: (failure) => emit(AuthError(failure)),
    );
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());

    final result = await _repository.registerWithEmail(
      displayName: displayName,
      email: email,
      password: password,
    );
    if (isClosed) return;

    result.fold(
      onSuccess: (profile) => _setSession(Authenticated(profile)),
      onFailure: (failure) => emit(AuthError(failure)),
    );
  }

  /// "Continue with Google". If the user closes the Google picker, the
  /// state goes back to what it was (no error is shown).
  Future<void> signInWithGoogle() async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());

    final result = await _repository.signInWithGoogle();
    if (isClosed) return;

    result.fold(
      onSuccess: (profile) => _setSession(
        profile != null
            ? Authenticated(profile)
            : (_session is Authenticated ? _session : const Unauthenticated()),
      ),
      onFailure: (failure) => emit(AuthError(failure)),
    );
  }

  Future<void> sendPasswordReset({required String email}) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());

    final result = await _repository.sendPasswordReset(email: email);
    if (isClosed) return;

    result.fold(
      onSuccess: (_) => emit(const AuthPasswordResetSent()),
      onFailure: (failure) => emit(AuthError(failure)),
    );
  }

  Future<void> signOut() async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());

    final result = await _repository.signOut();
    if (isClosed) return;

    result.fold(
      onSuccess: (_) => _setSession(const Unauthenticated()),
      onFailure: (failure) {
        emit(AuthError(failure));
        // Signing out failed, so the user is still signed in.
        if (_session is Authenticated) emit(_session);
      },
    );
  }

  void _setSession(AuthState session) {
    _session = session;
    emit(session);
  }

    @override
  Future<void> close() {
    // The cancel is started now but not awaited on purpose: waiting for it
    // can hang in widget tests (fake time). The stream stops right away.
    unawaited(_subscription.cancel());
    return super.close();
  }
}
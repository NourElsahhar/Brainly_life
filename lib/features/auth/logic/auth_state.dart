// AuthState = the "session" of the app: who is signed in right now.
//
// States:
//   AuthInitial            -> we are still checking (the splash screen is shown)
//   AuthLoading            -> an action is running (sign in, register, sign out...)
//   Authenticated(user)    -> signed in, `user` is the profile
//   Unauthenticated        -> signed out
//   AuthError(failure)     -> an action failed, show failure.userMessage
//   AuthPasswordResetSent  -> the password reset email was sent
//
// Usage:
//   final state = context.watch<AuthCubit>().state;
//   if (state is Authenticated) { final uid = state.user.uid; }
//
//   or with a switch (Dart forces you to handle every state):
//   switch (state) {
//     case Authenticated(:final user): ...
//     case AuthError(:final failure): ...
//     ...
//   }

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  List<Object?> get props => [];
}

final class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  List<Object?> get props => [];
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();

  @override
  List<Object?> get props => [];
}

final class AuthError extends AuthState {
  const AuthError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();

  @override
  List<Object?> get props => [];
}
// AuthRepository = the contract the Cubits use for everything about sign in.
// Every method returns a Result (never throws), so a Cubit needs no try/catch.
//
// Usage inside AuthCubit:
//   final result = await repository.signInWithEmail(email: e, password: p);
//   result.fold(
//     onSuccess: (profile) => emit(Authenticated(profile)),
//     onFailure: (failure) => emit(AuthError(failure)),
//   );
//
// Listen to authStateChanges() once, to know who is signed in:
//   repository.authStateChanges().listen((result) { ... });
//     success(profile) -> signed in
//     success(null)    -> signed out
//     failure          -> signed in, but the profile could not be loaded
//
// There are two implementations:
//   FirebaseAuthRepository -> the real one
//   MockAuthRepository     -> fake data (USE_MOCKS), with a demo account

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';

abstract class AuthRepository {
  /// Emits the profile of the signed-in user, or null when signed out.
  Stream<Result<UserProfile?>> authStateChanges();

  Future<Result<UserProfile>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<UserProfile>> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  });

  Future<Result<void>> sendPasswordReset({required String email});

  Future<Result<void>> signOut();
}
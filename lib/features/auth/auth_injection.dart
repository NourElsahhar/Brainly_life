// Dependency injection for the auth feature (owner: M1).
// injection.dart calls this function once when the app starts.
//
// What it registers:
//   - AuthRepository: the real one (Firebase), or the Mock when USE_MOCKS.
//     The Mock starts signed in as the demo user, so the team sees the app
//     right away. To test the Login screen with mocks, sign out first
//     (or use MockAuthRepository() without startSignedIn).
//   - AuthCubit: ONE for the whole app. app.dart provides it to every screen.
//
// Ask for them anywhere with: getIt<AuthRepository>() and getIt<AuthCubit>()

import 'package:brainly_life/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:brainly_life/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

void registerAuthFeature(GetIt getIt, {required bool useMocks}) {
  getIt.registerLazySingleton<AuthRepository>(
    () => useMocks
        ? MockAuthRepository(startSignedIn: true)
        : FirebaseAuthRepository(
            dataSource: AuthRemoteDataSource(
              auth: getIt<FirebaseAuth>(),
              firestore: getIt<FirebaseFirestore>(),
            ),
          ),
  );

  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt<AuthRepository>()),
    dispose: (cubit) => cubit.close(),
  );
}
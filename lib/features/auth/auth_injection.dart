// Dependency injection for the auth feature (owner: M1).
// injection.dart calls this function once when the app starts.
//
// What it registers:
//   - AuthRepository: the real one (Firebase), or the Mock when USE_MOCKS.
//
// Ask for it anywhere with: getIt<AuthRepository>()

import 'package:brainly_life/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:brainly_life/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

void registerAuthFeature(GetIt getIt, {required bool useMocks}) {
  getIt.registerLazySingleton<AuthRepository>(
    () => useMocks
        ? MockAuthRepository()
        : FirebaseAuthRepository(
            dataSource: AuthRemoteDataSource(
              auth: getIt<FirebaseAuth>(),
              firestore: getIt<FirebaseFirestore>(),
            ),
          ),
  );
}
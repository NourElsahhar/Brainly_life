// FirebaseAuthRepository = the real AuthRepository (FirebaseAuth + Firestore).
// It catches every exception and returns a Result with a friendly Failure
// (see FirebaseErrorMapper).
//
// getTimezone: the timezone saved in the settings of a NEW user.
// For now it is UTC. Later it will come from the device (flutter_timezone).
//
// Why the _registration lock: when an account is created, Firebase says
// "a user signed in" BEFORE the profile document is written. Without the lock,
// authStateChanges() would try to create the profile at the same time.
// So while a registration is running, authStateChanges() waits for it.

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/firebase_error_mapper.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/app_logger.dart';
import 'package:brainly_life/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required AuthRemoteDataSource dataSource,
    Future<String> Function()? getTimezone,
  })  : _dataSource = dataSource,
        _getTimezone = getTimezone ?? _utcTimezone;

  final AuthRemoteDataSource _dataSource;
  final Future<String> Function() _getTimezone;

  Completer<void>? _registration;

  static Future<String> _utcTimezone() async => UserSettings.defaultTimezone;

  @override
  Stream<Result<UserProfile?>> authStateChanges() {
    return _dataSource
        .authStateChanges()
        .asyncMap<Result<UserProfile?>>((user) async {
      // Wait while a registration is writing the new profile.
      await _registration?.future;

      if (user == null) return const Result<UserProfile?>.success(null);
      return _loadProfile(user);
    });
  }

  @override
  Future<Result<UserProfile>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signInWithEmail(
        email: email.trim(),
        password: password,
      );
      final profile = await _dataSource.loadOrCreateProfile(
        user,
        timezone: await _timezone(),
      );
      return Result.success(profile);
    } catch (error) {
      return Result.failure(_fail(error, 'Sign in'));
    }
  }

  @override
  Future<Result<UserProfile>> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final registration = Completer<void>();
    _registration = registration;

    try {
      final profile = await _dataSource.registerWithEmail(
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
        timezone: await _timezone(),
      );
      return Result.success(profile);
    } catch (error) {
      return Result.failure(_fail(error, 'Register'));
    } finally {
      registration.complete();
      if (identical(_registration, registration)) _registration = null;
    }
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    try {
      await _dataSource.sendPasswordReset(email: email.trim());
      return const Result<void>.success(null);
    } catch (error) {
      return Result.failure(_fail(error, 'Password reset'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Result<void>.success(null);
    } catch (error) {
      return Result.failure(_fail(error, 'Sign out'));
    }
  }

  Future<Result<UserProfile>> _loadProfile(User user) async {
    try {
      final profile = await _dataSource.loadOrCreateProfile(
        user,
        timezone: await _timezone(),
      );
      return Result.success(profile);
    } catch (error) {
      return Result.failure(_fail(error, 'Loading the profile'));
    }
  }

  /// The device timezone, or UTC if we cannot get it.
  Future<String> _timezone() async {
    try {
      final timezone = await _getTimezone();
      return timezone.isEmpty ? UserSettings.defaultTimezone : timezone;
    } catch (_) {
      return UserSettings.defaultTimezone;
    }
  }

  /// Turns any error into a Failure. Logs only the code (no personal data).
  Failure _fail(Object error, String action) {
    final failure = FirebaseErrorMapper.map(error);
    AppLogger.warning(
      '$action failed (${failure.code ?? failure.runtimeType})',
      tag: 'Auth',
    );
    return failure;
  }
}
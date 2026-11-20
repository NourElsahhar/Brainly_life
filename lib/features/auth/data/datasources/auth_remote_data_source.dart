// AuthRemoteDataSource = talks to FirebaseAuth and to Firestore (users/{uid}).
// It only does the calls. It THROWS exceptions (FirebaseAuthException,
// FirebaseException). The repository catches them and returns a Result.
//
// Do not use this class from a Cubit. Use AuthRepository.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/constants/firestore_paths.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, FieldValue, CollectionReference;
import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSource {
    AuthRemoteDataSource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  /// Emits the signed-in user, or null when signed out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _requireUser(credential);
  }

  /// Creates the account AND the profile document users/{uid}.
  /// If the profile cannot be written, the new account is deleted, so we
  /// never leave an account without a profile.
  Future<UserProfile> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String timezone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = _requireUser(credential);

    try {
      await user.updateDisplayName(displayName);
      return await _createProfile(
        user: user,
        displayName: displayName,
        timezone: timezone,
      );
    } catch (_) {
      try {
        await user.delete();
      } catch (_) {
        // Nothing else we can do. The original error is more important.
      }
      rethrow;
    }
  }

  Future<void> sendPasswordReset({required String email}) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() => _auth.signOut();

  /// Reads users/{uid}. If it does not exist yet (for example the first
  /// sign in), it is created with the default settings.
  Future<UserProfile> loadOrCreateProfile(
    User user, {
    required String timezone,
  }) async {
    final doc = await _users.doc(user.uid).get();
    if (doc.exists) return UserProfile.fromFirestore(doc);

    return _createProfile(
      user: user,
      displayName: user.displayName ?? '',
      timezone: timezone,
    );
  }

  /// One batch, so the profile is never half-written.
  Future<UserProfile> _createProfile({
    required User user,
    required String displayName,
    required String timezone,
  }) async {
    final profile = UserProfile(
      uid: user.uid,
      displayName: displayName,
      email: user.email ?? '',
      photoUrl: user.photoURL,
      createdAt: clock.now().toUtc(),
      settings: UserSettings.defaults(timezone: timezone),
    );

    final batch = _firestore.batch();
    batch.set(_users.doc(user.uid), {
      ...profile.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return profile;
  }

  User _requireUser(UserCredential credential) {
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'internal-error');
    }
    return user;
  }
}
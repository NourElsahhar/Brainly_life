// AuthRemoteDataSource = talks to FirebaseAuth, Google Sign-In and
// Firestore (users/{uid}). It only does the calls. It THROWS exceptions (FirebaseAuthException,
// FirebaseException). The repository catches them and returns a Result.
//
// Do not use this class from a Cubit. Use AuthRepository.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/constants/firestore_paths.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, FieldValue, CollectionReference;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Taken only when Google is used, so tests never touch the real plugin.
  final GoogleSignIn? _googleSignIn;
  GoogleSignIn get _google => _googleSignIn ?? GoogleSignIn.instance;

  // initialize() must run exactly once, before the first Google call.
  Future<void>? _googleReady;

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

  /// Opens the Google account picker, then signs in to Firebase with the
  /// Google ID token. Returns null when the user closes the picker.
  /// The profile (users/{uid}) is created by loadOrCreateProfile.
  Future<User?> signInWithGoogle() async {
    final google = _google;
    try {
      await (_googleReady ??= google.initialize());
    } catch (_) {
      _googleReady = null; // so the next tap tries again
      rethrow;
    }
    if (!google.supportsAuthenticate()) {
      throw FirebaseAuthException(code: 'operation-not-allowed');
    }

    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    final credential = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    return _requireUser(credential);
  }

  Future<void> sendPasswordReset({required String email}) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    // Also forget the Google account, so the picker shows next time.
    // Only when Google was used in this session (never in tests).
    if (_googleReady != null) {
      try {
        await _google.signOut();
      } catch (_) {
        // Not important: the Firebase sign out below is what matters.
      }
    }
    await _auth.signOut();
  }

  /// Changes the name in users/{uid} and on the Firebase account.
  Future<void> updateDisplayName(String displayName) async {
    final user = _requireCurrentUser();
    await _users
        .doc(user.uid)
        .update({
          'displayName': displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(firestoreTimeout);
    await user.updateDisplayName(displayName);
  }

  /// Saves the picked avatar, or removes the field when [avatarId] is null.
  Future<void> updateAvatar(String? avatarId) async {
    final user = _requireCurrentUser();
    await _users
        .doc(user.uid)
        .update({
          'avatarId': avatarId ?? FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(firestoreTimeout);
  }

  /// Saves the whole settings map in users/{uid}.settings.
  Future<void> updateSettings(UserSettings settings) async {
    final user = _requireCurrentUser();
    await _users
        .doc(user.uid)
        .update({
          'settings': settings.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(firestoreTimeout);
  }

  /// Deletes users/{uid}, then the Firebase account.
  ///
  /// Firebase refuses to delete an account when the last sign in was long
  /// ago ('requires-recent-login'). We check that FIRST, so we never delete
  /// the profile and then fail to delete the account.
  Future<void> deleteAccount({String? password}) async {
    final user = _requireCurrentUser();

    // 0. Firebase deletes an account only right after a sign in. So the
    //    user confirms who they are FIRST (password or Google). Without
    //    this, the data was deleted but user.delete() failed and the
    //    account stayed in Authentication.
    await _reauthenticate(user, password);

    // 1. Every subcollection (tasks, habits, plans...), then users/{uid}.
    //    The app does it itself: deleteUserData (Cloud Function) needs the
    //    Blaze plan, so it is not deployed.
    await _deleteUserData(user.uid);
    await _users.doc(user.uid).delete().timeout(firestoreTimeout);
    // 2. The Firebase account.
    await user.delete();
    if (_googleReady != null) {
      try {
        await _google.signOut();
      } catch (_) {
        // Not important: the account is already deleted.
      }
    }
  }

  /// Confirms the user again before a delete.
  ///   - a password was typed -> email + password
  ///   - a Google account     -> the Google picker
  ///   - otherwise            -> only if the last sign in was recent
  Future<void> _reauthenticate(User user, String? password) async {
    final providers = {for (final info in user.providerData) info.providerId};

    if (password != null && password.isNotEmpty) {
      final email = user.email;
      if (email == null || !providers.contains('password')) {
        throw FirebaseAuthException(code: 'invalid-credential');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return;
    }

    if (providers.contains('google.com')) {
      final google = _google;
      await (_googleReady ??= google.initialize());
      if (!google.supportsAuthenticate()) {
        throw FirebaseAuthException(code: 'requires-recent-login');
      }
      final GoogleSignInAccount account;
      try {
        account = await google.authenticate();
      } on GoogleSignInException catch (error) {
        if (error.code == GoogleSignInExceptionCode.canceled) {
          throw FirebaseAuthException(code: 'requires-recent-login');
        }
        rethrow;
      }
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(code: 'invalid-credential');
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return;
    }

    // A password account that typed no password.
    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null ||
        clock.now().difference(lastSignIn) > recentLoginWindow) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
  }

  /// The longest we wait for Firestore. A Firestore write only finishes
  /// when the SERVER confirms it, so without a limit the app would wait
  /// forever when Firestore cannot be reached (no database, blocked
  /// network...). After this, TimeoutException -> a clear error message
  /// instead of an endless spinner.
  static const Duration firestoreTimeout = Duration(seconds: 15);

  /// Every subcollection of users/{uid} (FirestorePaths). A new collection
  /// MUST be added here, or "Delete account" would leave it behind.
  static const List<String> userCollections = [
    FirestorePaths.tasks,
    FirestorePaths.taskCategories,
    FirestorePaths.subjects,
    FirestorePaths.topics,
    FirestorePaths.studyPlans,
    FirestorePaths.studySessions,
    FirestorePaths.habits,
    FirestorePaths.habitLogs,
    FirestorePaths.focusSessions,
    FirestorePaths.preferences,
    FirestorePaths.aiConversations,
    FirestorePaths.weeklyReports,
    FirestorePaths.aiUsage,
  ];

  /// Deletes all the user's documents, collection by collection, in
  /// batches of 400 (a batch allows 500 operations at most).
  Future<void> _deleteUserData(String uid) async {
    for (final name in userCollections) {
      final collection = _firestore.collection(
        FirestorePaths.userCollection(uid, name),
      );
      if (name == FirestorePaths.aiConversations) {
        // Each conversation has its own messages subcollection.
        final conversations = await collection.get().timeout(firestoreTimeout);
        for (final conversation in conversations.docs) {
          await _deleteCollection(
            conversation.reference.collection(FirestorePaths.messages),
          );
        }
      }
      await _deleteCollection(collection);
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final page = await collection.limit(400).get().timeout(firestoreTimeout);
      if (page.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit().timeout(firestoreTimeout);
    }
  }

  /// How long after a sign in Firebase still allows sensitive actions.
  static const Duration recentLoginWindow = Duration(minutes: 5);

  /// Reads users/{uid}. If it does not exist yet (for example the first
  /// sign in), it is created with the default settings.
  Future<UserProfile> loadOrCreateProfile(
    User user, {
    required String timezone,
  }) async {
    final doc = await _users.doc(user.uid).get().timeout(firestoreTimeout);
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
    await batch.commit().timeout(firestoreTimeout);

    return profile;
  }

  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    return user;
  }

  User _requireUser(UserCredential credential) {
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'internal-error');
    }
    return user;
  }
}

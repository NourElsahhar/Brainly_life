// FocusRemoteDataSource = talks to Firestore for Focus (owner: M4).
// It only does the calls and THROWS exceptions; FirestoreFocusRepository
// catches them and returns a Result.
//
// Collections (Master Document, Part D):
//   users/{uid}/focusSessions/{sessionId}
//   users/{uid}/preferences/focus        (the timer settings)

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/constants/firestore_paths.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FocusRemoteDataSource {
  FocusRemoteDataSource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const Duration timeout = Duration(seconds: 15);

  /// The document id of the timer settings in users/{uid}/preferences.
  static const String settingsDocId = 'focus';

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw FirebaseAuthException(code: 'no-current-user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(
        FirestorePaths.userCollection(_uid, FirestorePaths.focusSessions),
      );

  DocumentReference<Map<String, dynamic>> get _settings => _firestore
      .collection(
        FirestorePaths.userCollection(_uid, FirestorePaths.preferences),
      )
      .doc(settingsDocId);

  /// Saves a new session with a new id and returns it.
  Future<FocusSession> saveSession(FocusSession session) async {
    final ref = _sessions.doc();
    final saved = session.copyWith(id: ref.id);
    await ref.set(saved.toFirestore()).timeout(timeout);
    return saved;
  }

  /// Sessions with fromDate <= dateKey <= toDate (one field: no index).
  Future<List<FocusSession>> getSessions({
    required String fromDate,
    required String toDate,
  }) async {
    final snapshot = await _sessions
        .where('dateKey', isGreaterThanOrEqualTo: fromDate)
        .where('dateKey', isLessThanOrEqualTo: toDate)
        .get()
        .timeout(timeout);
    return snapshot.docs.map(FocusSession.fromFirestore).toList();
  }

  /// The saved settings, or null when none are saved yet.
  Future<FocusSettings?> getSettings() async {
    final doc = await _settings.get().timeout(timeout);
    final data = doc.data();
    return data == null ? null : FocusSettings.fromMap(data);
  }

  Future<void> saveSettings(FocusSettings settings) async {
    await _settings.set(settings.toFirestore()).timeout(timeout);
  }
}

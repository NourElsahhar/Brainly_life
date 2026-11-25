// HabitRemoteDataSource = talks to Firestore for habits (owner: M4).
// It only does the calls and THROWS exceptions; FirestoreHabitRepository
// catches them and returns a Result. Do not use it from a Cubit.
//
// Collections (Master Document, Part D):
//   users/{uid}/habits/{habitId}
//   users/{uid}/habitLogs/{habitId}_{dateKey}   (one per completed day)
//
// The log id is built from the habit and the day, so a habit can never be
// completed twice on the same day, and toggling is safe to repeat.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/constants/firestore_paths.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitRemoteDataSource {
  HabitRemoteDataSource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// The longest we wait for Firestore (a write only finishes when the
  /// server confirms it). After this: TimeoutException -> a clear message.
  static const Duration timeout = Duration(seconds: 15);

  /// The uid is read on EVERY call: the user can sign out and in again.
  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw FirebaseAuthException(code: 'no-current-user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _habits => _firestore
      .collection(FirestorePaths.userCollection(_uid, FirestorePaths.habits));

  CollectionReference<Map<String, dynamic>> get _logs => _firestore.collection(
    FirestorePaths.userCollection(_uid, FirestorePaths.habitLogs),
  );

  Future<List<Habit>> getHabits() async {
    final snapshot = await _habits.get().timeout(timeout);
    return snapshot.docs.map(Habit.fromFirestore).toList();
  }

  /// The habit, or null when it does not exist.
  Future<Habit?> getHabit(String habitId) async {
    final doc = await _habits.doc(habitId).get().timeout(timeout);
    return doc.exists ? Habit.fromFirestore(doc) : null;
  }

  /// Saves a new habit with a new id and returns it.
  Future<Habit> createHabit(Habit habit) async {
    final ref = _habits.doc();
    final saved = habit.copyWith(id: ref.id);
    await ref.set(saved.toFirestore()).timeout(timeout);
    return saved;
  }

  /// Replaces the habit. Throws 'not-found' when it does not exist.
  Future<void> updateHabit(Habit habit) async {
    await _habits.doc(habit.id).update(habit.toFirestore()).timeout(timeout);
  }

  Future<void> archiveHabit(String habitId, DateTime now) async {
    await _habits
        .doc(habitId)
        .update({'archived': true, 'updatedAt': Timestamp.fromDate(now)})
        .timeout(timeout);
  }

  /// Deletes the habit and all its logs (batches of 400).
  Future<void> deleteHabit(String habitId) async {
    while (true) {
      final page = await _logs
          .where('habitId', isEqualTo: habitId)
          .limit(400)
          .get()
          .timeout(timeout);
      if (page.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit().timeout(timeout);
    }
    await _habits.doc(habitId).delete().timeout(timeout);
  }

  /// Logs with fromDate <= date <= toDate. With [habitId], of that habit
  /// only (index: habitLogs habitId + date).
  Future<List<HabitLog>> getLogs({
    required String fromDate,
    required String toDate,
    String? habitId,
  }) async {
    Query<Map<String, dynamic>> query = _logs;
    if (habitId != null) query = query.where('habitId', isEqualTo: habitId);
    final snapshot = await query
        .where('date', isGreaterThanOrEqualTo: fromDate)
        .where('date', isLessThanOrEqualTo: toDate)
        .get()
        .timeout(timeout);
    return snapshot.docs.map(HabitLog.fromFirestore).toList();
  }

  /// Every day the habit was completed (its dateKeys).
  Future<Set<String>> completedDates(String habitId) async {
    final snapshot = await _logs
        .where('habitId', isEqualTo: habitId)
        .get()
        .timeout(timeout);
    return {for (final doc in snapshot.docs) doc.data()['date'] as String};
  }

  /// In ONE transaction: writes (done) or deletes (not done) the log of
  /// [dateKey], and saves the new streak numbers on the habit, so the log
  /// and the numbers never disagree (Home and Analytics read them).
  /// Throws 'not-found' when the habit was deleted meanwhile.
  Future<void> writeToggle({
    required String habitId,
    required String dateKey,
    required bool done,
    required DateTime now,
    required int currentStreak,
    required int bestStreak,
    required String? lastCompletedDate,
  }) async {
    final habitRef = _habits.doc(habitId);
    final logRef = _logs.doc(HabitLog.buildId(habitId, dateKey));

    await _firestore
        .runTransaction((transaction) async {
          final habit = await transaction.get(habitRef);
          if (!habit.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'not-found',
            );
          }
          if (done) {
            transaction.set(
              logRef,
              HabitLog(
                habitId: habitId,
                date: dateKey,
                completedAt: now,
              ).toFirestore(),
            );
          } else {
            transaction.delete(logRef);
          }
          transaction.update(habitRef, {
            'currentStreak': currentStreak,
            'bestStreak': bestStreak,
            'lastCompletedDate': lastCompletedDate,
            'updatedAt': Timestamp.fromDate(now),
          });
        })
        .timeout(timeout);
  }
}

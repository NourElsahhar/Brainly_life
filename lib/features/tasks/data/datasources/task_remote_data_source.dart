// TaskRemoteDataSource = talks to Firestore for tasks and task categories
// (owner: M3). It only does the calls and THROWS exceptions;
// FirestoreTaskRepository and FirestoreTaskCategoryRepository catch them and
// return a Result. Do not use it from a Cubit.
//
// Collections (Master Document, Part D):
//   users/{uid}/tasks/{taskId}
//   users/{uid}/taskCategories/{categoryId}
//
// Rules (firestore.rules, M1): a task has exactly the 10 fields of
// Task.toFirestore(), createdAt never changes, and a done task has
// completedAt while an open one does not. Dates are client Timestamps,
// never FieldValue.serverTimestamp() (Task.fromMap reads them with `!`).

import 'package:brainly_life/core/constants/firestore_paths.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource({required this._auth, required this._firestore});

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// The longest we wait for Firestore (a write only finishes when the
  /// server confirms it). After this: TimeoutException -> a clear message.
  static const Duration timeout = Duration(seconds: 15);

  /// A batch holds at most 500 writes. We stay under it.
  static const int batchSize = 400;

  /// The uid is read on EVERY call: the user can sign out and in again.
  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw FirebaseAuthException(code: 'no-current-user');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _tasks => _firestore.collection(
    FirestorePaths.userCollection(_uid, FirestorePaths.tasks),
  );

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection(
        FirestorePaths.userCollection(_uid, FirestorePaths.taskCategories),
      );

  // ---------- tasks ----------

  /// Live list of the open tasks (status 'todo'). Not sorted.
  Stream<List<Task>> watchActiveTasks() {
    return _tasks
        .where('status', isEqualTo: TaskStatus.todo.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Task.fromFirestore).toList());
  }

  /// Tasks completed at or after [since], newest first, [limit] at a time.
  /// With [afterTaskId], the page that starts after that task.
  Future<List<Task>> getCompletedTasks({
    required DateTime since,
    required int limit,
    String? afterTaskId,
  }) async {
    var query = _tasks
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('completedAt', descending: true)
        .limit(limit);

    if (afterTaskId != null) {
      final last = await _tasks.doc(afterTaskId).get().timeout(timeout);
      // The last task was deleted or reopened: no next page to find.
      if (!last.exists || last.data()?['completedAt'] == null) return [];
      query = query.startAfterDocument(last);
    }

    final snapshot = await query.get().timeout(timeout);
    return snapshot.docs.map(Task.fromFirestore).toList();
  }

  /// Live updates of one task. Emits null when it does not exist.
  Stream<Task?> watchTask(String id) {
    return _tasks
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Task.fromFirestore(doc) : null);
  }

  /// Saves a new task with a new id and returns it.
  Future<Task> createTask(Task task) async {
    final ref = _tasks.doc();
    final saved = task.copyWith(id: ref.id);
    await ref.set(saved.toFirestore()).timeout(timeout);
    return saved;
  }

  /// Replaces the task. Throws 'not-found' when it does not exist.
  Future<void> updateTask(Task task) async {
    await _tasks.doc(task.id).update(task.toFirestore()).timeout(timeout);
  }

  Future<void> deleteTask(String id) async {
    await _tasks.doc(id).delete().timeout(timeout);
  }

  /// Writes [task] again with its own id (used to undo a delete).
  Future<void> restoreTask(Task task) async {
    await _tasks.doc(task.id).set(task.toFirestore()).timeout(timeout);
  }

  /// Makes every task of [categoryId] Uncategorized, in batches.
  Future<void> clearCategory(String categoryId, DateTime now) async {
    while (true) {
      final page = await _tasks
          .where('categoryId', isEqualTo: categoryId)
          .limit(batchSize)
          .get()
          .timeout(timeout);
      if (page.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.update(doc.reference, {
          'categoryId': null,
          'updatedAt': Timestamp.fromDate(now),
        });
      }
      await batch.commit().timeout(timeout);
    }
  }

  /// How many tasks are done, ever (a count query: no task is downloaded).
  Future<int> countDoneTasks() async {
    final snapshot = await _tasks
        .where('status', isEqualTo: TaskStatus.done.name)
        .count()
        .get()
        .timeout(timeout);
    return snapshot.count ?? 0;
  }

  // ---------- categories ----------

  /// Live list of the categories. Not sorted.
  Stream<List<TaskCategory>> watchCategories() {
    return _categories.snapshots().map(
      (snapshot) => snapshot.docs.map(TaskCategory.fromFirestore).toList(),
    );
  }

  /// Saves a new category with a new id and returns it.
  Future<TaskCategory> createCategory(TaskCategory category) async {
    final ref = _categories.doc();
    final saved = category.copyWith(id: ref.id);
    await ref.set(saved.toFirestore()).timeout(timeout);
    return saved;
  }

  /// Saves the new name or colour. Throws 'not-found' when it is missing.
  Future<void> updateCategory(TaskCategory category) async {
    await _categories
        .doc(category.id)
        .update(category.toFirestore())
        .timeout(timeout);
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete().timeout(timeout);
  }
}


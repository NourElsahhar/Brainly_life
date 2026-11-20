// FirestorePaths = the names of all collections, in ONE place.
// Never write 'tasks' or 'users' as text inside a data source. Use these.
//
// Everything a user owns lives under users/{uid}/... (Master Document, D.1).
//
// Usage:
//   firestore.collection(FirestorePaths.users)                       // users
//   firestore.doc(FirestorePaths.userDoc(uid))                       // users/{uid}
//   firestore.collection(
//     FirestorePaths.userCollection(uid, FirestorePaths.tasks),      // users/{uid}/tasks
//   )
//
// Need a new collection? Add its name here (after the schema PR is approved).

class FirestorePaths {
  const FirestorePaths._();

  static const String users = 'users';

  // Subcollections of users/{uid}
  static const String aiUsage = 'aiUsage';
  static const String subjects = 'subjects';
  static const String topics = 'topics';
  static const String studyPlans = 'studyPlans';
  static const String studySessions = 'studySessions';
  static const String tasks = 'tasks';
  static const String taskCategories = 'taskCategories';
  static const String habits = 'habits';
  static const String habitLogs = 'habitLogs';
  static const String focusSessions = 'focusSessions';
  static const String preferences = 'preferences';
  static const String aiConversations = 'aiConversations';
  static const String weeklyReports = 'weeklyReports';

  // Subcollection of aiConversations/{conversationId}
  static const String messages = 'messages';

  /// 'users/{uid}'
  static String userDoc(String uid) => '$users/$uid';

  /// 'users/{uid}/{name}', for example users/abc/tasks
  static String userCollection(String uid, String name) =>
      '$users/$uid/$name';
}
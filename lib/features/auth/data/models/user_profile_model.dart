// UserProfile = the user's document: users/{uid}
//
// Fields in Firestore: displayName, email, photoUrl, avatarId (only when
// the user picked one), settings (a map), createdAt, updatedAt.
// The uid is the document id (not a field).
//
// createdAt and updatedAt are written by the data source with
// FieldValue.serverTimestamp(), so toFirestore() does NOT include them.
// createdAt can never change after creation (Firestore rules).
//
// Usage:
//   final profile = UserProfile.fromFirestore(snapshot);   // read
//   final data = profile.toFirestore();                    // write
//   final renamed = profile.copyWith(displayName: 'Nour');
//   final noPhoto = profile.copyWith(clearPhotoUrl: true);
//   final withAvatar = profile.copyWith(avatarId: 'rocket');
//   final noAvatar = profile.copyWith(clearAvatarId: true);
//
// In tests (no Firebase) use fromMap:
//   UserProfile.fromMap('uid1', {'email': 'a@b.com', ...});

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'user_settings_model.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.createdAt,
    required this.settings,
    this.displayName = '',
    this.photoUrl,
    this.avatarId,
  });

  /// Reads a user document. The uid is the document id.
  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return UserProfile.fromMap(doc.id, doc.data());
  }

  /// Same as [fromFirestore] but from plain data, so it can be tested
  /// without Firebase. Missing or wrong values become safe defaults.
  factory UserProfile.fromMap(String uid, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};

    final displayName = map['displayName'];
    final email = map['email'];
    final photoUrl = map['photoUrl'];
    final avatarId = map['avatarId'];
    final settings = map['settings'];
    final createdAt = map['createdAt'];

    return UserProfile(
      uid: uid,
      displayName: displayName is String ? displayName : '',
      email: email is String ? email : '',
      photoUrl: photoUrl is String && photoUrl.isNotEmpty ? photoUrl : null,
      avatarId: avatarId is String && avatarId.isNotEmpty ? avatarId : null,
      // While a server timestamp is still pending, createdAt is null.
      createdAt: createdAt is Timestamp
          ? createdAt.toDate().toUtc()
          : clock.now().toUtc(),
      settings: UserSettings.fromMap(
        settings is Map ? Map<String, dynamic>.from(settings) : null,
      ),
    );
  }

  final String uid;
  final String displayName;
  final String email;

  /// Link to the picture (for example from the Google account), or null.
  final String? photoUrl;

  /// The avatar the user picked (see profile_avatars.dart), or null.
  /// When set, it is shown instead of the photo and the first letter.
  final String? avatarId;

  /// UTC.
  final DateTime createdAt;
  final UserSettings settings;

  /// The fields saved in Firestore (without createdAt, updatedAt and uid).
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      // Only when picked, so a new profile has exactly the old fields.
      if (avatarId != null) 'avatarId': avatarId,
      'settings': settings.toMap(),
    };
  }

  /// Use [clearPhotoUrl] to remove the photo (photoUrl: null means "no change").
  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    bool clearPhotoUrl = false,
    String? avatarId,
    bool clearAvatarId = false,
    UserSettings? settings,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      avatarId: clearAvatarId ? null : (avatarId ?? this.avatarId),
      createdAt: createdAt,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    displayName,
    email,
    photoUrl,
    avatarId,
    createdAt,
    settings,
  ];
}

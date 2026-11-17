// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_session_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StudySession {

 String get id; String get planId; String get subjectId; String get topicId; String get dateKey; DateTime get startAt; int get plannedMinutes; int get actualMinutes; SessionStatus get status; String? get reminderId; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudySessionCopyWith<StudySession> get copyWith => _$StudySessionCopyWithImpl<StudySession>(this as StudySession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StudySession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudySession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.planId, _this.planId) || other.planId == _this.planId)&&(identical(other.subjectId, _this.subjectId) || other.subjectId == _this.subjectId)&&(identical(other.topicId, _this.topicId) || other.topicId == _this.topicId)&&(identical(other.dateKey, _this.dateKey) || other.dateKey == _this.dateKey)&&(identical(other.startAt, _this.startAt) || other.startAt == _this.startAt)&&(identical(other.plannedMinutes, _this.plannedMinutes) || other.plannedMinutes == _this.plannedMinutes)&&(identical(other.actualMinutes, _this.actualMinutes) || other.actualMinutes == _this.actualMinutes)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reminderId, _this.reminderId) || other.reminderId == _this.reminderId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as StudySession;
  return Object.hash(runtimeType,_this.id,_this.planId,_this.subjectId,_this.topicId,_this.dateKey,_this.startAt,_this.plannedMinutes,_this.actualMinutes,_this.status,_this.reminderId,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as StudySession;
  return 'StudySession(id: ${_this.id}, planId: ${_this.planId}, subjectId: ${_this.subjectId}, topicId: ${_this.topicId}, dateKey: ${_this.dateKey}, startAt: ${_this.startAt}, plannedMinutes: ${_this.plannedMinutes}, actualMinutes: ${_this.actualMinutes}, status: ${_this.status}, reminderId: ${_this.reminderId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $StudySessionCopyWith<$Res>  {
  factory $StudySessionCopyWith(StudySession value, $Res Function(StudySession) _then) = _$StudySessionCopyWithImpl;
@useResult
$Res call({
 String id, String planId, String subjectId, String topicId, String dateKey, DateTime startAt, int plannedMinutes, int actualMinutes, SessionStatus status, String? reminderId, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$StudySessionCopyWithImpl<$Res>
    implements $StudySessionCopyWith<$Res> {
  _$StudySessionCopyWithImpl(this._self, this._then);

  final StudySession _self;
  final $Res Function(StudySession) _then;

/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? planId = null,Object? subjectId = null,Object? topicId = null,Object? dateKey = null,Object? startAt = null,Object? plannedMinutes = null,Object? actualMinutes = null,Object? status = null,Object? reminderId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(StudySession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,topicId: null == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String,dateKey: null == dateKey ? _self.dateKey : dateKey // ignore: cast_nullable_to_non_nullable
as String,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,plannedMinutes: null == plannedMinutes ? _self.plannedMinutes : plannedMinutes // ignore: cast_nullable_to_non_nullable
as int,actualMinutes: null == actualMinutes ? _self.actualMinutes : actualMinutes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,reminderId: freezed == reminderId ? _self.reminderId : reminderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [StudySession].
extension StudySessionPatterns on StudySession {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudySession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudySession() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudySession value)  $default,){
final _that = this;
switch (_that) {
case _StudySession():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudySession value)?  $default,){
final _that = this;
switch (_that) {
case _StudySession() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String planId,  String subjectId,  String topicId,  String dateKey,  DateTime startAt,  int plannedMinutes,  int actualMinutes,  SessionStatus status,  String? reminderId,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudySession() when $default != null:
return $default(_that.id,_that.planId,_that.subjectId,_that.topicId,_that.dateKey,_that.startAt,_that.plannedMinutes,_that.actualMinutes,_that.status,_that.reminderId,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String planId,  String subjectId,  String topicId,  String dateKey,  DateTime startAt,  int plannedMinutes,  int actualMinutes,  SessionStatus status,  String? reminderId,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _StudySession():
return $default(_that.id,_that.planId,_that.subjectId,_that.topicId,_that.dateKey,_that.startAt,_that.plannedMinutes,_that.actualMinutes,_that.status,_that.reminderId,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String planId,  String subjectId,  String topicId,  String dateKey,  DateTime startAt,  int plannedMinutes,  int actualMinutes,  SessionStatus status,  String? reminderId,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StudySession() when $default != null:
return $default(_that.id,_that.planId,_that.subjectId,_that.topicId,_that.dateKey,_that.startAt,_that.plannedMinutes,_that.actualMinutes,_that.status,_that.reminderId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _StudySession extends StudySession {
  const _StudySession({required this.id, required this.planId, required this.subjectId, required this.topicId, required this.dateKey, required this.startAt, required this.plannedMinutes, this.actualMinutes = 0, this.status = SessionStatus.planned, this.reminderId, this.createdAt, this.updatedAt}): super._();
  

@override final  String id;
@override final  String planId;
@override final  String subjectId;
@override final  String topicId;
@override final  String dateKey;
@override final  DateTime startAt;
@override final  int plannedMinutes;
@override@JsonKey() final  int actualMinutes;
@override@JsonKey() final  SessionStatus status;
@override final  String? reminderId;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudySessionCopyWith<_StudySession> get copyWith => __$StudySessionCopyWithImpl<_StudySession>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudySession&&(identical(other.id, id) || other.id == id)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.dateKey, dateKey) || other.dateKey == dateKey)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.plannedMinutes, plannedMinutes) || other.plannedMinutes == plannedMinutes)&&(identical(other.actualMinutes, actualMinutes) || other.actualMinutes == actualMinutes)&&(identical(other.status, status) || other.status == status)&&(identical(other.reminderId, reminderId) || other.reminderId == reminderId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,planId,subjectId,topicId,dateKey,startAt,plannedMinutes,actualMinutes,status,reminderId,createdAt,updatedAt);
}

@override
String toString() {
    return 'StudySession(id: $id, planId: $planId, subjectId: $subjectId, topicId: $topicId, dateKey: $dateKey, startAt: $startAt, plannedMinutes: $plannedMinutes, actualMinutes: $actualMinutes, status: $status, reminderId: $reminderId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$StudySessionCopyWith<$Res> implements $StudySessionCopyWith<$Res> {
  factory _$StudySessionCopyWith(_StudySession value, $Res Function(_StudySession) _then) = __$StudySessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String planId, String subjectId, String topicId, String dateKey, DateTime startAt, int plannedMinutes, int actualMinutes, SessionStatus status, String? reminderId, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$StudySessionCopyWithImpl<$Res>
    implements _$StudySessionCopyWith<$Res> {
  __$StudySessionCopyWithImpl(this._self, this._then);

  final _StudySession _self;
  final $Res Function(_StudySession) _then;

/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? planId = null,Object? subjectId = null,Object? topicId = null,Object? dateKey = null,Object? startAt = null,Object? plannedMinutes = null,Object? actualMinutes = null,Object? status = null,Object? reminderId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_StudySession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,topicId: null == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String,dateKey: null == dateKey ? _self.dateKey : dateKey // ignore: cast_nullable_to_non_nullable
as String,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,plannedMinutes: null == plannedMinutes ? _self.plannedMinutes : plannedMinutes // ignore: cast_nullable_to_non_nullable
as int,actualMinutes: null == actualMinutes ? _self.actualMinutes : actualMinutes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,reminderId: freezed == reminderId ? _self.reminderId : reminderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

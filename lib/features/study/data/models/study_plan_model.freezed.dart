// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StudyPlan {

 String get id; String get title; DateTime get startDate; DateTime get endDate; PlanGenerator get generatedBy; int? get promptVersion; PlanStatus get status; PlanConstraints get constraints; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of StudyPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudyPlanCopyWith<StudyPlan> get copyWith => _$StudyPlanCopyWithImpl<StudyPlan>(this as StudyPlan, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StudyPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudyPlan&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.generatedBy, _this.generatedBy) || other.generatedBy == _this.generatedBy)&&(identical(other.promptVersion, _this.promptVersion) || other.promptVersion == _this.promptVersion)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.constraints, _this.constraints) || other.constraints == _this.constraints)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as StudyPlan;
  return Object.hash(runtimeType,_this.id,_this.title,_this.startDate,_this.endDate,_this.generatedBy,_this.promptVersion,_this.status,_this.constraints,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as StudyPlan;
  return 'StudyPlan(id: ${_this.id}, title: ${_this.title}, startDate: ${_this.startDate}, endDate: ${_this.endDate}, generatedBy: ${_this.generatedBy}, promptVersion: ${_this.promptVersion}, status: ${_this.status}, constraints: ${_this.constraints}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $StudyPlanCopyWith<$Res>  {
  factory $StudyPlanCopyWith(StudyPlan value, $Res Function(StudyPlan) _then) = _$StudyPlanCopyWithImpl;
@useResult
$Res call({
 String id, String title, DateTime startDate, DateTime endDate, PlanGenerator generatedBy, int? promptVersion, PlanStatus status, PlanConstraints constraints, DateTime? createdAt, DateTime? updatedAt
});


$PlanConstraintsCopyWith<$Res> get constraints;

}
/// @nodoc
class _$StudyPlanCopyWithImpl<$Res>
    implements $StudyPlanCopyWith<$Res> {
  _$StudyPlanCopyWithImpl(this._self, this._then);

  final StudyPlan _self;
  final $Res Function(StudyPlan) _then;

/// Create a copy of StudyPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? startDate = null,Object? endDate = null,Object? generatedBy = null,Object? promptVersion = freezed,Object? status = null,Object? constraints = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(StudyPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,generatedBy: null == generatedBy ? _self.generatedBy : generatedBy // ignore: cast_nullable_to_non_nullable
as PlanGenerator,promptVersion: freezed == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanStatus,constraints: null == constraints ? _self.constraints : constraints // ignore: cast_nullable_to_non_nullable
as PlanConstraints,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of StudyPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanConstraintsCopyWith<$Res> get constraints {
  
  return $PlanConstraintsCopyWith<$Res>(_self.constraints, (value) {
    return _then(_self.copyWith(constraints: value));
  });
}
}


/// Adds pattern-matching-related methods to [StudyPlan].
extension StudyPlanPatterns on StudyPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudyPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudyPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudyPlan value)  $default,){
final _that = this;
switch (_that) {
case _StudyPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudyPlan value)?  $default,){
final _that = this;
switch (_that) {
case _StudyPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DateTime startDate,  DateTime endDate,  PlanGenerator generatedBy,  int? promptVersion,  PlanStatus status,  PlanConstraints constraints,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudyPlan() when $default != null:
return $default(_that.id,_that.title,_that.startDate,_that.endDate,_that.generatedBy,_that.promptVersion,_that.status,_that.constraints,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DateTime startDate,  DateTime endDate,  PlanGenerator generatedBy,  int? promptVersion,  PlanStatus status,  PlanConstraints constraints,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _StudyPlan():
return $default(_that.id,_that.title,_that.startDate,_that.endDate,_that.generatedBy,_that.promptVersion,_that.status,_that.constraints,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DateTime startDate,  DateTime endDate,  PlanGenerator generatedBy,  int? promptVersion,  PlanStatus status,  PlanConstraints constraints,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StudyPlan() when $default != null:
return $default(_that.id,_that.title,_that.startDate,_that.endDate,_that.generatedBy,_that.promptVersion,_that.status,_that.constraints,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _StudyPlan extends StudyPlan {
  const _StudyPlan({required this.id, required this.title, required this.startDate, required this.endDate, required this.generatedBy, this.promptVersion, this.status = PlanStatus.active, required this.constraints, this.createdAt, this.updatedAt}): super._();
  

@override final  String id;
@override final  String title;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  PlanGenerator generatedBy;
@override final  int? promptVersion;
@override@JsonKey() final  PlanStatus status;
@override final  PlanConstraints constraints;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of StudyPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudyPlanCopyWith<_StudyPlan> get copyWith => __$StudyPlanCopyWithImpl<_StudyPlan>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudyPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.generatedBy, generatedBy) || other.generatedBy == generatedBy)&&(identical(other.promptVersion, promptVersion) || other.promptVersion == promptVersion)&&(identical(other.status, status) || other.status == status)&&(identical(other.constraints, constraints) || other.constraints == constraints)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,title,startDate,endDate,generatedBy,promptVersion,status,constraints,createdAt,updatedAt);
}

@override
String toString() {
    return 'StudyPlan(id: $id, title: $title, startDate: $startDate, endDate: $endDate, generatedBy: $generatedBy, promptVersion: $promptVersion, status: $status, constraints: $constraints, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$StudyPlanCopyWith<$Res> implements $StudyPlanCopyWith<$Res> {
  factory _$StudyPlanCopyWith(_StudyPlan value, $Res Function(_StudyPlan) _then) = __$StudyPlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DateTime startDate, DateTime endDate, PlanGenerator generatedBy, int? promptVersion, PlanStatus status, PlanConstraints constraints, DateTime? createdAt, DateTime? updatedAt
});


@override $PlanConstraintsCopyWith<$Res> get constraints;

}
/// @nodoc
class __$StudyPlanCopyWithImpl<$Res>
    implements _$StudyPlanCopyWith<$Res> {
  __$StudyPlanCopyWithImpl(this._self, this._then);

  final _StudyPlan _self;
  final $Res Function(_StudyPlan) _then;

/// Create a copy of StudyPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? startDate = null,Object? endDate = null,Object? generatedBy = null,Object? promptVersion = freezed,Object? status = null,Object? constraints = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_StudyPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,generatedBy: null == generatedBy ? _self.generatedBy : generatedBy // ignore: cast_nullable_to_non_nullable
as PlanGenerator,promptVersion: freezed == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanStatus,constraints: null == constraints ? _self.constraints : constraints // ignore: cast_nullable_to_non_nullable
as PlanConstraints,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of StudyPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanConstraintsCopyWith<$Res> get constraints {
  
  return $PlanConstraintsCopyWith<$Res>(_self.constraints, (value) {
    return _then(_self.copyWith(constraints: value));
  });
}
}

// dart format on

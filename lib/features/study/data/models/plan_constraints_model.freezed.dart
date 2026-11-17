// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_constraints_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlanConstraints {

 Map<int, int> get minutesPerWeekday; Set<int> get daysOff; int get maxSessionMinutes; int get breakMinutes;
/// Create a copy of PlanConstraints
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanConstraintsCopyWith<PlanConstraints> get copyWith => _$PlanConstraintsCopyWithImpl<PlanConstraints>(this as PlanConstraints, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlanConstraints;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanConstraints&&const DeepCollectionEquality().equals(other.minutesPerWeekday, _this.minutesPerWeekday)&&const DeepCollectionEquality().equals(other.daysOff, _this.daysOff)&&(identical(other.maxSessionMinutes, _this.maxSessionMinutes) || other.maxSessionMinutes == _this.maxSessionMinutes)&&(identical(other.breakMinutes, _this.breakMinutes) || other.breakMinutes == _this.breakMinutes));
}


@override
int get hashCode {
  final _this = this as PlanConstraints;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.minutesPerWeekday),const DeepCollectionEquality().hash(_this.daysOff),_this.maxSessionMinutes,_this.breakMinutes);
}

@override
String toString() {
  final _this = this as PlanConstraints;
  return 'PlanConstraints(minutesPerWeekday: ${_this.minutesPerWeekday}, daysOff: ${_this.daysOff}, maxSessionMinutes: ${_this.maxSessionMinutes}, breakMinutes: ${_this.breakMinutes})';
}


}

/// @nodoc
abstract mixin class $PlanConstraintsCopyWith<$Res>  {
  factory $PlanConstraintsCopyWith(PlanConstraints value, $Res Function(PlanConstraints) _then) = _$PlanConstraintsCopyWithImpl;
@useResult
$Res call({
 Map<int, int> minutesPerWeekday, Set<int> daysOff, int maxSessionMinutes, int breakMinutes
});




}
/// @nodoc
class _$PlanConstraintsCopyWithImpl<$Res>
    implements $PlanConstraintsCopyWith<$Res> {
  _$PlanConstraintsCopyWithImpl(this._self, this._then);

  final PlanConstraints _self;
  final $Res Function(PlanConstraints) _then;

/// Create a copy of PlanConstraints
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minutesPerWeekday = null,Object? daysOff = null,Object? maxSessionMinutes = null,Object? breakMinutes = null,}) {
  return _then(PlanConstraints(
minutesPerWeekday: null == minutesPerWeekday ? _self.minutesPerWeekday : minutesPerWeekday // ignore: cast_nullable_to_non_nullable
as Map<int, int>,daysOff: null == daysOff ? _self.daysOff : daysOff // ignore: cast_nullable_to_non_nullable
as Set<int>,maxSessionMinutes: null == maxSessionMinutes ? _self.maxSessionMinutes : maxSessionMinutes // ignore: cast_nullable_to_non_nullable
as int,breakMinutes: null == breakMinutes ? _self.breakMinutes : breakMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanConstraints].
extension PlanConstraintsPatterns on PlanConstraints {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanConstraints value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanConstraints() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanConstraints value)  $default,){
final _that = this;
switch (_that) {
case _PlanConstraints():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanConstraints value)?  $default,){
final _that = this;
switch (_that) {
case _PlanConstraints() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<int, int> minutesPerWeekday,  Set<int> daysOff,  int maxSessionMinutes,  int breakMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanConstraints() when $default != null:
return $default(_that.minutesPerWeekday,_that.daysOff,_that.maxSessionMinutes,_that.breakMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<int, int> minutesPerWeekday,  Set<int> daysOff,  int maxSessionMinutes,  int breakMinutes)  $default,) {final _that = this;
switch (_that) {
case _PlanConstraints():
return $default(_that.minutesPerWeekday,_that.daysOff,_that.maxSessionMinutes,_that.breakMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<int, int> minutesPerWeekday,  Set<int> daysOff,  int maxSessionMinutes,  int breakMinutes)?  $default,) {final _that = this;
switch (_that) {
case _PlanConstraints() when $default != null:
return $default(_that.minutesPerWeekday,_that.daysOff,_that.maxSessionMinutes,_that.breakMinutes);case _:
  return null;

}
}

}

/// @nodoc


class _PlanConstraints extends PlanConstraints {
  const _PlanConstraints({required  Map<int, int> minutesPerWeekday, required  Set<int> daysOff, required this.maxSessionMinutes, required this.breakMinutes}): _minutesPerWeekday = minutesPerWeekday,_daysOff = daysOff,super._();
  

 final  Map<int, int> _minutesPerWeekday;
@override Map<int, int> get minutesPerWeekday {
  if (_minutesPerWeekday is EqualUnmodifiableMapView) return _minutesPerWeekday;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_minutesPerWeekday);
}

 final  Set<int> _daysOff;
@override Set<int> get daysOff {
  if (_daysOff is EqualUnmodifiableSetView) return _daysOff;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_daysOff);
}

@override final  int maxSessionMinutes;
@override final  int breakMinutes;

/// Create a copy of PlanConstraints
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanConstraintsCopyWith<_PlanConstraints> get copyWith => __$PlanConstraintsCopyWithImpl<_PlanConstraints>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanConstraints&&const DeepCollectionEquality().equals(other.minutesPerWeekday, _minutesPerWeekday)&&const DeepCollectionEquality().equals(other.daysOff, _daysOff)&&(identical(other.maxSessionMinutes, maxSessionMinutes) || other.maxSessionMinutes == maxSessionMinutes)&&(identical(other.breakMinutes, breakMinutes) || other.breakMinutes == breakMinutes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_minutesPerWeekday),const DeepCollectionEquality().hash(_daysOff),maxSessionMinutes,breakMinutes);
}

@override
String toString() {
    return 'PlanConstraints(minutesPerWeekday: $minutesPerWeekday, daysOff: $daysOff, maxSessionMinutes: $maxSessionMinutes, breakMinutes: $breakMinutes)';
}


}

/// @nodoc
abstract mixin class _$PlanConstraintsCopyWith<$Res> implements $PlanConstraintsCopyWith<$Res> {
  factory _$PlanConstraintsCopyWith(_PlanConstraints value, $Res Function(_PlanConstraints) _then) = __$PlanConstraintsCopyWithImpl;
@override @useResult
$Res call({
 Map<int, int> minutesPerWeekday, Set<int> daysOff, int maxSessionMinutes, int breakMinutes
});




}
/// @nodoc
class __$PlanConstraintsCopyWithImpl<$Res>
    implements _$PlanConstraintsCopyWith<$Res> {
  __$PlanConstraintsCopyWithImpl(this._self, this._then);

  final _PlanConstraints _self;
  final $Res Function(_PlanConstraints) _then;

/// Create a copy of PlanConstraints
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minutesPerWeekday = null,Object? daysOff = null,Object? maxSessionMinutes = null,Object? breakMinutes = null,}) {
  return _then(_PlanConstraints(
minutesPerWeekday: null == minutesPerWeekday ? _self._minutesPerWeekday : minutesPerWeekday // ignore: cast_nullable_to_non_nullable
as Map<int, int>,daysOff: null == daysOff ? _self._daysOff : daysOff // ignore: cast_nullable_to_non_nullable
as Set<int>,maxSessionMinutes: null == maxSessionMinutes ? _self.maxSessionMinutes : maxSessionMinutes // ignore: cast_nullable_to_non_nullable
as int,breakMinutes: null == breakMinutes ? _self.breakMinutes : breakMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

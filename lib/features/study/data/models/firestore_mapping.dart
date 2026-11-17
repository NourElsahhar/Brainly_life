import 'package:cloud_firestore/cloud_firestore.dart';

T requireField<T>(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is T) {
    return value;
  }
  throw FormatException('Field "$key" is missing or is not of type $T.');
}

DateTime requireDate(Map<String, dynamic> data, String key) {
  return requireField<Timestamp>(data, key).toDate().toUtc();
}

DateTime? optionalDate(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate().toUtc();
  }
  throw FormatException('Field "$key" is not a Timestamp.');
}

T parseEnum<T extends Enum>(List<T> values, Object? raw, String key) {
  for (final value in values) {
    if (value.name == raw) {
      return value;
    }
  }
  throw FormatException('Unknown value "$raw" for field "$key".');
}

Map<String, dynamic> requireMap(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw FormatException('Field "$key" is missing or is not a map.');
}

T? optionalField<T>(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) {
    return null;
  }
  if (value is T) {
    return value;
  }
  throw FormatException('Field "$key" is not of type $T.');
}

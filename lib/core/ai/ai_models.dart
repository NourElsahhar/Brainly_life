import 'package:equatable/equatable.dart';

enum AiFeature { studyPlan, habitSuggest, chat, dailyTip, weeklyInsight }

Object? _freeze(Object? value) => switch (value) {
  Map<String, Object?> map => Map<String, Object?>.unmodifiable(
    map.map((key, value) => MapEntry(key, _freeze(value))),
  ),
  List<Object?> list => List<Object?>.unmodifiable(list.map(_freeze)),
  _ => value,
};

class AiRequest extends Equatable {
  AiRequest({
    required this.feature,
    required Map<String, Object?> payload,
    this.promptVersion,
  }) : payload = _freeze(payload) as Map<String, Object?>;

  final AiFeature feature;
  final Map<String, Object?> payload;
  final int? promptVersion;

  AiRequest copyWith({
    AiFeature? feature,
    Map<String, Object?>? payload,
    int? promptVersion,
  }) => AiRequest(
    feature: feature ?? this.feature,
    payload: payload ?? this.payload,
    promptVersion: promptVersion ?? this.promptVersion,
  );

  Map<String, Object?> toJson() => {
    'feature': feature.name,
    'payload': payload,
    if (promptVersion != null) 'promptVersion': promptVersion,
  };

  @override
  List<Object?> get props => [feature, payload, promptVersion];
}

class AiUsage extends Equatable {
  const AiUsage({required this.remainingToday, required this.feature});

  final int remainingToday;
  final AiFeature feature;

  factory AiUsage.fromJson(Map<String, Object?> json) => AiUsage(
    remainingToday: json['remainingToday'] as int,
    feature: AiFeature.values.byName(json['feature'] as String),
  );

  @override
  List<Object?> get props => [remainingToday, feature];
}

class AiResponse extends Equatable {
  AiResponse({required Map<String, Object?> data, required this.usage})
    : data = _freeze(data) as Map<String, Object?>;

  factory AiResponse.fromJson(Map<String, Object?> json) => AiResponse(
    data: Map<String, Object?>.from(json['data'] as Map),
    usage: AiUsage.fromJson(Map<String, Object?>.from(json['usage'] as Map)),
  );

  final Map<String, Object?> data;
  final AiUsage usage;

  @override
  List<Object?> get props => [data, usage];
}

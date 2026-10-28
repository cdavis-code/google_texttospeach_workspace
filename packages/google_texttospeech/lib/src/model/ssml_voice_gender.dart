import 'package:json_annotation/json_annotation.dart';

/// Gender of the voice for SSML input.
enum SsmlVoiceGender {
  /// Voice that supports SSML is unspecified.
  @JsonValue('SSML_GENDER_UNSPECIFIED')
  unspecified,

  /// Voice that supports SSML is male.
  @JsonValue('MALE')
  male,

  /// Voice that supports SSML is female.
  @JsonValue('FEMALE')
  female,

  /// Voice that supports SSML is neutral.
  @JsonValue('NEUTRAL')
  neutral,

  /// Decoded value for any gender string this client version does not know
  /// (via `@JsonKey(unknownEnumValue: SsmlVoiceGender.fallback)` on fields).
  /// Never send this in a request.
  unknown;

  static const SsmlVoiceGender fallback = SsmlVoiceGender.unknown;
}

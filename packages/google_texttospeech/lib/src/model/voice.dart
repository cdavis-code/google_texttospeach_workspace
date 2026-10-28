import 'dart:convert';

import 'package:google_texttospeech/src/model/ssml_voice_gender.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice.g.dart';

/// A Google Cloud Text-to-Speech voice.
@JsonSerializable()
class Voice {
  /// The unique URI-encoded identifier of the voice, e.g. `en-US-Wavenet-D`.
  final String? name;

  /// IETF BCP 47 language codes this voice supports.
  final List<String>? languageCodes;

  /// The gender of this voice (relevant only for SSML input).
  @JsonKey(unknownEnumValue: SsmlVoiceGender.fallback)
  final SsmlVoiceGender? ssmlGender;

  /// The natural sample rate in Hertz of audio synthesized by this voice.
  final double? naturalSampleRateHertz;

  const Voice({
    this.name,
    this.languageCodes,
    this.ssmlGender,
    this.naturalSampleRateHertz,
  });

  factory Voice.fromJson(Map<String, dynamic> json) => _$VoiceFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}

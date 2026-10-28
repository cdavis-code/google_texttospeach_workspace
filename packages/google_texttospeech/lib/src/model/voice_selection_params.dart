import 'dart:convert';

import 'package:google_texttospeech/src/model/ssml_voice_gender.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_selection_params.g.dart';

/// Description of the voice requested for synthesis.
@JsonSerializable()
class VoiceSelectionParams {
  /// Required. IETF BCP 47 language tag of the desired voice, e.g. `en-US`.
  final String languageCode;

  /// Optional name of the voice, e.g. `en-US-Wavenet-D`.
  final String? name;

  /// Optional model name. Leave unset for normal voices — Chirp 3 HD and the
  /// other named voices work via the full [name] (e.g.
  /// `en-US-Chirp3-HD-Achernar`), not by setting this. Only some AutoML/custom
  /// voice setups require an explicit model here.
  final String? modelName;

  /// Optional preferred gender for the voice.
  @JsonKey(unknownEnumValue: SsmlVoiceGender.fallback)
  final SsmlVoiceGender? ssmlGender;

  const VoiceSelectionParams({
    required this.languageCode,
    this.name,
    this.modelName,
    this.ssmlGender,
  });

  factory VoiceSelectionParams.fromJson(Map<String, dynamic> json) =>
      _$VoiceSelectionParamsFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSelectionParamsToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}

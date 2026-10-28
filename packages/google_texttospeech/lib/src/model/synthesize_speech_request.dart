import 'dart:convert';

import 'package:google_texttospeech/src/model/audio_config.dart';
import 'package:google_texttospeech/src/model/synthesis_input.dart';
import 'package:google_texttospeech/src/model/voice_selection_params.dart';
import 'package:json_annotation/json_annotation.dart';

part 'synthesize_speech_request.g.dart';

/// The top-level message sent by the client for the `text.synthesize` method.
@JsonSerializable()
class SynthesizeSpeechRequest {
  /// Required. The SynthesisInput.
  final SynthesisInput input;

  /// Required. The VoiceSelectionParams.
  final VoiceSelectionParams voice;

  /// Required. The AudioConfig.
  final AudioConfig audioConfig;

  const SynthesizeSpeechRequest({
    required this.input,
    required this.voice,
    required this.audioConfig,
  });

  factory SynthesizeSpeechRequest.fromJson(Map<String, dynamic> json) =>
      _$SynthesizeSpeechRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SynthesizeSpeechRequestToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}

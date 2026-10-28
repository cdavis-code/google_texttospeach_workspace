import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'synthesize_speech_response.g.dart';

/// The message returned to the client by the `text.synthesize` method.
@JsonSerializable()
class SynthesizeSpeechResponse {
  /// The base64-encoded audio data.
  final String? audioContent;

  const SynthesizeSpeechResponse({this.audioContent});

  factory SynthesizeSpeechResponse.fromJson(Map<String, dynamic> json) =>
      _$SynthesizeSpeechResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SynthesizeSpeechResponseToJson(this);

  /// Convenience: decoded audio bytes, or null when [audioContent] is absent.
  Uint8List? get audioBytes =>
      audioContent == null ? null : base64Decode(audioContent!);

  @override
  String toString() => jsonEncode(toJson());
}

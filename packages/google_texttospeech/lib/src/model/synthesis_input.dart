import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'synthesis_input.g.dart';

/// Text or SSML input to be synthesized. Exactly one of [text] or [ssml]
/// must be provided.
@JsonSerializable()
class SynthesisInput {
  /// The text to synthesize.
  final String? text;

  /// The SSML document to synthesize.
  final String? ssml;

  /// Optional system instruction for controllable/promptable voice models
  /// (e.g. Gemini-TTS): steers tone/style. Ignored by non-promptable models.
  final String? prompt;

  SynthesisInput({this.text, this.ssml, this.prompt})
    : assert(
        (text == null) != (ssml == null),
        'Exactly one of text or ssml must be provided.',
      );

  factory SynthesisInput.fromJson(Map<String, dynamic> json) =>
      _$SynthesisInputFromJson(json);

  Map<String, dynamic> toJson() => _$SynthesisInputToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}

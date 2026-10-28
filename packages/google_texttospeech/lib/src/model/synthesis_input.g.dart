// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synthesis_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SynthesisInput _$SynthesisInputFromJson(Map<String, dynamic> json) =>
    SynthesisInput(
      text: json['text'] as String?,
      ssml: json['ssml'] as String?,
      prompt: json['prompt'] as String?,
    );

Map<String, dynamic> _$SynthesisInputToJson(SynthesisInput instance) =>
    <String, dynamic>{
      'text': ?instance.text,
      'ssml': ?instance.ssml,
      'prompt': ?instance.prompt,
    };

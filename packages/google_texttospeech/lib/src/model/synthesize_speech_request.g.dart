// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synthesize_speech_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SynthesizeSpeechRequest _$SynthesizeSpeechRequestFromJson(
  Map<String, dynamic> json,
) => SynthesizeSpeechRequest(
  input: SynthesisInput.fromJson(json['input'] as Map<String, dynamic>),
  voice: VoiceSelectionParams.fromJson(json['voice'] as Map<String, dynamic>),
  audioConfig: AudioConfig.fromJson(
    json['audioConfig'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$SynthesizeSpeechRequestToJson(
  SynthesizeSpeechRequest instance,
) => <String, dynamic>{
  'input': instance.input.toJson(),
  'voice': instance.voice.toJson(),
  'audioConfig': instance.audioConfig.toJson(),
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioConfig _$AudioConfigFromJson(Map<String, dynamic> json) => AudioConfig(
  audioEncoding: $enumDecode(_$AudioEncodingEnumMap, json['audioEncoding']),
  speakingRate: (json['speakingRate'] as num?)?.toDouble(),
  pitch: (json['pitch'] as num?)?.toDouble(),
  sampleRateHertz: (json['sampleRateHertz'] as num?)?.toInt(),
  volumeGainDb: (json['volumeGainDb'] as num?)?.toDouble(),
  effectsProfile: (json['effectsProfile'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AudioConfigToJson(AudioConfig instance) =>
    <String, dynamic>{
      'audioEncoding': _$AudioEncodingEnumMap[instance.audioEncoding]!,
      'speakingRate': ?instance.speakingRate,
      'pitch': ?instance.pitch,
      'sampleRateHertz': ?instance.sampleRateHertz,
      'volumeGainDb': ?instance.volumeGainDb,
      'effectsProfile': ?instance.effectsProfile,
    };

const _$AudioEncodingEnumMap = {
  AudioEncoding.linear16: 'LINEAR16',
  AudioEncoding.mp3: 'MP3',
  AudioEncoding.oggOpus: 'OGG_OPUS',
  AudioEncoding.unknown: 'unknown',
};

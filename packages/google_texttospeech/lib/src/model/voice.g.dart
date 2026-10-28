// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Voice _$VoiceFromJson(Map<String, dynamic> json) => Voice(
  name: json['name'] as String?,
  languageCodes: (json['languageCodes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  ssmlGender: $enumDecodeNullable(
    _$SsmlVoiceGenderEnumMap,
    json['ssmlGender'],
    unknownValue: SsmlVoiceGender.unknown,
  ),
  naturalSampleRateHertz: (json['naturalSampleRateHertz'] as num?)?.toDouble(),
);

Map<String, dynamic> _$VoiceToJson(Voice instance) => <String, dynamic>{
  'name': ?instance.name,
  'languageCodes': ?instance.languageCodes,
  'ssmlGender': ?_$SsmlVoiceGenderEnumMap[instance.ssmlGender],
  'naturalSampleRateHertz': ?instance.naturalSampleRateHertz,
};

const _$SsmlVoiceGenderEnumMap = {
  SsmlVoiceGender.unspecified: 'SSML_GENDER_UNSPECIFIED',
  SsmlVoiceGender.male: 'MALE',
  SsmlVoiceGender.female: 'FEMALE',
  SsmlVoiceGender.neutral: 'NEUTRAL',
  SsmlVoiceGender.unknown: 'unknown',
};

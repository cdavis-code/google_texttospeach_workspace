// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_selection_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceSelectionParams _$VoiceSelectionParamsFromJson(
  Map<String, dynamic> json,
) => VoiceSelectionParams(
  languageCode: json['languageCode'] as String,
  name: json['name'] as String?,
  modelName: json['modelName'] as String?,
  ssmlGender: $enumDecodeNullable(
    _$SsmlVoiceGenderEnumMap,
    json['ssmlGender'],
    unknownValue: SsmlVoiceGender.unknown,
  ),
);

Map<String, dynamic> _$VoiceSelectionParamsToJson(
  VoiceSelectionParams instance,
) => <String, dynamic>{
  'languageCode': instance.languageCode,
  'name': ?instance.name,
  'modelName': ?instance.modelName,
  'ssmlGender': ?_$SsmlVoiceGenderEnumMap[instance.ssmlGender],
};

const _$SsmlVoiceGenderEnumMap = {
  SsmlVoiceGender.unspecified: 'SSML_GENDER_UNSPECIFIED',
  SsmlVoiceGender.male: 'MALE',
  SsmlVoiceGender.female: 'FEMALE',
  SsmlVoiceGender.neutral: 'NEUTRAL',
  SsmlVoiceGender.unknown: 'unknown',
};

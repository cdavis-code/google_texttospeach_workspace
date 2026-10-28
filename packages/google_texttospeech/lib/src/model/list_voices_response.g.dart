// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_voices_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListVoicesResponse _$ListVoicesResponseFromJson(Map<String, dynamic> json) =>
    ListVoicesResponse(
      voices: (json['voices'] as List<dynamic>?)
          ?.map((e) => Voice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ListVoicesResponseToJson(ListVoicesResponse instance) =>
    <String, dynamic>{
      'voices': ?instance.voices?.map((e) => e.toJson()).toList(),
    };

import 'dart:convert';

import 'package:google_texttospeech/src/model/voice.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_voices_response.g.dart';

/// The message returned for a `voices.list` request.
@JsonSerializable()
class ListVoicesResponse {
  /// The list of voices.
  final List<Voice>? voices;

  const ListVoicesResponse({this.voices});

  factory ListVoicesResponse.fromJson(Map<String, dynamic> json) =>
      _$ListVoicesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListVoicesResponseToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}

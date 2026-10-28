import 'dart:convert';

import 'package:google_texttospeech/src/model/audio_encoding.dart';
import 'package:json_annotation/json_annotation.dart';

part 'audio_config.g.dart';

/// Configuration for the synthesized audio.
@JsonSerializable()
class AudioConfig {
  /// Required. Encoding of the returned audio.
  final AudioEncoding audioEncoding;

  /// Speaking rate: 0.25 to 4.0. Values > 1.0 raise pitch.
  final double? speakingRate;

  /// Additional pitch (in semitones) applied: -20.0 to 20.0.
  final double? pitch;

  /// Sample rate in Hertz of the returned audio.
  final int? sampleRateHertz;

  /// Volume gain (in dB) applied: -40.0 to 40.0.
  final double? volumeGainDb;

  /// An effect profile of the selected voice, e.g. `HEADPHONE_CLASS`.
  final List<String>? effectsProfile;

  const AudioConfig({
    required this.audioEncoding,
    this.speakingRate,
    this.pitch,
    this.sampleRateHertz,
    this.volumeGainDb,
    this.effectsProfile,
  });

  factory AudioConfig.fromJson(Map<String, dynamic> json) =>
      _$AudioConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AudioConfigToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}

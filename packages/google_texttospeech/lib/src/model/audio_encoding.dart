import 'package:json_annotation/json_annotation.dart';

/// The encoding of the audio stream in the response.
enum AudioEncoding {
  /// Output in the Linear16 format.
  @JsonValue('LINEAR16')
  linear16,

  /// Output in the MP3 format.
  @JsonValue('MP3')
  mp3,

  /// Output in the Ogg Opus format.
  @JsonValue('OGG_OPUS')
  oggOpus,

  /// Decoded value for any encoding string this client version does not
  /// know (via `@JsonKey(unknownEnumValue: AudioEncoding.fallback)`).
  unknown;

  static const AudioEncoding fallback = AudioEncoding.unknown;
}

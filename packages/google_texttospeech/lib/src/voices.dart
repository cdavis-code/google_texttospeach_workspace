import 'package:google_texttospeech/src/provider/voices.dart';
import 'package:google_texttospeech/src/text_to_speech_api_helper.dart';
import 'package:google_texttospeech/google_texttospeech.dart';

/// The `voices` resource: list voices available from the Text-to-Speech API.
class Voices extends TextToSpeechApiHelper {
  final VoicesClient _rest;

  Voices({required super.dio, super.apiKey}) : _rest = VoicesClient(dio);

  /// Returns a list of [Voice] definitions available to the project.
  /// Set [languageCode] to filter to voices that can synthesize that
  /// BCP-47 language (e.g. `en-US`); omit to get every voice.
  Future<ListVoicesResponse> list({String? languageCode}) async {
    return _rest.list(apiKey, accept, languageCode: languageCode);
  }
}

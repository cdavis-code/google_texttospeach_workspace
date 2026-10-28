import 'package:google_texttospeech/src/provider/synthesize.dart';
import 'package:google_texttospeech/src/text_to_speech_api_helper.dart';
import 'package:google_texttospeech/google_texttospeech.dart';

/// The `text` resource: synthesize speech from [SynthesisInput].
class Synthesize extends TextToSpeechApiHelper {
  final SynthesizeClient _rest;

  Synthesize({required super.dio, super.apiKey})
    : _rest = SynthesizeClient(dio);

  /// Synthesizes the given [input] with the given [voice] selection rendered
  /// according to [audioConfig]. Returns a [SynthesizeSpeechResponse] whose
  /// `audioContent` is base64-encoded audio.
  Future<SynthesizeSpeechResponse> synthesize({
    required SynthesisInput input,
    required VoiceSelectionParams voice,
    required AudioConfig audioConfig,
  }) async {
    return _rest.synthesize(
      apiKey,
      accept,
      contentType,
      SynthesizeSpeechRequest(
        input: input,
        voice: voice,
        audioConfig: audioConfig,
      ),
    );
  }
}

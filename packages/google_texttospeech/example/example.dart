import 'dart:io';

import 'package:google_texttospeech/google_texttospeech.dart';

/// Requires a Google Cloud Text-to-Speech API key.
///
/// Create one in the Google Cloud Console (enable the Text-to-Speech API,
/// then Credentials > Create credentials > API key) and **restrict the key
/// to the Text-to-Speech API** so a leak cannot affect anything else.
/// Provide it either via the GOOGLE_TTS_API_KEY environment variable or a
/// `.env` file in the current directory (see `.env.example`).
Future<void> main() async {
  // API key auth: the key is sent as the `key` query parameter on every
  // request. Both v1 methods (`voices.list`, `text:synthesize`) support it.
  final tts = GoogleTts.withApiKey();

  // List voices (filter to a language, or omit languageCode for all).
  final voices = await tts.voices.list(languageCode: 'en-US');
  for (final voice in voices.voices ?? const <Voice>[]) {
    print('${voice.name} ${voice.languageCodes} ${voice.ssmlGender}');
  }

  // Synthesize plain text into MP3 audio.
  final response = await tts.synthesize.synthesize(
    input: SynthesisInput(
      text: 'Hello from the Google Cloud Text-to-Speech API!',
    ),
    voice: VoiceSelectionParams(
      languageCode: 'en-US',
      name: 'en-US-Wavenet-D',
      ssmlGender: SsmlVoiceGender.male,
    ),
    audioConfig: AudioConfig(audioEncoding: AudioEncoding.mp3),
  );

  final audio = response.audioBytes;
  if (audio == null) {
    stderr.writeln('No audio content returned.');
    exit(1);
  }

  File('helloworld.mp3').writeAsBytesSync(audio);
  print('Wrote helloworld.mp3 (${audio.length} bytes)');

  // Synthesize SSML markup (note: `text` and `ssml` are mutually exclusive).
  final ssmlResponse = await tts.synthesize.synthesize(
    input: SynthesisInput(
      ssml:
          '<speak>Saying <break time="300ms"/>this with SSML is '
          '<emphasis level="strong">really cool</emphasis>.</speak>',
    ),
    voice: const VoiceSelectionParams(languageCode: 'en-US'),
    audioConfig: const AudioConfig(
      audioEncoding: AudioEncoding.mp3,
      speakingRate: 1.1,
    ),
  );
  File('ssml.mp3').writeAsBytesSync(ssmlResponse.audioBytes!);
  print('Wrote ssml.mp3');

  // OAuth / token-generator auth (for higher quotas or per-project billing):
  //
  //   final tts = GoogleTts.withOAuth(oauthClient: myOauth2Client);
  //   final tts = await GoogleTts.withGenerator(MyAdcTokenGenerator());
  //
  // See packages/google_texttospeech_cli/authentication.md.

  tts.close();
}

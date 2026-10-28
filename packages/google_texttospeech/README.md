# google_texttospeech

[![Buy Me A Coffee](https://raw.githubusercontent.com/cdavis-code/easy_onvif_workspace/main/logo/buy_me_a_coffee.svg)](https://www.buymeacoffee.com/cdavis)

Native Dart interface to the **Google Cloud Text-to-Speech REST API v1**
(`voices.list` and `text:synthesize`).

## Usage

```dart
import 'dart:io';

import 'package:google_texttospeech/google_texttospeech.dart';

// API key auth (recommended): GOOGLE_TTS_API_KEY env var, ./.env, or explicit.
final tts = GoogleTts.withApiKey(apiKey: 'AIza...');

// List voices (optionally filtered by language).
final voices = await tts.voices.list(languageCode: 'en-US');
print(voices.voices?.map((v) => v.name));

// Synthesize speech. `text` and `ssml` are mutually exclusive.
final result = await tts.synthesize.synthesize(
  input: SynthesisInput(text: 'Hello world!'),
  voice: const VoiceSelectionParams(
    languageCode: 'en-US',
    name: 'en-US-Wavenet-D',
  ),
  audioConfig: const AudioConfig(
    audioEncoding: AudioEncoding.mp3,
    speakingRate: 1.0,
  ),
);

File('hello.mp3').writeAsBytesSync(result.audioBytes!);

tts.close();
```

## Authentication

| Factory | Use when |
|---|---|
| `GoogleTts.withApiKey()` | Default. Works for both v1 methods. Restrict the key to the Text-to-Speech API in Cloud Console. |
| `GoogleTts.withOAuth(oauthClient: ...)` | Quota / billing-account needs. The only v1 scope is `cloud-platform` (whole-project access) — read the security notes in [../google_texttospeech_cli/authentication.md](../google_texttospeech_cli/authentication.md). |
| `await GoogleTts.withGenerator(gen)` | You supply access tokens from your own secret manager / ADC; the library never persists credentials. |

## Example

See [example/example.dart](example/example.dart) (run with
`GOOGLE_TTS_API_KEY` set).

## License

MIT — see [LICENSE](LICENSE).

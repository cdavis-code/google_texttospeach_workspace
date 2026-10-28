# google_texttospeech Workspace

[![Buy Me A Coffee](https://raw.githubusercontent.com/cdavis-code/easy_onvif_workspace/main/logo/buy_me_a_coffee.svg)](https://www.buymeacoffee.com/cdavis)

Native Dart interface to the Google Cloud Text-to-Speech REST API (v1),
plus a command-line tool.

## Packages

| Package | Description |
|---|---|
| [google_texttospeech](packages/google_texttospeech) | Core Dart library for the Cloud Text-to-Speech v1 API |
| [google_texttospeech_cli](packages/google_texttospeech_cli) | `tts` command-line interface for the library |

## Quick Start

### Core Library (Dart)

```dart
import 'dart:io';

import 'package:google_texttospeech/google_texttospeech.dart';

final tts = GoogleTts.withApiKey(); // reads GOOGLE_TTS_API_KEY or ./.env

final response = await tts.synthesize.synthesize(
  input: SynthesisInput(text: 'Hello world!'),
  voice: const VoiceSelectionParams(languageCode: 'en-US'),
  audioConfig: const AudioConfig(audioEncoding: AudioEncoding.mp3),
);

File('hello.mp3').writeAsBytesSync(response.audioBytes!);
```

### CLI Tool

```sh
dart pub global activate google_texttospeech_cli

export GOOGLE_TTS_API_KEY=your-api-key   # see authentication notes below
tts voices list --language-code en-US
tts synthesize synthesize --text "Hello world" --out hello.mp3
```

## Authentication

**Recommended:** a Cloud Console API key **restricted to the Text-to-Speech
API** — both v1 methods work with it and a leak cannot affect anything else.
OAuth 2.0 (quota/billing-account use cases) is also supported via
`tts authorize`, but note that the only v1 OAuth scope is
`cloud-platform` (whole-project access) and refresh tokens are stored as
plaintext files. See
[packages/google_texttospeech_cli/authentication.md](packages/google_texttospeech_cli/authentication.md)
for the full trade-offs before choosing OAuth.

## Development

```sh
# Get dependencies for all packages
melos bootstrap

# Run build_runner for code generation (retrofit + json_serializable)
melos run build

# Analyze / format / test
melos run analyze
melos run format
melos run test
```

## License

MIT License - see [LICENSE](LICENSE) for details.

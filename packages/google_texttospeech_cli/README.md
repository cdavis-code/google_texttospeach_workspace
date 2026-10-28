# google_texttospeech_cli

[![Buy Me A Coffee](https://raw.githubusercontent.com/cdavis-code/easy_onvif_workspace/main/logo/buy_me_a_coffee.svg)](https://www.buymeacoffee.com/cdavis)

A command-line interface for the Google Cloud Text-to-Speech API, built on
[`google_texttospeech`](../google_texttospeech).

## Install

```sh
dart pub global activate google_texttospeech_cli
tts --help
```

## Usage

```sh
# Authenticate with an API key (recommended; restrict it to the TTS API):
export GOOGLE_TTS_API_KEY=your-api-key

# List voices — default prints only names usable by `synthesize --name`
tts voices list
tts voices list --language-code en-US

# Full voice records (JSON), including global aliases
tts voices list --full

# Synthesize speech to a file
tts synthesize synthesize --text "Hello world" --name en-US-Wavenet-D --out hello.mp3

# SSML input
tts synthesize synthesize --ssml '<speak>Hello <break time="300ms"/>world</speak>' --out hello.mp3

# Base64 audio on stdout
tts synthesize synthesize --text "Hi" --out - | base64 -d > hi.mp3

# Or use OAuth (higher quotas / per-project billing — see authentication.md
# for the security trade-offs before you do):
tts authorize --credentials-file client_secret.json
```

## Authentication

See [authentication.md](authentication.md). Summary: prefer an API key
restricted to the Text-to-Speech API. OAuth is supported but the only v1
scope is `cloud-platform` (project-wide), and stored refresh tokens are
plaintext files with `chmod 600`.

## Piping / scripting (`tts ... | jq`)

The `dart pub global` shim prints resolver chatter ("Downloading packages…",
"Building package executable…") to **stdout** before the command runs, which
corrupts a pipe to `jq`. Compile a real executable once and use it for
machine-readable output — it writes only your JSON to stdout:

```sh
dart compile exe bin/tts.dart -o "$HOME/.local/bin/tts-bin"
tts-bin voices list --language-code en-US | jq -r '.voices[].name'
```

## License

MIT — see [LICENSE](LICENSE).

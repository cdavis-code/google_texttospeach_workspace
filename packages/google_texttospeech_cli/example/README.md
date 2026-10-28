# google_texttospeech_cli examples

Authentication (choose one):

```sh
# Recommended: a Cloud Console API key restricted to the Text-to-Speech API.
export GOOGLE_TTS_API_KEY=your-api-key

# Or OAuth (needed for quota/billing and for promptable Gemini-TTS models):
dart run bin/tts.dart authorize --credentials-file client_secret.json
unset GOOGLE_TTS_API_KEY   # force the CLI to use the stored OAuth token
```

List the voice names that `synthesize --name` accepts:

```sh
dart run bin/tts.dart voices list --language-code en-US
dart run bin/tts.dart voices list --language-code en-US --full   # raw JSON records
```

Synthesize speech:

```sh
# A standard / Chirp 3 HD voice by its full name.
dart run bin/tts.dart synthesize synthesize \
  --text "Hello world" --name en-US-Chirp3-HD-Achernar --out hello.mp3

# A promptable Gemini-TTS model (needs OAuth + billing + aiplatform.user).
dart run bin/tts.dart synthesize synthesize \
  --text "Hello world" --prompt "Read aloud in a warm, welcoming tone." \
  --name Achernar --model-name gemini-3.1-flash-tts-preview \
  --language-code en-us --encoding mp3 --out hello.mp3
```

See [../authentication.md](../authentication.md) for the full setup and the
`gemini-*-tts` prerequisites.

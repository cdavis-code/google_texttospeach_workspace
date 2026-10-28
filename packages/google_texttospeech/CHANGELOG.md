# Changelog

## 0.1.0

- Initial release: native Dart client for the Google Cloud Text-to-Speech
  REST API v1 (`voices.list` and `text:synthesize`).
- Auth via API key (`GoogleTts.withApiKey`), OAuth2 (`withOAuth`), or a
  pluggable `RefreshTokenGenerator` (`withGenerator`).
- Supports Chirp 3 HD voices by full name and promptable Gemini-TTS models via
  `VoiceSelectionParams.modelName` and `SynthesisInput.prompt`.

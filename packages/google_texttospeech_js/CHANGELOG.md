# Changelog

## 0.1.0

- Initial release: `@unngh/google-texttospeech` — dart2js-compiled JavaScript
  bindings + TypeScript/npm wrapper for the `google_texttospeech` core
  (Cloud Text-to-Speech v1: `voices.list`, `text:synthesize`).
- Universal (browser + Node.js) `GoogleTts` client with `withApiKey`,
  `withOAuth` (Node-only), `voicesList`, `synthesize`, `close`; base64 audio
  returned in `audioContent`.

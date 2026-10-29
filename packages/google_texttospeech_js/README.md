# @unngh/google-texttospeech

JavaScript/TypeScript bindings for the
[`google_texttospeech`](../google_texttospeech) Dart package — a universal
(browser + Node.js) client for the Google Cloud Text-to-Speech REST API v1
(`voices.list`, `text:synthesize`), compiled to JS with dart2js.

## Install

```sh
npm install @unngh/google-texttospeech
```

## Usage

```ts
import { GoogleTts } from '@unngh/google-texttospeech/node';   // or .../browser

const tts = await GoogleTts.withApiKey(process.env.GOOGLE_TTS_API_KEY!);

const { voices } = await tts.voicesList('en-US');
console.log(voices?.map((v) => v.name));

const { audioContent } = await tts.synthesize({
  input: { text: 'Hello world' },                 // or { ssml } / add { prompt }
  voice: { languageCode: 'en-US', name: 'en-US-Wavenet-D' },
  audioConfig: { audioEncoding: 'MP3' },
});

const bytes = Buffer.from(audioContent!, 'base64');   // Node; use atob() in browsers
```

`@unngh/google-texttospeech/node` also offers `GoogleTts.fromEnv()` (reads
`GOOGLE_TTS_API_KEY`). `withOAuth` is Node-only and throws in the browser.

## Building from source

```sh
npm install
npm run build      # build:dart (dart2js) then build:ts (tsup)
npm test           # vitest interop smoke test
npm run typecheck  # tsc --noEmit
```

## License

MIT — see [LICENSE](LICENSE).

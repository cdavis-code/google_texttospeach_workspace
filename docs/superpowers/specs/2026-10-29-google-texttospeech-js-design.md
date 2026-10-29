# google_texttospeech_js — Design Spec

Date: 2026-10-29
Status: approved (approach: full mirror of reference `packages/yt_js`)
Reference: https://github.com/cdavis-code/yt_workspace/tree/main/packages/yt_js

## Summary

A new workspace package `packages/google_texttospeech_js` that compiles the
`google_texttospeech` core Dart library to JavaScript (`dart compile js`) and wraps
it in a typed TypeScript/npm layer, published to npm as **`@unngh/google-texttospeech`**.
Structurally identical to the reference `yt_js`, downsized to the two-method TTS v1
surface (`voices.list`, `text:synthesize`). The Dart `google_texttospeech` and
`google_texttospeech_cli` packages stay behaviorally unchanged.

## Decisions (from user)

- npm name/scope: **`@unngh/google-texttospeech`** (npm scope `@unngh`, like the reference; the
  pub.dev publisher `cdavis.ca` is irrelevant to the Dart package — it is `publish_to: none`).
- Auth surface: **both** `withApiKey` and `withOAuth`, matching `yt_js` parity, even though
  `withOAuth` throws at runtime in a browser (the core's web OAuth stub is unsupported). Documented.
- Compiles the core's existing web-compatible paths (`universal_io` + the
  `if (dart.library.io)` conditional in `oauth_access_control_interface.dart`) — no `dart:io`
  is reachable from the browser `withApiKey` call (apiKey is always passed explicitly, so the
  `.env`/`File` code never runs).

## Package layout (mirrors yt_js)

```
packages/google_texttospeech_js/
├── pubspec.yaml                       # name google_texttospeech_js; publish_to: none;
│                                      # resolution: workspace; sdk ^3.8.0
│                                      # deps: google_texttospeech ^0.1.0, loggy ^2.0.3,
│                                      #       universal_io ^2.3.1, web ^1.1.1
│                                      # dev: lints ^6.1.0
├── lib/google_texttospeech_js.dart    # dart2js entry: main(){ bindings.install(); }
├── lib/src/js_bindings.dart           # installs globalThis.GoogleTtsJs (dart:js_interop)
├── src/index.ts                       # GoogleTts facade (typed, loader-less base)
├── src/types.ts                       # TS interfaces (request/response/handle/namespace/options)
├── src/runtime.ts                     # getRuntime(loader) -> globalThis.GoogleTtsJs
├── src/browser.ts                     # browser loader (dynamic import of compiled runtime)
├── src/node.ts                        # node loader (self/window polyfill) + fromEnv()
├── tsup.config.ts                     # esm browser+node bundles, cjs node, d.ts
├── tsconfig.json
├── vitest.config.ts
├── scripts/build.sh                   # dart compile js -> build/dart + copy to dist/*.runtime.js
├── scripts/publish-npm.sh             # npm version + build + publish + git tag
├── package.json                       # name @unngh/google-texttospeech, exports/files/scripts
├── .gitignore .npmignore
├── README.md CHANGELOG.md LICENSE      # LICENSE = repo MIT copy
```

No `test/` directory with Dart tests; JS tests live in `test/*.test.ts` (vitest).

## Dart JS interop surface (`js_bindings.dart`)

Entry installs a namespace; a returned handle carries methods. Mirrors the reference
`install()` / `_wrap()` / `_dartToJs` / `_jsToDartMap` shape verbatim (the JSON round-trip
helpers are copied as-is).

```dart
// globalThis.GoogleTtsJs = { version, withApiKey, withOAuth }
GoogleTts handle:
  voicesList(languageCode?)            -> Promise<ListVoicesResponse JSON>
  synthesize(requestJson)              -> Promise<SynthesizeSpeechResponse JSON>
  close()                              -> {}
```

- `withApiKey(apiKey: JSString, logLevel?: JSString)`: init Loggy, `GoogleTts.withApiKey(apiKey: ...)`, return `_wrap(googleTts)`.
- `withOAuth(logLevel?)`: `GoogleTts.withOAuth(...)` (throws in browser — accepted).
- `synthesize`: `final req = SynthesizeSpeechRequest.fromJson(_jsToDartMap(body));`
  then `googleTts.synthesize.synthesize(input: req.input, voice: req.voice, audioConfig: req.audioConfig)`
  and `_dartToJs(res.toJson())`. Reuses existing core models/service — no core changes.
- `voicesList`: `googleTts.voices.list(languageCode: ...)` -> `_dartToJs(res.toJson())`.
- The response `audioContent` is base64; passed through in JSON (decoded by callers in TS/JS).

`_wrap` sets exactly: `voicesList`, `synthesize`, `close`. Errors: async bodies throw →
the `Future.toJS` promise rejects; the TS layer surfaces the message (no silent swallow).

## TypeScript layer

- `types.ts`: `interface SynthesisInput {text?; ssml?; prompt?}`, `VoiceSelectionParams`,
  `AudioConfig`, `SynthesizeSpeechRequest`, `SynthesizeSpeechResponse {audioContent?: string}`,
  `ListVoicesResponse {voices?: Voice[]}`, `GoogleTtsJsHandle {voicesList; synthesize; close}`,
  `GoogleTtsJsNamespace {version; withApiKey; withOAuth}`, `ConnectOptions {logLevel?}`.
- `index.ts`: `class GoogleTts` wrapping a handle; static `withApiKey(apiKey, opts, loader?)`
  and `withOAuth(opts, loader?)` (throw if no loader); methods `voicesList({languageCode?})`,
  `synthesize(req)`, `close()` returning typed Promises.
- `runtime.ts`: cache + `(globalThis as any).GoogleTtsJs` (copy of yt_js `getRuntime`).
- `browser.ts`/`node.ts`: subclass with `loadDart()` importing `../build/dart/google_texttospeech_js.js`
  (bundled into dist by tsup); node also polyfills `self`/`window` and adds
  `fromEnv()` reading `process.env.GOOGLE_TTS_API_KEY`.
- npm entry points mirror yt_js: `main`=node.cjs, `module`=node.js, `types`=index.d.ts,
  `exports` for `.`/`./browser`/`./node`; `files`: dist, README.md, LICENSE; `type: module`;
  engines node>=18.
- `scripts`: build:dart, build:ts(tsup), build, typecheck, test(vitest), clean, prepublishOnly.

## Build mechanism

`scripts/build.sh` (port of yt_js): `dart pub get`, `dart compile js -O4
-o build/dart/google_texttospeech_js.js lib/google_texttospeech_js.dart`, strip `.deps`,
copy to `dist/google_texttospeech_js.runtime.js`. Then `tsup` emits the ESM/CJS/d.ts.

## Workspace + tooling integration (keep Dart pipeline green)

- Root `pubspec.yaml`:
  - `workspace:` add `- packages/google_texttospeech_js`.
  - melos `format-check` and `_test_internal` add
    `packageFilters.ignore: [google_texttospeech_js]` (mirror yt_js exclusion — its
    tests are vitest, not `dart test`, and node build isn't a dart format target). Keep
    `analyze` including it (its `lib/*.dart` should stay lint-clean).
  - `meta`/`dartdoc` scopes unchanged (js package has no meta/pub.dartdoc need; exclude from dartdoc).
- `melos bootstrap` must succeed with the new member (it resolves
  `google_texttospeech ^0.1.0` via workspace-local resolution, which now also exists published).
- `.gitignore` add `packages/google_texttospeech_js/{node_modules,build,dist}` (package-local
  .gitignore too, like reference).

## CI

- `dart.yml`: the existing `dart format --set-exit-if-changed .`/analyze already tolerate the
  new Dart files; ensure the format/test ignore applies (or the JS package has no dart-only
  lint issues). No behavioral change to existing jobs.
- Optional new `.github/workflows/publish-npm.yml` gated on tags
  `google-texttospeech-v*`: setup dart+node, `scripts/build.sh`, `npm ci && npm run build:ts`,
  `npm publish`. Marked optional in the plan; add only if the user wants automated npm releases.

## Testing

- One vitest smoke test: build first, then assert loading the browser runtime installs
  `globalThis.GoogleTtsJs` with `withApiKey`/`withOAuth`/`version` and that a handle exposes
  `voicesList`/`synthesize`/`close`. No network. (Matches the "one runnable check" rule; the
  interop wiring is the non-trivial part.)
- Dart core behavior unchanged; existing `models_test.dart` / cli tests stay the safety net.

## Success criteria

- `melos bootstrap` green with 3 packages.
- `melos run analyze` green (js package Dart lints clean); `melos run format-check` green
  (js package excluded from dart format/test like the reference).
- `bash scripts/build.sh` emits `build/dart/google_texttospeech_js.js` + `dist/…runtime.js`;
  `npm run build` (tsup) emits dist ESM/CJS + `index.d.ts`; `npx vitest run` passes;
  `tsc --noEmit` clean.
- `google_texttospeech` / `google_texttospeech_cli` outputs byte-for-byte unchanged.

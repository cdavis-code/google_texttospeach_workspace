# google_texttospeech_workspace — Design Spec

Date: 2026-10-27
Status: approved (approach A: 1:1 structural port of `yt_workspace`)
Reference: https://github.com/cdavis-code/yt_workspace
API: https://cloud.google.com/text-to-speech/docs/reference/rest/v1

## Summary

Dart monorepo providing a native client for **Google Cloud Text-to-Speech REST API v1**
(exactly two methods: `voices.list`, `text:synthesize`) plus a CLI. Structure, layering,
code generation, and auth patterns mirror the `yt`/`yt_cli` packages of the reference
project, downsized to the TTS surface.

## Scope decisions (from user)

- v1 only. **No** long-running operations / batch synthesis (`projects.locations.operations.*`).
- Full auth mirror: API key, OAuth2 (interactive `authorize` + stored tokens), and pluggable token generator.
- Packages: `google_texttospeech` (core lib), `google_texttospeech_cli` (CLI). No JS/MCP/homebrew ports.
- CLI executable name: `tts`.

## v1 API surface (ground truth)

Base URL: `https://texttospeech.googleapis.com/v1`

| Method | HTTP | Notes |
|---|---|---|
| `voices.list` | `GET /voices?languageCode=` | API key usable (no pagination in v1) |
| `text.synthesize` | `POST /text:synthesize` (JSON body) | API key usable |

Models (field names per discovery doc; all sub-fields nullable except required ones):

- `ListVoicesResponse { List<Voice> voices }`
- `Voice { String name, List<String> languageCodes, SsmlVoiceGender ssmlGender, double naturalSampleRateHertz }`
- `SynthesizeSpeechRequest { SynthesisInput input*, VoiceSelectionParams voice*, AudioConfig audioConfig* }` (`*` required)
- `SynthesisInput { String text, String ssml }` — mutually exclusive (oneof)
- `VoiceSelectionParams { String languageCode, String name, SsmlVoiceGender ssmlGender }`
- `AudioConfig { AudioEncoding audioEncoding*, double speakingRate, double pitch, int sampleRateHertz, double volumeGainDb, List<String> effectsProfile }`
- `SynthesizeSpeechResponse { String audioContent }` — base64-encoded audio
- `AudioEncoding` enum: `LINEAR16 | MP3 | OGG_OPUS` (json value strings, `Unknown` fallback like `yt` enums)
- `SsmlVoiceGender` enum: `SSML_GENDER_UNSPECIFIED | MALE | FEMALE | NEUTRAL` (`Unknown` fallback)

## Repository layout

```
google_texttospeach_workspace/
├── pubspec.yaml              # name: google_texttospeech_workspace; publish_to: none;
│                             # environment sdk ^3.8.0; workspace: packages/*; dev_dep melos ^7.7.0;
│                             # melos: block with scripts (below)
├── analysis_options.yaml     # include lints/recommended; exclude **/*.g.dart;
│                             # strict-inference, strict-raw-types (verbatim reference)
├── AGENTS.md                 # overview / packages table / commands / conventions (ported)
├── README.md  CHANGELOG.md  LICENSE (MIT)  .gitignore  .pubignore
├── .github/workflows/dart.yml        # format-check + analyze --fatal-infos on push/PR to main
├── tool/update_meta.dart             # regenerates lib/meta.dart from pubspec (ported)
└── packages/
    ├── google_texttospeech/
    └── google_texttospeech_cli/
```

Melos scripts mirror the reference (homebrew script dropped): `lint:all`, `dep`,
`build` (`dart run build_runner build --delete-conflicting-outputs`, filter `fileExists: build.yaml`),
`meta` + `_meta_internal`, `analyze` (`dart analyze --fatal-infos`, concurrency 1),
`format`, `format-check`, `test` + `_test_internal` (`dart test`, filter `dirExists: test`), `dartdoc`.

Both packages: `resolution: workspace`, `environment: sdk: ^3.8.0`, version `0.1.0`.

## Core package `packages/google_texttospeech`

### pubspec

deps: `dio ^5.9.2`, `http`, `http_parser`, `json_annotation ^4.12.0`, `loggy ^2.0.3`,
`oauth2 ^2.0.5`, `retrofit ^4.9.2`, `universal_io ^2.3.1` (+ `path_provider` only if the
reference's credentials path resolution needs it — mirror `yt` exactly).
dev deps: `build_runner ^2.15.0`, `json_serializable ^6.14.0`, `lints ^6.1.0`,
`retrofit_generator ^10.2.6`, `test`.
`build.yaml`: json_serializable options `create_to_json/create_factory: true`, exclude `**/*.g.dart` sources (verbatim reference).

### lib tree

```
lib/
├── google_texttospeech.dart     # barrel: exports base, services, models, util
├── oauth.dart                   # conditional export io/web OAuthAccessControl (ported)
├── meta.dart                    # melos-generated name/version
└── src/
    ├── google_tts_base.dart     # class GoogleTts (see below)
    ├── text_to_speech_api_helper.dart   # port of youtube_api_helper: dio, apiKey,
    │                                    # accept/contentType, buildQuery helpers
    ├── synthesize.dart          # class Synthesize extends helper -> SynthesizeClient
    ├── voices.dart              # class Voices extends helper -> VoicesClient
    ├── provider/
    │   ├── synthesize.dart|.g.dart      # @RestApi(baseUrl 'https://texttospeech.googleapis.com/v1')
    │   │                                # @POST('/text:synthesize', @Query('key'), @Header headers, @Body)
    │   └── voices.dart|.g.dart          # @GET('/voices', @Query('key'), @Query('pageSize'), @Query('pageToken'))
    ├── model/                   # one file per model above + .g.dart, subdirs only if >8 files
    │   ├── audio_config.dart  audio_encoding.dart  list_voices_response.dart
    │   ├── ssml_voice_gender.dart  synthesis_input.dart  synthesize_speech_request.dart
    │   ├── synthesize_speech_response.dart  voice.dart  voice_selection_params.dart
    │   └── util/                # oauth_credentials, google_oauth_credentials, token, jwt_credentials (ported, as `yt`)
    ├── oauth/                   # oauth_access_control.dart, _interface, _io, _web,
    │                            # refresh_token_generator.dart (ported from `yt`)
    └── util/                    # authorization_exception, credentials_path, enum, extras,
                                 # logging_interceptors, util (ported; Util.envTtsApiKey = 'GOOGLE_TTS_API_KEY')
```

### `GoogleTts` base class (mirrors `Yt` verbatim in shape)

- static `Dio dio`, static `_interceptors`, `Loggy` via `UiLoggy`.
- factories: `GoogleTts.withApiKey({String? apiKey, Map<String,String>? additionalHeaders})`
  (resolves `GOOGLE_TTS_API_KEY` env / `.env`, throws `ArgumentError` when missing);
  `GoogleTts.withOAuth({oauth2.Client? oauthClient, LogOptions logOptions})` (bearer interceptor via
  `OAuthAccessControl`); `static Future<GoogleTts> withGenerator(RefreshTokenGenerator)`.
- `_resetSharedState()` before each factory (prevents interceptor leaks) — same as reference.
- modules: `Voices get voices`, `Synthesize get synthesize` (both available under key and OAuth auth;
  no `_moduleUnavailableMessage` branching needed since both v1 methods accept API keys).
- `void close() => dio.close()`.

### Service classes

- `Voices.list({String? languageCode})` → `Future<ListVoicesResponse>`.
- `Synthesize.synthesize({required SynthesisInput input, required VoiceSelectionParams voice, required AudioConfig audioConfig})`
  → `Future<SynthesizeSpeechResponse>`; body serialized via model `toJson()`.
- Validation at the trust boundary: `SynthesisInput` constructor asserts text/ssml are not both set
  (throws `ArgumentError`), since the API 400s on multi-oneof.

## CLI package `packages/google_texttospeech_cli`

```
bin/tts.dart                       # CommandRunner<void>('tts', ...) + --log-level option,
                                   # exit(64) on UsageException (verbatim reference shape)
lib/
├── google_texttospeech_cli.dart   # barrel of commands
├── meta.dart
└── src/
    ├── cmd/
    │   ├── tts_helper_command.dart      # abstract YtHelperCommand port: initializeTts(),
    │   │                                # exposes `voices`, `synthesize`, close(); reads
    │   │                                # client_secret.json + tts_access_tokens.json,
    │   │                                # GOOGLE_TTS_CLIENT_SECRETS_FILE / GOOGLE_TTS_ACCESS_TOKENS_FILE
    │   ├── tts_authorize_command.dart   # installed-app OAuth flow + consent + token store (ported)
    │   ├── tts_version_command.dart     # prints meta.dart version
    │   ├── voices_command.dart          # `tts voices` group -> `list` subcommand
    │   └── synthesize_command.dart      # `tts synthesize` group -> `synthesize` subcommand
    └── util/security_util.dart          # ported client-secret parse/validate
```

pubspec deps: `google_texttospeech: ^0.1.0` (path via workspace), `args ^2.7.0`, `dio`, `loggy`,
`oauth2`, `universal_io`; `executables: {tts: tts}`.

CLI flags (`synthesize` group):
`--text` XOR `--ssml` (exactly one required, enforced with `UsageException`), `--name`,
`--language-code`, `--gender` (male|female|neutral|unspecified), `--encoding` (linear16|mp3|ogg_opus,
default mp3), `--speaking-rate`, `--pitch`, `--sample-rate`, `--volume-gain`, `--effects-profile`
(comma-separated list), `--out <file>` (writes decoded bytes; default `out.<ext from encoding>`;
`--out -` → stdout base64). `tts voices list [--language-code TAG]` prints
`response` (model `toString` via JSON) like reference commands print responses.
Auth mode: env `.env`/`GOOGLE_TTS_API_KEY` key first, else stored OAuth tokens; mirrors
reference fallback messaging (`Run "tts authorize" ...`).

## Error handling

- Library: `DioException` propagates; `AuthorizationException` ported for auth problems;
  no custom retry logic (YAGNI; retrofit/dio surface it).
- CLI: `on DioException catch → throw UsageException('API usage error:', err.error)` pattern
  ported from reference; exit code 64 for usage errors.

## Testing

Reference has no tests; this project leaves ONE minimal check (ponytail rule):
`packages/google_texttospeech/test/models_test.dart` —
JSON round-trip of `SynthesizeSpeechRequest`/`Voice`/`AudioConfig` (enum mappings incl. `Unknown`),
and `SynthesisInput` throws when text+ssml both set. No network, no mocks.
CLI/library auth wiring is exercised manually via `tts voices list` with a real key during bring-up.

## Bring-up order (for the implementation plan)

1. Root workspace files + both package pubspecs + `melos bootstrap` green.
2. Core: util → model (+ codegen green: `melos run build`, `analyze`) → provider clients → services → base → barrel.
3. Example (`example/example.dart`, API-key path) + one test.
4. CLI: helper → voices/synthesize/authorize/version → bin → `dart pub global activate --source path`.
5. AGENTS.md/READMEs, CI workflow, `melos run lint:all` + `melos run test` green.

## Success criteria

`melos bootstrap`, `melos run build`, `melos run analyze` (--fatal-infos), `melos run format-check`,
`melos run test` all green; `tts voices list` and `tts synthesize --text ... --out out.mp3`
produce real audio with a valid API key; repo tree matches this spec file-for-file.

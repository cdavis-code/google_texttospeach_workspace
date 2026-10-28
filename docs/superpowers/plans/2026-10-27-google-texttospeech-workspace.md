# google_texttospeech_workspace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Dart melos workspace with `google_texttospeech` (v1 Cloud TTS REST client: `voices.list` + `text:synthesize`) and `google_texttospeech_cli` (`tts` binary), structurally mirroring `yt_workspace`.

**Architecture:** Retrofit/Dio generated HTTP clients behind thin service classes (`Voices`, `Synthesize`) extending an API-helper base; a static-Dio `GoogleTts` entry class with `withApiKey`/`withOAuth`/`withGenerator` factories; json_serializable models; CLI on `args/command_runner` with one command-group file per resource. Full spec: `docs/superpowers/specs/2026-10-27-google-texttospeech-design.md`.

**Tech Stack:** Dart SDK ^3.8.0 (local 3.13), melos 8, dio 5, retrofit + retrofit_generator, json_annotation + json_serializable, oauth2, loggy, universal_io, args.

**Reference source:** `third_party/yt` and `third_party/yt_cli` (verbatim copy of `cdavis-code/yt_workspace` packages) and `third_party/tool/update_meta.dart`. Ported files are copied then renamed per the **Substitution table** below — the copy+rename IS the port; no logic changes beyond listed fixes.

## Substitution table (applies to every ported file)

| Find | Replace | Notes |
|---|---|---|
| `package:yt/` | `package:google_texttospeech/` | imports |
| `package:yt_cli/` | `package:google_texttospeech_cli/` | imports |
| `package:yt/yt.dart` | `package:google_texttospeech/google_texttospeech.dart` | covered by row 1 + file rename |
| `class Yt ` / `Yt.` / `Yt(` / `< Yt` / ` Yt>` | `GoogleTts` | word boundary; watch doc-comments |
| `YouTubeApiHelper` | `TextToSpeechApiHelper` | |
| `youtube_api_helper.dart` | `text_to_speech_api_helper.dart` | import paths |
| `envYtApiKey` / `YT_API_KEY` | `envTtsApiKey` / `GOOGLE_TTS_API_KEY` | |
| `envYtClientSecretsFile` / `YT_CLIENT_SECRETS_FILE` | `envTtsClientSecretsFile` / `GOOGLE_TTS_CLIENT_SECRETS_FILE` | |
| `envYtAccessTokensFile` / `YT_ACCESS_TOKENS_FILE` | `envTtsAccessTokensFile` / `GOOGLE_TTS_ACCESS_TOKENS_FILE` | |
| `YT_DISABLE_DOTENV` | `GOOGLE_TTS_DISABLE_DOTENV` | |
| `.yt` (dirname) | `.tts` | credentials dir default |
| `access_tokens.json` default → `tts_access_tokens.json` | only in CLI helper (`tts_server_tokens.json` per spec is NOT used; keep single consistent name) | decision locked: `tts_access_tokens.json` everywhere |
| `https://www.googleapis.com/auth/youtube.force-ssl` | `https://www.googleapis.com/auth/cloud-platform` | TTS OAuth scope |
| `yt authorize` (user-facing strings) | `tts authorize` | |
| `yt_cli` in messages | `google_texttospeech_cli` | |
| `Running "yt"` / YouTube prose | Text-to-Speech prose | error messages, help text |

**Not ported (deliberately, YAGNI):** `util/enum.dart` (only `ModerationStatus` — unused), `util/extras.dart` (keep — used by CLI `err.usage`), model/util `jwt_credentials`/`json_settings` (no JWT flow in v1 CLI), `withKey` deprecated alias, homebrew/JS/MCP machinery. `util/util.dart` ships trimmed: keep `convertToLogOptions`, `defaultEncoding`, `ListPosition`, env-var consts, credential filename consts; drop YouTube-only helpers (`responseMaxResults`, `maxResults`, `getUploadIdFromUrl`, `base64GCloud*`, `unixTimeStamp`, `cast`, `TextFormat`).

---

### Task 1: Workspace root

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `LICENSE`, `CHANGELOG.md`, `README.md` (root stub)

- [ ] **Step 1: Write root `pubspec.yaml`**

```yaml
name: google_texttospeech_workspace
publish_to: none

environment:
  sdk: ^3.8.0

workspace:
  - packages/google_texttospeech
  - packages/google_texttospeech_cli

dev_dependencies:
  melos: ^8.0.0

melos:
  name: google_texttospeech_workspace
  packages:
    - packages/**

  command:
    bootstrap:
      runPubGetInParallel: false
      usePubspecOverrides: true

  scripts:
    lint:all:
      run: melos run analyze && melos run format-check
    dep:
      run: dart pub get
      exec:
        concurrency: 1
    build:
      run: dart run build_runner build --delete-conflicting-outputs
      packageFilters:
        fileExists: build.yaml
    meta:
      run: melos run _meta_internal --no-select
      description: Regenerate lib/meta.dart from pubspec.yaml.
    _meta_internal:
      exec: dart \$MELOS_ROOT_PATH/tool/update_meta.dart
      packageFilters:
        scope:
          - google_texttospeech
          - google_texttospeech_cli
    analyze:
      run: dart analyze --fatal-infos
      exec:
        concurrency: 1
    format:
      run: dart format .
      exec:
        concurrency: 1
    format-check:
      run: dart format --output=none --set-exit-if-changed .
    test:
      run: melos run _test_internal --no-select
      exec:
        concurrency: 1
    _test_internal:
      exec: dart test
      packageFilters:
        dirExists: test
    dartdoc:
      run: dart doc
      packageFilters:
        scope: google_texttospeech
```

- [ ] **Step 2: Write `analysis_options.yaml`** (copy of reference root file, plus generated-file exclusion already inside)

```yaml
include: package:lints/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
  language:
    strict-inference: true
    strict-raw-types: true
```

- [ ] **Step 3: Copy `.gitignore`, `LICENSE`, root `CHANGELOG.md` from reference**

`third_party/yt/LICENSE` → `LICENSE` (copy as-is). Root `.gitignore`: write the standard Dart one (`.dart_tool/`, `.packages`, `pubspec_overrides.yaml`, `.env`, `doc/api/`, `*.iml` except none needed). `.env` MUST be ignored — it holds API keys.

- [ ] **Step 4: Verify + commit**

Run: `melos bootstrap` — Expected: fails with "packages/google_texttospeech not found" is OK at this point; instead verify YAML parses: `dart pub get` at root may fail until Task 2 exists. So only commit now:
`git add -A && git commit -m "chore: scaffold melos/dart workspace root"`

---

### Task 2: Core package pubspec + build.yaml + ported util/oauth layer

**Files:**
- Create: `packages/google_texttospeech/{pubspec.yaml,build.yaml,.pubignore,example/}`
- Copy+substitute: all files below from `third_party/`

- [ ] **Step 1: Write `packages/google_texttospeech/pubspec.yaml`**

```yaml
name: google_texttospeech
version: 0.1.0
description: Native Dart interface to the Google Cloud Text-to-Speech REST API v1.
homepage: https://github.com/cdavis-code/google_texttospeach_workspace/tree/main/packages/google_texttospeech
repository: https://github.com/cdavis-code/google_texttospeach_workspace
issue_tracker: https://github.com/cdavis-code/google_texttospeach_workspace/issues

topics:
  - api
  - text-to-speech
  - google
  - oauth2
  - rest

resolution: workspace

environment:
  sdk: ^3.8.0

dependencies:
  dio: ^5.9.2
  http: ^1.6.0
  json_annotation: ^4.12.0
  loggy: ^2.0.3
  oauth2: ^2.0.5
  retrofit: ^4.9.2
  universal_io: ^2.3.1

dev_dependencies:
  build_runner: ^2.15.0
  json_serializable: ^6.14.0
  lints: ^6.1.0
  retrofit_generator: ^10.2.6
  test: ^1.26.0
```

- [ ] **Step 2: Copy `build.yaml` verbatim** from `third_party/yt/build.yaml`.

- [ ] **Step 3: Copy+substitute util layer** — `third_party/yt/lib/src/util/{util.dart,credentials_path.dart,logging_interceptors.dart,authorization_exception.dart,extras.dart}` → `packages/google_texttospeech/lib/src/util/`. Apply substitution table. Then trim `util.dart` per "Not ported" note (drop responseMaxResults/maxResults/getUploadIdFromUrl/base64GCloud*/unixTimeStamp/cast/TextFormat). Fix in `logging_interceptors.dart` doc comment: "YouTube API responses" → "Text-to-Speech API responses"; note `audioContent` base64 can legitimately be large — keep the 50 MiB default.

- [ ] **Step 4: Copy+substitute oauth layer** — `third_party/yt/lib/oauth.dart` → `lib/oauth.dart`; `third_party/yt/lib/src/oauth/*` (5 files) → `lib/src/oauth/`; `third_party/yt/lib/src/model/util/{google_oauth_credentials,oauth_credentials,token}.dart` → `lib/src/model/util/` (copy their `.g.dart` too). Substitute table + scope row. In `oauth_access_control_io.dart` also replace `'yt_cli'` mentions per table. In `oauth_access_control_web.dart` message: `GoogleTts.withApiKey()`.

- [ ] **Step 5: Verify**

Run: `melos bootstrap` (root) — Expected: resolves both workspace packages once Task 5 pubspec exists; for now create the CLI pubspec placeholder OR expect "google_texttospeech_cli missing" error. Defer to Task 5's verify. Instead check copy completeness: `ls lib/src/util lib/src/oauth lib/src/model/util` matches file list.

- [ ] **Step 6: Commit** `git add packages/google_texttospeech && git commit -m "feat(core): port util + oauth layer from reference"`

---

### Task 3: Models (new code — full content)

**Files:**
- Create in `packages/google_texttospeech/lib/src/model/`: `audio_encoding.dart`, `ssml_voice_gender.dart`, `synthesis_input.dart`, `voice_selection_params.dart`, `audio_config.dart`, `voice.dart`, `list_voices_response.dart`, `synthesize_speech_request.dart`, `synthesize_speech_response.dart`

Style: reference model pattern (`@JsonSerializable()`, nullable fields, `fromJson`/`toJson`, `toString() => jsonEncode(toJson())`). Enums are Dart enums with `@JsonValue` wire names plus a `static <Enum>? fallback => <Enum>.unknown;` member (json_serializable ≥6.9 `unknownValue` hook) so unrecognized server values decode to `unknown` instead of throwing.

- [ ] **Step 1: `audio_encoding.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

/// The encoding of the audio stream in the response.
enum AudioEncoding {
  /// Output in the Linear16 format.
  @JsonValue('LINEAR16')
  linear16,

  /// Output in the MP3 format.
  @JsonValue('MP3')
  mp3,

  /// Output in the Ogg Opus format.
  @JsonValue('OGG_OPUS')
  oggOpus,

  /// Decoded value for any encoding string this client version does not
  /// know (via json_serializable `fallback`).
  unknown;

  static AudioEncoding? fallback => AudioEncoding.unknown;
}
```

- [ ] **Step 2: `ssml_voice_gender.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

/// Gender of the voice for SSML input.
enum SsmlVoiceGender {
  /// Voice that supports SSML is unspecified.
  @JsonValue('SSML_GENDER_UNSPECIFIED')
  unspecified,

  /// Voice that supports SSML is male.
  @JsonValue('MALE')
  male,

  /// Voice that supports SSML is female.
  @JsonValue('FEMALE')
  female,

  /// Voice that supports SSML is neutral.
  @JsonValue('NEUTRAL')
  neutral,

  /// Decoded value for any gender string this client version does not know
  /// (via json_serializable `fallback`). Never send this in a request.
  unknown;

  static SsmlVoiceGender? fallback => SsmlVoiceGender.unknown;
}
```

- [ ] **Step 3: `synthesis_input.dart`** — oneof text/ssml enforced at construction:

```dart
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'synthesis_input.g.dart';

/// Text or SSML input to be synthesized. Exactly one of [text] or [ssml]
/// must be provided.
@JsonSerializable()
class SynthesisInput {
  /// The text to synthesize.
  final String? text;

  /// The SSML document to synthesize.
  final String? ssml;

  SynthesisInput({this.text, this.ssml})
      : assert(
          (text == null) != (ssml == null),
          'Exactly one of text or ssml must be provided.',
        );

  factory SynthesisInput.fromJson(Map<String, dynamic> json) =>
      _$SynthesisInputFromJson(json);

  Map<String, dynamic> toJson() => _$SynthesisInputToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
```

- [ ] **Step 4: `voice_selection_params.dart`**

```dart
import 'dart:convert';

import 'package:google_texttospeech/src/model/ssml_voice_gender.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_selection_params.g.dart';

/// Description of the voice requested for synthesis.
@JsonSerializable()
class VoiceSelectionParams {
  /// Required. IETF BCP 47 language tag of the desired voice, e.g. `en-US`.
  final String languageCode;

  /// Optional name of the voice, e.g. `en-US-Wavenet-D`.
  final String? name;

  /// Optional preferred gender for the voice.
  final SsmlVoiceGender? ssmlGender;

  const VoiceSelectionParams({
    required this.languageCode,
    this.name,
    this.ssmlGender,
  });

  factory VoiceSelectionParams.fromJson(Map<String, dynamic> json) =>
      _$VoiceSelectionParamsFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSelectionParamsToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
```

- [ ] **Step 5: `audio_config.dart`**

```dart
import 'dart:convert';

import 'package:google_texttospeech/src/model/audio_encoding.dart';
import 'package:json_annotation/json_annotation.dart';

part 'audio_config.g.dart';

/// Configuration for the synthesized audio.
@JsonSerializable()
class AudioConfig {
  /// Required. Encoding of the returned audio.
  final AudioEncoding audioEncoding;

  /// Speaking rate: 0.25 to 4.0. Values > 1.0 raise pitch.
  final double? speakingRate;

  /// Additional pitch (in semitones) applied: -20.0 to 20.0.
  final double? pitch;

  /// Sample rate in Hertz of the returned audio.
  final int? sampleRateHertz;

  /// Volume gain (in dB) applied: -40.0 to 40.0.
  @JsonKey(name: 'volumeGainDb')
  final double? volumeGainDb;

  /// An effect profile of the selected voice, e.g. `HEADPHONE_CLASS`.
  final List<String>? effectsProfile;

  const AudioConfig({
    required this.audioEncoding,
    this.speakingRate,
    this.pitch,
    this.sampleRateHertz,
    this.volumeGainDb,
    this.effectsProfile,
  });

  factory AudioConfig.fromJson(Map<String, dynamic> json) =>
      _$AudioConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AudioConfigToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
```

- [ ] **Step 6: `voice.dart`**

```dart
import 'dart:convert';

import 'package:google_texttospeech/src/model/ssml_voice_gender.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice.g.dart';

/// A Google Cloud Text-to-Speech voice.
@JsonSerializable()
class Voice {
  /// The unique URI-encoded identifier of the voice, e.g. `en-US-Wavenet-D`.
  final String? name;

  /// IETF BCP 47 language codes this voice supports.
  final List<String>? languageCodes;

  /// The gender of this voice (relevant only for SSML input).
  final SsmlVoiceGender? ssmlGender;

  /// The natural sample rate in Hertz of audio synthesized by this voice.
  final double? naturalSampleRateHertz;

  const Voice({
    this.name,
    this.languageCodes,
    this.ssmlGender,
    this.naturalSampleRateHertz,
  });

  factory Voice.fromJson(Map<String, dynamic> json) => _$VoiceFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
```

- [ ] **Step 7: `list_voices_response.dart`**

```dart
import 'dart:convert';

import 'package:google_texttospeech/src/model/voice.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_voices_response.g.dart';

/// The message returned for a `voices.list` request.
@JsonSerializable()
class ListVoicesResponse {
  /// The list of voices.
  final List<Voice>? voices;

  /// Identifier for the next page, or empty if this is the last page.
  final String? nextPageToken;

  const ListVoicesResponse({this.voices, this.nextPageToken});

  factory ListVoicesResponse.fromJson(Map<String, dynamic> json) =>
      _$ListVoicesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListVoicesResponseToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
```

- [ ] **Step 8: `synthesize_speech_request.dart`**

```dart
import 'dart:convert';

import 'package:google_texttospeech/src/model/audio_config.dart';
import 'package:google_texttospeech/src/model/synthesis_input.dart';
import 'package:google_texttospeech/src/model/voice_selection_params.dart';
import 'package:json_annotation/json_annotation.dart';

part 'synthesize_speech_request.g.dart';

/// The top-level message sent by the client for the `text.synthesize` method.
@JsonSerializable()
class SynthesizeSpeechRequest {
  /// Required. The SynthesisInput.
  final SynthesisInput input;

  /// Required. The VoiceSelectionParams.
  @JsonKey(name: 'voice')
  final VoiceSelectionParams voice;

  /// Required. The AudioConfig.
  final AudioConfig audioConfig;

  const SynthesizeSpeechRequest({
    required this.input,
    required this.voice,
    required this.audioConfig,
  });

  factory SynthesizeSpeechRequest.fromJson(Map<String, dynamic> json) =>
      _$SynthesizeSpeechRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SynthesizeSpeechRequestToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
```

- [ ] **Step 9: `synthesize_speech_response.dart`**

```dart
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'synthesize_speech_response.g.dart';

/// The message returned to the client by the `text.synthesize` method.
@JsonSerializable()
class SynthesizeSpeechResponse {
  /// The base64-encoded audio data.
  final String? audioContent;

  const SynthesizeSpeechResponse({this.audioContent});

  factory SynthesizeSpeechResponse.fromJson(Map<String, dynamic> json) =>
      _$SynthesizeSpeechResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SynthesizeSpeechResponseToJson(this);

  /// Convenience: decoded audio bytes, or null when [audioContent] is absent.
  Uint8List? get audioBytes =>
      audioContent == null ? null : base64Decode(audioContent!);

  @override
  String toString() => jsonEncode(toJson());
}
```

Requires `import 'dart:typed_data';` (add with the other imports).

- [ ] **Step 10:** `.g.dart` files are NOT hand-written — generated in Task 5 `melos run build`. Commit skeletons: `git add packages/google_texttospeech/lib/src/model && git commit -m "feat(core): v1 models"`

---

### Task 4: Retrofit providers + services + base + barrel (new code — full content)

**Files:**
- Create: `lib/src/provider/{voices.dart,synthesize.dart}`, `lib/src/{text_to_speech_api_helper.dart,voices.dart,synthesize.dart,google_tts_base.dart}`, `lib/google_texttospeech.dart`, `lib/meta.dart` (via melos meta)

- [ ] **Step 1: `lib/src/text_to_speech_api_helper.dart`** — copy `third_party/yt/lib/src/youtube_api_helper.dart`, apply substitutions, and delete `buildParts` (no `part` concept in TTS):

```dart
import 'package:dio/dio.dart';

abstract class TextToSpeechApiHelper {
  final String? token;
  final String? apiKey;
  final Dio dio;

  final accept = 'application/json';

  final contentType = 'application/json';

  TextToSpeechApiHelper({required this.dio, this.token, this.apiKey});
}
```

- [ ] **Step 2: `lib/src/provider/voices.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:retrofit/retrofit.dart';

part 'voices.g.dart';

/// REST client for the texttospeech.googleapis.com v1 `voices` resource.
@RestApi(baseUrl: 'https://texttospeech.googleapis.com/v1')
abstract class VoicesClient {
  factory VoicesClient(Dio dio, {String baseUrl}) = _VoicesClient;

  /// Returns the list of voices that is available from the
  /// Text-to-Speech API.
  @GET('/voices')
  Future<ListVoicesResponse> list(
    @Query('key') String? apiKey,
    @Header('Accept') String accept, {
    @Query('pageSize') int? pageSize,
    @Query('pageToken') String? pageToken,
  });
}
```

- [ ] **Step 3: `lib/src/provider/synthesize.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:retrofit/http.dart';
import 'package:retrofit/retrofit.dart';

part 'synthesize.g.dart';

/// REST client for the texttospeech.googleapis.com v1 `text` resource.
@RestApi(baseUrl: 'https://texttospeech.googleapis.com/v1')
abstract class SynthesizeClient {
  factory SynthesizeClient(Dio dio, {String baseUrl}) = _SynthesizeClient;

  /// Synthesizes the requested text and returns the generated audio data
  /// in a [SynthesizeSpeechResponse].
  @POST('/text:synthesize')
  Future<SynthesizeSpeechResponse> synthesize(
    @Query('key') String? apiKey,
    @Header('Accept') String accept,
    @Header('Content-Type') String contentType,
    @Body() SynthesizeSpeechRequest body,
  );
}
```

- [ ] **Step 4: `lib/src/voices.dart`**

```dart
import 'package:google_texttospeech/src/provider/voices.dart';
import 'package:google_texttospeech/src/text_to_speech_api_helper.dart';
import 'package:google_texttospeech/google_texttospeech.dart';

/// The `voices` resource: list voices available from the Text-to-Speech API.
class Voices extends TextToSpeechApiHelper {
  final VoicesClient _rest;

  Voices({required super.dio, super.apiKey}) : _rest = VoicesClient(dio);

  /// Returns a list of [Voice] definitions available to the application
  /// project. Set [pageSize] and [pageToken] for pagination.
  Future<ListVoicesResponse> list({
    int? pageSize,
    String? pageToken,
  }) async {
    return _rest.list(
      apiKey,
      accept,
      pageSize: pageSize,
      pageToken: pageToken,
    );
  }
}
```

- [ ] **Step 5: `lib/src/synthesize.dart`**

```dart
import 'package:google_texttospeech/src/provider/synthesize.dart';
import 'package:google_texttospeech/src/text_to_speech_api_helper.dart';
import 'package:google_texttospeech/google_texttospeech.dart';

/// The `text` resource: synthesize speech from [SynthesisInput].
class Synthesize extends TextToSpeechApiHelper {
  final SynthesizeClient _rest;

  Synthesize({required super.dio, super.apiKey}) : _rest = SynthesizeClient(dio);

  /// Synthesizes the given [input] with the given [voice] selection rendered
  /// according to [audioConfig]. Returns a [SynthesizeSpeechResponse] whose
  /// `audioContent` is base64-encoded audio.
  Future<SynthesizeSpeechResponse> synthesize({
    required SynthesisInput input,
    required VoiceSelectionParams voice,
    required AudioConfig audioConfig,
  }) async {
    return _rest.synthesize(
      apiKey,
      accept,
      contentType,
      SynthesizeSpeechRequest(
        input: input,
        voice: voice,
        audioConfig: audioConfig,
      ),
    );
  }
}
```

- [ ] **Step 6: `lib/src/google_tts_base.dart`** — copy `third_party/yt/lib/src/yt_base.dart`, apply substitution table, then: single `Voices? _voices` / `Synthesize? _synthesize` pair of nullable fields + getters (`Voices get voices => _voices!;` etc.), both always constructed in `setModules` (drop `useTokenAuth` branching AND `_moduleUnavailableMessage` — both v1 methods work with an API key). Keep static dio, `_resetSharedState`, `addInterceptor`, `withApiKey` (uses `Util.envTtsApiKey`), `withOAuth`, `withGenerator`, `close`.

Resulting class skeleton (fill copy-adapted bodies verbatim):

```dart
class GoogleTts with UiLoggy {
  static final dio = Dio();
  static final _interceptors = <Interceptor>[];
  static RefreshTokenGenerator? refreshTokenGenerator;

  Voices? _voices;
  Synthesize? _synthesize;

  Voices get voices => _voices!;
  Synthesize get synthesize => _synthesize!;

  GoogleTts({LogOptions logOptions = ..., LoggyPrinter printer = ...}) { ... }
  static GoogleTts withApiKey({String? apiKey, Map<String, String>? additionalHeaders}) { ... }
  static GoogleTts withOAuth({oauth2.Client? oauthClient, LogOptions logOptions = ...}) { ... }
  static Future<GoogleTts> withGenerator(RefreshTokenGenerator generator, {LogOptions logOptions = ...}) async { ... }
  static void _resetSharedState() { ... }
  static void addInterceptor(Interceptor interceptor, {ListPosition position = ListPosition.start}) { ... }
  void setModules({bool? useTokenAuth, String? apiKey}) {
    _voices = Voices(apiKey: apiKey, dio: dio);
    _synthesize = Synthesize(apiKey: apiKey, dio: dio);
  }
  void close() => dio.close();
}
```

- [ ] **Step 7: `lib/google_texttospeech.dart` barrel** — export exactly:

```dart
/// Native Dart interface to the Google Cloud Text-to-Speech REST API v1.
///
/// Covers the v1 `voices.list` and `text:synthesize` methods of
/// https://cloud.google.com/text-to-speech/docs/reference/rest/v1.
library;

export 'src/google_tts_base.dart';
export 'src/synthesize.dart';
export 'src/voices.dart';

export 'src/model/audio_config.dart';
export 'src/model/audio_encoding.dart';
export 'src/model/list_voices_response.dart';
export 'src/model/ssml_voice_gender.dart';
export 'src/model/synthesize_speech_request.dart';
export 'src/model/synthesize_speech_response.dart';
export 'src/model/synthesis_input.dart';
export 'src/model/voice.dart';
export 'src/model/voice_selection_params.dart';

export 'src/model/util/google_oauth_credentials.dart';
export 'src/model/util/oauth_credentials.dart';
export 'src/model/util/token.dart';

export 'src/oauth/refresh_token_generator.dart';

export 'src/util/authorization_exception.dart';
export 'src/util/credentials_path.dart';
export 'src/util/extras.dart';
export 'src/util/logging_interceptors.dart';
export 'src/util/util.dart';
```

- [ ] **Step 8: meta** — run `melos run meta` (generates `lib/meta.dart` in both packages once CLI exists; skip now if it errors for the missing CLI package, re-run after Task 6 Step 1).

- [ ] **Step 9: Commit** `git commit -am "feat(core): services, retrofit providers, base client, barrel"`

---

### Task 5: Bootstrap + codegen + first green build

- [ ] **Step 1:** Root `dart pub get` then `melos bootstrap` — Expected: success once both package pubspecs exist (create CLI pubspec in Task 6 Step 1 if bootstrapping strictly needs it; order may swap 5/6 — bootstrap FIRST after Task 2 creates the core pubspec, using a temporary minimal CLI pubspec from Task 6).
- [ ] **Step 2:** `melos run build` — Expected: retrofit_generator + json_serializable emit all `*.g.dart`, 0 errors.
- [ ] **Step 3:** `dart analyze --fatal-infos` in core — Expected: No issues found. Fix any (imports, word-substitution leftovers).
- [ ] **Step 4:** `melos run format`
- [ ] **Step 5:** Commit `git commit -am "chore(core): codegen green"`

---

### Task 6: CLI package

**Files:**
- Create: `packages/google_texttospeech_cli/{pubspec.yaml,bin/tts.dart,lib/google_texttospeech_cli.dart,lib/src/cmd/{tts_helper_command.dart,tts_version_command.dart,voices_command.dart,synthesize_command.dart,tts_authorize_command.dart},lib/src/util/security_util.dart,authentication.md,README stub}`

- [ ] **Step 1: `pubspec.yaml`**

```yaml
name: google_texttospeech_cli
version: 0.1.0
description: A CLI tool for the Google Cloud Text-to-Speech REST API.
homepage: https://github.com/cdavis-code/google_texttospeach_workspace
repository: https://github.com/cdavis-code/google_texttospeach_workspace/tree/main/packages/google_texttospeech_cli
issue_tracker: https://github.com/cdavis-code/google_texttospeach_workspace/issues

topics:
  - cli
  - text-to-speech
  - google
  - api
  - oauth2

resolution: workspace

environment:
  sdk: ^3.8.0

executables:
  tts: tts

dependencies:
  google_texttospeech: ^0.1.0
  args: ^2.7.0
  dio: ^5.9.2
  loggy: ^2.0.3
  oauth2: ^2.0.5
  universal_io: ^2.3.1

dev_dependencies:
  lints: ^6.1.0
```

- [ ] **Step 2: Port `security_util.dart` + `tts_authorize_command.dart`** from `third_party/yt_cli/lib/src/util/security_util.dart` and `.../youtube_authorize_command.dart`. Substitution table +: guide URL → this repo's `packages/google_texttospeech_cli/authentication.md`; `YoutubeAuthorizeCommand` → `TtsAuthorizeCommand`; class doc "YouTube API requests" → "Text-to-Speech API requests".

- [ ] **Step 3: `lib/src/cmd/tts_helper_command.dart`** — port `youtube_helper_command.dart`: field `late final GoogleTts _tts;`, getters `voices`/`synthesize`, `initializeTts()` reads `client_secret.json` + `tts_access_tokens.json` via `CredentialsPath.clientSecretsFile/accessTokensFile` (same logic), message `Run "tts authorize"`, constructs `GoogleTts.withOAuth(...)`; add key-first path:

```dart
  Future<void> initializeTts() async {
    // Prefer GOOGLE_TTS_API_KEY (env or .env) when present; otherwise fall
    // back to stored OAuth credentials, like the reference yt_cli but
    // reversed order to favor the key-only TTS use case.
    final apiKey = CredentialsPath.resolveValue(Util.envTtsApiKey);
    if (apiKey != null && apiKey.isNotEmpty) {
      _tts = GoogleTts.withApiKey(
        apiKey: apiKey,
        additionalHeaders: null,
      );
      Loggy.initLoggy(
        logOptions: Util.convertToLogOptions(globalResults!['log-level']),
      );
      return;
    }
    ... (port of reference OAuth client_secrets flow with names substituted)
  }
```

Note: `GoogleTts.withApiKey` already calls `Loggy.initLoggy` with default options in its ctor; to honor `--log-level` under key auth, construct then re-init Loggy with `Util.convertToLogOptions(globalResults!['log-level'])` as shown. Keep `close()`.

- [ ] **Step 4: `lib/src/cmd/voices_command.dart`** — command group + list subcommand:

```dart
import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:google_texttospeech/google_texttospeech.dart';

import 'tts_helper_command.dart';

/// Command group for the voices resource.
class TtsVoicesCommand extends Command<void> {
  @override
  String get description =>
      'Voice names and synthesis metadata for the Text-to-Speech API.';

  @override
  String get name => 'voices';

  TtsVoicesCommand() {
    addSubcommand(TtsListVoicesCommand());
  }
}

/// Returns the list of voices available from the Text-to-Speech API.
class TtsListVoicesCommand extends TtsHelperCommand {
  @override
  String get description =>
      'Returns the list of voices available from the Text-to-Speech API.';

  @override
  String get name => 'list';

  TtsListVoicesCommand() {
    argParser
      ..addOption(
        'page-size',
        valueHelp: 'count',
        help: 'The maximum number of results returned in the response.',
      )
      ..addOption(
        'page-token',
        valueHelp: 'token',
        help: 'The next-page token returned from a previous list request.',
      );
  }

  @override
  void run() async {
    await initializeTts();

    try {
      final response = await voices.list(
        pageSize: argResults?['page-size'] == null
            ? null
            : int.parse(argResults!['page-size'] as String),
        pageToken: argResults?['page-token'],
      );

      print(response);

      close();
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}
```

(`err.usage` — add `import '../util/...'`? No: `usage` lives in core `util/extras.dart`, already exported by the package barrel.)

- [ ] **Step 5: `lib/src/cmd/synthesize_command.dart`**

```dart
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:universal_io/io.dart';

import 'tts_helper_command.dart';

/// Command group for the text synthesis resource.
class TtsSynthesizeCommand extends Command<void> {
  @override
  String get description => 'Synthesizes speech from the input text.';

  @override
  String get name => 'synthesize';

  TtsSynthesizeCommand() {
    addSubcommand(TtsRunSynthesizeCommand());
  }
}

/// Synthesizes the given text and writes the audio to a file.
class TtsRunSynthesizeCommand extends TtsHelperCommand {
  @override
  String get description =>
      'Synthesizes the given text and writes the audio to a file.';

  @override
  String get name => 'synthesize';

  TtsRunSynthesizeCommand() {
    argParser
      ..addOption('text', help: 'Plain text to synthesize (exclusive with --ssml).')
      ..addOption('ssml', help: 'SSML document to synthesize (exclusive with --text).')
      ..addOption('language-code', valueHelp: 'tag', defaultsTo: 'en-US',
          help: 'BCP 47 language tag of the desired voice.')
      ..addOption('name', valueHelp: 'voice',
          help: 'Name of the voice, e.g. en-US-Wavenet-D.')
      ..addOption('gender', allowed: ['unspecified', 'male', 'female', 'neutral'],
          help: 'Preferred voice gender.')
      ..addOption('encoding', allowed: ['linear16', 'mp3', 'ogg-opus'],
          defaultsTo: 'mp3', help: 'Audio encoding of the output.')
      ..addOption('speaking-rate', valueHelp: 'rate')
      ..addOption('pitch', valueHelp: 'semitones')
      ..addOption('sample-rate', valueHelp: 'hz')
      ..addOption('volume-gain', valueHelp: 'db')
      ..addMultiOption('effects-profile', valueHelp: 'profile')
      ..addOption('out', valueHelp: 'path',
          help: 'Output file. Default out.<ext>. Use "-" for base64 on stdout.');
  }

  @override
  void run() async {
    final text = argResults?['text'] as String?;
    final ssml = argResults?['ssml'] as String?;

    if ((text == null) == (ssml == null)) {
      throw UsageException('Provide exactly one of --text or --ssml.', usage);
    }

    await initializeTts();

    try {
      final response = await synthesize.synthesize(
        input: text != null
            ? SynthesisInput(text: text)
            : SynthesisInput(ssml: ssml),
        voice: VoiceSelectionParams(
          languageCode: argResults!['language-code'] as String,
          name: argResults?['name'],
          ssmlGender: switch (argResults?['gender']) {
            'male' => SsmlVoiceGender.male,
            'female' => SsmlVoiceGender.female,
            'neutral' => SsmlVoiceGender.neutral,
            'unspecified' => SsmlVoiceGender.unspecified,
            _ => null,
          },
        ),
        audioConfig: AudioConfig(
          audioEncoding: switch (argResults!['encoding']) {
            'linear16' => AudioEncoding.linear16,
            'ogg-opus' => AudioEncoding.oggOpus,
            _ => AudioEncoding.mp3,
          },
          speakingRate: argResults?['speaking-rate'] == null
              ? null
              : double.parse(argResults!['speaking-rate'] as String),
          pitch: argResults?['pitch'] == null
              ? null
              : double.parse(argResults!['pitch'] as String),
          sampleRateHertz: argResults?['sample-rate'] == null
              ? null
              : int.parse(argResults!['sample-rate'] as String),
          volumeGainDb: argResults?['volume-gain'] == null
              ? null
              : double.parse(argResults!['volume-gain'] as String),
          effectsProfile:
              (argResults!['effects-profile'] as List<String>).isEmpty
              ? null
              : argResults!['effects-profile'] as List<String>,
        ),
      );

      final audio = response.audioBytes;
      if (audio == null) {
        throw UsageException('API returned no audio content.', usage);
      }

      if (argResults?['out'] == '-') {
        stdout.add(base64Encode(audio).codeUnits);
      } else {
        final ext = switch (argResults!['encoding']) {
          'linear16' => 'wav',
          'ogg-opus' => 'ogg',
          _ => 'mp3',
        };
        final path = (argResults?['out'] ?? 'out.$ext') as String;
        File(path).writeAsBytesSync(audio);
        print('Wrote ${audio.length} bytes to $path');
      }

      close();
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}
```

- [ ] **Step 6: port `tts_version_command.dart`** (copy `youtube_version_command.dart` → `TtsVersionCommand`, import `package:google_texttospeech_cli/meta.dart`).

- [ ] **Step 7: `lib/google_texttospeech_cli.dart` barrel**

```dart
/// CLI commands for the google_texttospeech package.
library;

export 'src/cmd/tts_authorize_command.dart';
export 'src/cmd/tts_helper_command.dart';
export 'src/cmd/tts_version_command.dart';
export 'src/cmd/synthesize_command.dart';
export 'src/cmd/voices_command.dart';
```

- [ ] **Step 8: `bin/tts.dart`**

```dart
import 'package:args/command_runner.dart';
import 'package:universal_io/io.dart';
import 'package:google_texttospeech_cli/google_texttospeech_cli.dart';

void main(List<String> arguments) async {
  CommandRunner<void>(
      'tts',
      'A command line interface for the Google Cloud Text-to-Speech API',
    )
    ..argParser.addOption(
      'log-level',
      allowed: ['all', 'debug', 'info', 'warning', 'error', 'off'],
      defaultsTo: 'off',
    )
    ..addCommand(TtsAuthorizeCommand())
    ..addCommand(TtsSynthesizeCommand())
    ..addCommand(TtsVersionCommand())
    ..addCommand(TtsVoicesCommand())
    ..run(arguments).catchError((Object error) {
      if (error is! UsageException) throw error;

      print(error);

      exit(64); // Exit code 64 indicates a usage error.
    });
}
```

- [ ] **Step 9: Verify + commit** — `melos bootstrap && melos run build && melos run analyze && melos run format`; expect 0 issues. `git commit -am "feat(cli): tts command runner + commands"`

---

### Task 7: Docs, example, test

**Files:**
- Create: `packages/google_texttospeech/example/example.dart` (port `third_party/yt/example/example.dart`, rewrite the demo calls to `GoogleTts.withApiKey()` + `voices.list` + one `synthesize` writing `helloworld.mp3`), `packages/google_texttospeech/test/models_test.dart`, `AGENTS.md` (port structure of reference AGENTS.md: overview table for 2 packages, commands, conventions — no homebrew/npm sections), package `README.md`s (port headline sections; CLI `authentication.md` rewrite YouTube→TTS setup: OAuth client of type Android/Desktop, enable Text-to-Speech API), root `README.md` with packages table.

- [ ] **Step 1: Write `test/models_test.dart`** (the one runnable check for the non-trivial JSON/enum/oneof logic):

```dart
import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:test/test.dart';

void main() {
  test('request json round trip uses API enum values', () {
    const request = SynthesizeSpeechRequest(
      input: SynthesisInput(text: 'hello'),
      voice: VoiceSelectionParams(
        languageCode: 'en-US',
        name: 'en-US-Wavenet-D',
        ssmlGender: SsmlVoiceGender.male,
      ),
      audioConfig: AudioConfig(
        audioEncoding: AudioEncoding.oggOpus,
        speakingRate: 1.2,
      ),
    );

    final json = request.toJson();
    expect(json['voice']['ssmlGender'], 'MALE');
    expect(json['audioConfig']['audioEncoding'], 'OGG_OPUS');

    final decoded = SynthesizeSpeechRequest.fromJson(json);
    expect(decoded.audioConfig.audioEncoding, AudioEncoding.oggOpus);
    expect(decoded.voice.ssmlGender, SsmlVoiceGender.male);
  });

  test('voice response decodes', () {
    final response = ListVoicesResponse.fromJson({
      'voices': [
        {
          'name': 'en-US-Wavenet-A',
          'languageCodes': ['en-US'],
          'ssmlGender': 'FEMALE',
          'naturalSampleRateHertz': 24000.0,
        },
      ],
    });
    expect(response.voices!.single.ssmlGender, SsmlVoiceGender.female);
  });

  test('unknown gender maps to unknown', () {
    expect(
      Voice.fromJson({'ssmlGender': 'ROBOT'}).ssmlGender,
      SsmlVoiceGender.unknown,
    );
  });

  test('SynthesisInput enforces oneof', () {
    expect(() => SynthesisInput(), throwsA(isA<AssertionError>()));
    expect(
      () => SynthesisInput(text: 'a', ssml: '<speak>a</speak>'),
      throwsA(isA<AssertionError>()),
    );
  });
}
```

The `unknown gender maps to unknown` test passes because of the `static SsmlVoiceGender? fallback` members defined on the enums in Task 3 (json_serializable uses a `static fallback` getter as its `unknownValue` hook), so arbitrary server-side values decode to `unknown` instead of throwing.

- [ ] **Step 2: Run `melos run test`** — Expected: all green (asserts run in VM test mode; json_serializable `.g.dart` present from Task 5).
- [ ] **Step 3: Write example + docs files listed above.**
- [ ] **Step 4: Commit** `git commit -am "test+docs: model test, example, AGENTS/README/authentication"`

---

### Task 8: CI + final verification

- [ ] **Step 1:** `.github/workflows/dart.yml` — slim version: on push/PR main, `dart-sdk: stable`, steps: checkout, `dart pub get`, `melos bootstrap`, `melos run build`, `melos run analyze`, `melos run format-check`, `melos run test`.
- [ ] **Step 2:** `melos run lint:all && melos run test` → all green.
- [ ] **Step 3:** Manual smoke (only if `GOOGLE_TTS_API_KEY` set): `dart run google_texttospeech_cli:tts voices list --page-size 3` prints JSON; `tts synthesize --text "hello world" --out /tmp/hello.mp3` writes a playable file. Skip silently with a note if no key available.
- [ ] **Step 4:** Final commit; ensure `melos_yt_workspace.iml`-style IDE files NOT committed (reference has them; skip, YAGNI).

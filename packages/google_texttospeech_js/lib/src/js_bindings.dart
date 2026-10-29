/// JS-interop bindings that expose a minimal `google_texttospeech` surface to
/// JavaScript.
///
/// `install()` puts a `GoogleTtsJs` namespace on `globalThis`; `withApiKey` /
/// `withOAuth` return an opaque handle whose methods the TypeScript layer
/// (`src/index.ts`) wraps into a typed, Promise-based API. JSON <-> JS values
/// round-trip through `JSON.parse`/`stringify` for fidelity, exactly as the
/// reference `yt_js` bindings do.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:loggy/loggy.dart';

@JS('globalThis')
external JSObject get _globalThis;

/// Installs the interop namespace on `globalThis.GoogleTtsJs`.
/// Called once from the dart2js `main()`.
void install() {
  final ns = JSObject();
  ns.setProperty('withApiKey'.toJS, _withApiKey.toJS);
  ns.setProperty('withOAuth'.toJS, _withOAuth.toJS);
  ns.setProperty('version'.toJS, '0.1.0'.toJS);
  _globalThis.setProperty('GoogleTtsJs'.toJS, ns);
}

/// Creates a client with an API key.
///
/// JS: `GoogleTtsJs.withApiKey(apiKey, logLevel?) -> Promise<Handle>`.
JSPromise<JSObject> _withApiKey(JSString apiKey, JSString? logLevel) {
  final future = () async {
    Loggy.initLoggy(
      logPrinter: const PrettyPrinter(showColors: false),
      logOptions: _parseLogLevel(logLevel?.toDart),
    );
    final tts = GoogleTts.withApiKey(apiKey: apiKey.toDart);
    return _wrap(tts);
  }();
  return future.toJS;
}

/// Creates a client with OAuth. Unsupported in the browser (no loopback /
/// filesystem); mirrors `yt_js` parity and rejects on use.
///
/// JS: `GoogleTtsJs.withOAuth(logLevel?) -> Promise<Handle>`.
JSPromise<JSObject> _withOAuth(JSString? logLevel) {
  final future = () async {
    final logOpts = _parseLogLevel(logLevel?.toDart);
    Loggy.initLoggy(
      logPrinter: const PrettyPrinter(showColors: false),
      logOptions: logOpts,
    );
    final tts = GoogleTts.withOAuth(logOptions: logOpts);
    return _wrap(tts);
  }();
  return future.toJS;
}

LogOptions _parseLogLevel(String? level) {
  switch (level) {
    case 'all':
      return const LogOptions(LogLevel.all);
    case 'debug':
      return const LogOptions(LogLevel.debug);
    case 'info':
      return const LogOptions(LogLevel.info);
    case 'warning':
      return const LogOptions(LogLevel.warning);
    case 'error':
      return const LogOptions(LogLevel.error);
    default:
      return const LogOptions(LogLevel.error, stackTraceLevel: LogLevel.off);
  }
}

/// Wraps a [GoogleTts] instance in an opaque JS object exposing only the
/// methods the TypeScript layer needs.
JSObject _wrap(GoogleTts tts) {
  final handle = JSObject();

  // voices.list -> ListVoicesResponse JSON.
  handle.setProperty(
    'voicesList'.toJS,
    ((JSString? languageCode) {
      final future = () async {
        final response = await tts.voices.list(
          languageCode: languageCode?.toDart,
        );
        return _dartToJs(response.toJson()) ?? JSObject();
      }();
      return future.toJS;
    }).toJS,
  );

  // text.synthesize. Body mirrors the SynthesizeSpeechRequest wire shape
  // (input.text|ssml|prompt, voice.languageCode|name|modelName, audioConfig).
  handle.setProperty(
    'synthesize'.toJS,
    ((JSAny body) {
      final future = () async {
        final request = SynthesizeSpeechRequest.fromJson(_jsToDartMap(body));
        final response = await tts.synthesize.synthesize(
          input: request.input,
          voice: request.voice,
          audioConfig: request.audioConfig,
        );
        return _dartToJs(response.toJson()) ?? JSObject();
      }();
      return future.toJS;
    }).toJS,
  );

  handle.setProperty(
    'close'.toJS,
    (() {
      tts.close();
      return JSObject();
    }).toJS,
  );

  return handle;
}

// -------------------------------------------------------------------------
// JSON <-> JS value conversion (round-trip via JSON for fidelity)
// -------------------------------------------------------------------------

JSObject get _json => _globalThis.getProperty<JSObject>('JSON'.toJS);

/// Converts a plain Dart value (from `dart:convert` JSON) to a JS value.
JSAny? _dartToJs(Object? value) {
  if (value == null) return null;
  final encoded = jsonEncode(value);
  return _json.callMethod<JSAny?>('parse'.toJS, encoded.toJS);
}

/// Converts a JS value to a Dart `Map<String, dynamic>` via JSON round-trip.
Map<String, dynamic> _jsToDartMap(JSAny body) {
  final encoded = _json.callMethod<JSString>('stringify'.toJS, body);
  return jsonDecode(encoded.toDart) as Map<String, dynamic>;
}

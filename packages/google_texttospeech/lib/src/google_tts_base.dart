import 'package:dio/dio.dart';
import 'package:loggy/loggy.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:google_texttospeech/oauth.dart';

class GoogleTts with UiLoggy {
  static final dio = Dio();
  static final tokenExpiry = DateTime(2000, 0, 0);
  static final _interceptors = <Interceptor>[];

  static RefreshTokenGenerator? refreshTokenGenerator;

  Voices? _voices;
  Synthesize? _synthesize;

  /// The `voices` resource: list the voices available from the
  /// Text-to-Speech API.
  Voices get voices => _voices!;

  /// The `text` resource: synthesize speech from text or SSML input.
  Synthesize get synthesize => _synthesize!;

  GoogleTts({
    LogOptions logOptions = const LogOptions(
      LogLevel.error,
      stackTraceLevel: LogLevel.off,
    ),
    LoggyPrinter printer = const PrettyPrinter(showColors: false),
  }) {
    Loggy.initLoggy(logPrinter: printer, logOptions: logOptions);

    addInterceptor(LoggingInterceptors(), position: ListPosition.end);
  }

  static GoogleTts withApiKey({
    String? apiKey,
    Map<String, String>? additionalHeaders,
  }) {
    final resolvedKey =
        apiKey ?? CredentialsPath.resolveValue(Util.envTtsApiKey);

    if (resolvedKey == null || resolvedKey.isEmpty) {
      throw ArgumentError(
        'No API key provided. Pass it directly or set the '
        '${Util.envTtsApiKey} environment variable (or add it to a .env file).',
      );
    }

    _resetSharedState();

    final googleTts = GoogleTts();

    googleTts.setModules(apiKey: resolvedKey);

    if (additionalHeaders != null) {
      dio.options.headers.addAll(additionalHeaders);
    }

    dio.interceptors.addAll(_interceptors);

    return googleTts;
  }

  static GoogleTts withOAuth({
    oauth2.Client? oauthClient,
    LogOptions logOptions = const LogOptions(
      LogLevel.error,
      stackTraceLevel: LogLevel.off,
    ),
  }) {
    _resetSharedState();

    final googleTts = GoogleTts(
      logOptions: logOptions,
      printer: const PrettyPrinter(showColors: false),
    );

    // Create the access control once and reuse it across all requests.
    // The IO implementation reads `client_secrets.json` (and may obtain
    // tokens interactively) in its constructor / init(), so creating a
    // new instance per request would re-do that work.
    final oauthAccessControl = OAuthAccessControl(oauthClient);

    addInterceptor(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await oauthAccessControl.checkAccessToken();

          options.headers['Authorization'] =
              'Bearer ${oauthAccessControl.token}';

          return handler.next(options);
        },
      ),
    );

    googleTts.setModules();

    dio.interceptors.addAll(_interceptors);

    return googleTts;
  }

  static Future<GoogleTts> withGenerator(
    RefreshTokenGenerator refreshTokenGenerator, {
    LogOptions logOptions = const LogOptions(
      LogLevel.error,
      stackTraceLevel: LogLevel.off,
    ),
  }) async {
    _resetSharedState();

    final googleTts = GoogleTts(logOptions: logOptions);

    Token token = await refreshTokenGenerator.generate();

    addInterceptor(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Authorization'] = 'Bearer ${token.accessToken}';

          return handler.next(options);
        },
      ),
    );

    googleTts.setModules();

    dio.interceptors.addAll(_interceptors);

    return googleTts;
  }

  /// Clears interceptors and per-request `Authorization` headers from the
  /// shared [dio] / [_interceptors] state.
  ///
  /// The factory constructors ([withApiKey], [withOAuth], [withGenerator])
  /// each install their own auth strategy onto the process-wide static
  /// `dio` / `_interceptors`. Without resetting first, a process that
  /// switches between, say, an OAuth-bound `GoogleTts` and an API-key
  /// `GoogleTts` would leak the previous `Bearer ...` interceptor onto
  /// the new client and duplicate `LoggingInterceptors`.
  static void _resetSharedState() {
    _interceptors.clear();
    dio.interceptors.clear();
    dio.options.headers.remove('Authorization');
  }

  static void addInterceptor(
    Interceptor interceptor, {
    ListPosition position = ListPosition.start,
  }) {
    switch (position) {
      case ListPosition.start:
        _interceptors.insert(0, interceptor);

        break;
      case ListPosition.end:
        _interceptors.add(interceptor);

        break;
    }
  }

  void setModules({String? apiKey}) {
    /// A [Voice] resource is a Google Cloud Text-to-Speech voice; the
    /// `voices` resource lists the voices available to the project.
    _voices = Voices(apiKey: apiKey, dio: dio);

    /// The `text` resource synthesizes the requested text or SSML input
    /// into audio.
    _synthesize = Synthesize(apiKey: apiKey, dio: dio);
  }

  void close() => dio.close();
}

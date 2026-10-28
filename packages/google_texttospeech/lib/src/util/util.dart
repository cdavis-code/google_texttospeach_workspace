import 'dart:convert';

import 'package:loggy/loggy.dart';

class Util {
  static LogOptions convertToLogOptions(String logLevel) {
    var logOptions = const LogOptions(LogLevel.off);

    switch (logLevel) {
      case 'all':
        logOptions = const LogOptions(LogLevel.all);
        break;

      case 'debug':
        logOptions = const LogOptions(LogLevel.debug);
        break;

      case 'info':
        logOptions = const LogOptions(LogLevel.info);
        break;

      case 'warning':
        logOptions = const LogOptions(LogLevel.warning);
        break;

      case 'error':
        logOptions = const LogOptions(LogLevel.error);
        break;
    }

    return logOptions;
  }

  static Encoding defaultEncoding() => Encoding.getByName('utf-8')!;

  static T cast<T>(dynamic x, {required T fallback}) => x is T ? x : fallback;

  /// Environment variable name pointing at the OAuth client-secret JSON file.
  ///
  /// May contain an absolute path, a `~`-prefixed path, or a path relative
  /// to the current working directory.
  ///
  /// Resolution order (see `OAuthAccessControlIo` and `CredentialsPath`):
  ///   1. Runtime environment (`Platform.environment`)
  ///   2. `.env` file in the current working directory
  ///   3. Caller-supplied default (e.g. `$HOME/.tts/client_secrets.json`)
  static const String envTtsClientSecretsFile =
      'GOOGLE_TTS_CLIENT_SECRETS_FILE';

  /// Environment variable name pointing at the persisted OAuth access /
  /// refresh token JSON file.
  ///
  /// Same resolution order as [envTtsClientSecretsFile].
  static const String envTtsAccessTokensFile = 'GOOGLE_TTS_ACCESS_TOKENS_FILE';

  /// Environment variable name for the Google Cloud Text-to-Speech API key.
  ///
  /// Resolution order (see `CredentialsPath`):
  ///   1. Runtime environment (`Platform.environment`)
  ///   2. `.env` file in the current working directory
  ///   3. Explicit `apiKey` parameter passed to `GoogleTts.withApiKey()`
  static const String envTtsApiKey = 'GOOGLE_TTS_API_KEY';

  /// Default credentials directory name (relative to the user's home directory).
  static const String defaultCredentialsDirname = '.tts';

  /// Filename for the client credentials (client_secret) file.
  static const String credentialsFilename = 'client_secrets.json';

  /// Filename for the persisted OAuth access credentials.
  static const String accessCredentialsFilename = 'tts_access_tokens.json';
}

enum ListPosition { start, end }

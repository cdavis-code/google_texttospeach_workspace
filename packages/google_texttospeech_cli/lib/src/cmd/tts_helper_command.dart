import 'package:args/command_runner.dart';
import 'package:loggy/loggy.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:universal_io/io.dart';
import 'package:google_texttospeech/google_texttospeech.dart';

import '../util/security_util.dart';

/// Base class for commands that call the Text-to-Speech API. Handles
/// authentication (API key first, then stored OAuth tokens) and exposes the
/// [voices] and [synthesize] service modules to subclasses.
abstract class TtsHelperCommand extends Command<void> {
  late final GoogleTts _tts;

  /// The `voices` resource, for listing available voices.
  Voices get voices => _tts.voices;

  /// The `text` resource, for synthesizing speech.
  Synthesize get synthesize => _tts.synthesize;

  /// Builds the [GoogleTts] client, preferring `GOOGLE_TTS_API_KEY` (env or
  /// `.env`) and otherwise loading stored OAuth credentials.
  Future<void> initializeTts() async {
    // Prefer GOOGLE_TTS_API_KEY (env or .env) when present; a TTS API key
    // covers both v1 methods. Otherwise fall back to stored OAuth
    // credentials from `tts authorize`.
    final apiKey = CredentialsPath.resolveValue(Util.envTtsApiKey);

    if (apiKey != null && apiKey.isNotEmpty) {
      _tts = GoogleTts.withApiKey(apiKey: apiKey);

      Loggy.initLoggy(
        logOptions: Util.convertToLogOptions(globalResults!['log-level']),
      );

      return;
    }

    const secretFilename = 'client_secret.json';
    const tokenFilename = 'tts_access_tokens.json';

    // Resolve each credential file location independently via
    // GOOGLE_TTS_CLIENT_SECRETS_FILE and GOOGLE_TTS_ACCESS_TOKENS_FILE
    // (env var or .env in the current working directory). When neither is
    // set, fall back to the default filenames in the current working
    // directory.
    final secretPath = CredentialsPath.clientSecretsFile(
      defaultPath: secretFilename,
    );
    final tokenPath = CredentialsPath.accessTokensFile(
      defaultPath: tokenFilename,
    );

    final secretFile = File(secretPath);
    final tokenFile = File(tokenPath);

    if (!await secretFile.exists() || !await tokenFile.exists()) {
      print(
        'Not authorized.  Run "tts authorize" to set up OAuth 2.0 credentials,'
        ' or set ${Util.envTtsApiKey}.',
      );
      exit(1);
    }

    // Parse and validate client_secret.json.
    final Map<String, dynamic> config;
    try {
      config = SecurityUtil.parseAndValidateClientSecret(
        await secretFile.readAsString(),
      );
    } on FormatException catch (e) {
      print('Error: ${e.message}');
      print('Re-run "tts authorize" with a valid client_secret.json.');
      exit(1);
    }
    final clientId = config['client_id'] as String;
    final clientSecret = config['client_secret'] as String;

    // Load stored OAuth 2.0 credentials. oauth2.Client transparently
    // refreshes them when expired.
    final credentialsJson = await tokenFile.readAsString();
    final credentials = oauth2.Credentials.fromJson(credentialsJson);
    final oauthClient = oauth2.Client(
      credentials,
      identifier: clientId,
      secret: clientSecret,
    );

    _tts = GoogleTts.withOAuth(
      oauthClient: oauthClient,
      logOptions: Util.convertToLogOptions(globalResults!['log-level']),
    );
  }

  /// Closes the underlying HTTP client and exits the process.
  void close() {
    _tts.close();

    exit(0);
  }
}

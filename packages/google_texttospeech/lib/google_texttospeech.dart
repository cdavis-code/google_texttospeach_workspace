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

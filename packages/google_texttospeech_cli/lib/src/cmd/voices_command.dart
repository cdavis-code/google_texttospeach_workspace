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
        'language-code',
        valueHelp: 'tag',
        help:
            'Optional BCP-47 language tag (e.g. en-US). Only voices that can '
            'synthesize this language are returned; omit for all voices.',
      )
      ..addFlag(
        'full',
        negatable: false,
        help:
            'Print the full voice records (JSON) instead of just the voice '
            'names accepted by `synthesize --name`.',
      );
  }

  @override
  void run() async {
    await initializeTts();

    try {
      final response = await voices.list(
        languageCode: argResults?['language-code'],
      );

      if (argResults!['full'] as bool) {
        print(response);
      } else {
        for (final name in synthesizableVoiceNames(response.voices)) {
          print(name);
        }
      }

      close();
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// Voice names that `synthesize --name` accepts directly.
///
/// `voices.list` returns two kinds of entries: language-scoped names that
/// begin with a BCP-47 code (lowercase, e.g. `en-US-Wavenet-D`) and global
/// aliases that begin with an uppercase proper noun (e.g. `Achernar`). The
/// aliases only synthesize with an extra (undocumented) model name, so they
/// are dropped here; only the directly-usable names are returned.
List<String> synthesizableVoiceNames(Iterable<Voice>? voices) => [
  for (final v in voices ?? const <Voice>[])
    if (v.name != null && _languageScopedPattern.hasMatch(v.name!)) v.name!,
];

final _languageScopedPattern = RegExp(r'^[a-z]');

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

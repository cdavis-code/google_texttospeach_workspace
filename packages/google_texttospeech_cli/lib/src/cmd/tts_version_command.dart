import 'package:args/command_runner.dart';
import 'package:google_texttospeech_cli/meta.dart';

/// Display the google_texttospeech_cli package name and version information.
///
/// This command is useful for verifying the installed version
/// and troubleshooting compatibility issues.
class TtsVersionCommand extends Command<void> {
  @override
  String get description => 'Display the package name and version';

  @override
  String get name => 'version';

  @override
  void run() async {
    print('${pubSpec['name']} v${pubSpec['version']}');
  }
}

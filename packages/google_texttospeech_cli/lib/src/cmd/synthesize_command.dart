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
      ..addOption(
        'text',
        help: 'Plain text to synthesize (exclusive with --ssml).',
      )
      ..addOption(
        'ssml',
        help: 'SSML document to synthesize (exclusive with --text).',
      )
      ..addOption(
        'prompt',
        help:
            'System instruction for promptable models (e.g. Gemini-TTS) to '
            'steer tone/style; ignored by other models.',
      )
      ..addOption(
        'language-code',
        valueHelp: 'tag',
        defaultsTo: 'en-US',
        help: 'BCP 47 language tag of the desired voice.',
      )
      ..addOption(
        'name',
        valueHelp: 'voice',
        help: 'Name of the voice, e.g. en-US-Wavenet-D.',
      )
      ..addOption(
        'model-name',
        valueHelp: 'model',
        help:
            'Optional model name. Usually leave unset: pick a voice by its '
            'full --name (e.g. en-US-Chirp3-HD-Achernar).',
      )
      ..addOption(
        'gender',
        allowed: ['unspecified', 'male', 'female', 'neutral'],
        help: 'Preferred voice gender.',
      )
      ..addOption(
        'encoding',
        allowed: ['linear16', 'mp3', 'ogg-opus'],
        defaultsTo: 'mp3',
        help: 'Audio encoding of the output.',
      )
      ..addOption('speaking-rate', valueHelp: 'rate')
      ..addOption('pitch', valueHelp: 'semitones')
      ..addOption('sample-rate', valueHelp: 'hz')
      ..addOption('volume-gain', valueHelp: 'db')
      ..addMultiOption('effects-profile', valueHelp: 'profile')
      ..addOption(
        'out',
        valueHelp: 'path',
        help: 'Output file. Default out.<ext>. Use "-" for base64 on stdout.',
      );
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
        input: SynthesisInput(
          text: text,
          ssml: ssml,
          prompt: argResults?['prompt'] as String?,
        ),
        voice: VoiceSelectionParams(
          languageCode: argResults!['language-code'] as String,
          name: argResults?['name'],
          modelName: argResults?['model-name'],
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

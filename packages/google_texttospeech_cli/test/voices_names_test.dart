import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:google_texttospeech_cli/google_texttospeech_cli.dart';
import 'package:test/test.dart';

void main() {
  test('keeps language-scoped names, drops uppercase aliases', () {
    const voices = [
      Voice(name: 'Achernar'), // global Chirp alias -> dropped
      Voice(name: 'en-US-Chirp3-HD-Achernar'), // usable
      Voice(name: 'en-US-Wavenet-D'), // usable
      Voice(), // null name -> dropped
    ];

    expect(synthesizableVoiceNames(voices), [
      'en-US-Chirp3-HD-Achernar',
      'en-US-Wavenet-D',
    ]);
  });

  test('handles null voice list', () {
    expect(synthesizableVoiceNames(null), isEmpty);
  });
}

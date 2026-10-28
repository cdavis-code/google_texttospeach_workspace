import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:test/test.dart';

void main() {
  test('request json round trip uses API enum values', () {
    // Wire format the API expects/returns.
    const wire = {
      'input': {'text': 'hello'},
      'voice': {
        'languageCode': 'en-US',
        'name': 'en-US-Wavenet-D',
        'ssmlGender': 'MALE',
      },
      'audioConfig': {'audioEncoding': 'OGG_OPUS', 'speakingRate': 1.2},
    };

    final decoded = SynthesizeSpeechRequest.fromJson(wire);
    expect(decoded.audioConfig.audioEncoding, AudioEncoding.oggOpus);
    expect(decoded.voice.ssmlGender, SsmlVoiceGender.male);

    // Round trip through our own encoder, verifying nested models are
    // encoded eagerly (explicit_to_json) so Dio sends proper JSON.
    final json = decoded.toJson();
    expect((json['voice'] as Map<String, dynamic>)['ssmlGender'], 'MALE');
    expect(
      (json['audioConfig'] as Map<String, dynamic>)['audioEncoding'],
      'OGG_OPUS',
    );
    final redecoded = SynthesizeSpeechRequest.fromJson(decoded.toJson());
    expect(redecoded.voice.languageCode, 'en-US');
    expect(redecoded.input.text, 'hello');
    expect(redecoded.audioConfig.speakingRate, 1.2);
  });

  test('voice response decodes', () {
    final response = ListVoicesResponse.fromJson({
      'voices': [
        {
          'name': 'en-US-Wavenet-A',
          'languageCodes': ['en-US'],
          'ssmlGender': 'FEMALE',
          'naturalSampleRateHertz': 24000.0,
        },
      ],
    });
    expect(response.voices!.single.ssmlGender, SsmlVoiceGender.female);
  });

  test('unknown gender maps to unknown', () {
    expect(
      Voice.fromJson({'ssmlGender': 'ROBOT'}).ssmlGender,
      SsmlVoiceGender.unknown,
    );
  });

  test('SynthesisInput enforces oneof', () {
    expect(() => SynthesisInput(), throwsA(isA<AssertionError>()));
    expect(
      () => SynthesisInput(text: 'a', ssml: '<speak>a</speak>'),
      throwsA(isA<AssertionError>()),
    );
  });

  test('request body omits null fields (no proto oneof collision)', () {
    final body = SynthesizeSpeechRequest(
      input: SynthesisInput(text: 'hi'),
      voice: const VoiceSelectionParams(languageCode: 'en-US'),
      audioConfig: const AudioConfig(audioEncoding: AudioEncoding.mp3),
    ).toJson();

    // `ssml: null` would make Google treat text+ssml as a set oneof -> 400.
    expect((body['input'] as Map), isNot(contains('ssml')));
    expect((body['input'] as Map), isNot(contains('prompt')));
    expect((body['voice'] as Map), isNot(contains('name')));
    expect((body['voice'] as Map), isNot(contains('modelName')));
    expect((body['audioConfig'] as Map), isNot(contains('speakingRate')));
  });

  test('modelName serializes for Chirp 3 HD voices', () {
    final body = SynthesizeSpeechRequest(
      input: SynthesisInput(text: 'hi'),
      voice: const VoiceSelectionParams(
        languageCode: 'en-US',
        name: 'Achernar',
        modelName: 'chirp_3_hd',
      ),
      audioConfig: const AudioConfig(audioEncoding: AudioEncoding.mp3),
    ).toJson();

    expect((body['voice'] as Map)['modelName'], 'chirp_3_hd');
    expect(
      SynthesizeSpeechRequest.fromJson(body).voice.modelName,
      'chirp_3_hd',
    );
  });

  test('prompt serializes alongside text for promptable models', () {
    final body = SynthesisInput(
      text: 'hi',
      prompt: 'warm, welcoming tone',
    ).toJson();
    expect(body['text'], 'hi');
    expect(body['prompt'], 'warm, welcoming tone');
  });
}

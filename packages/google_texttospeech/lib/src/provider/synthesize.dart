import 'package:dio/dio.dart';
import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:retrofit/retrofit.dart';

part 'synthesize.g.dart';

/// REST client for the texttospeech.googleapis.com v1 `text` resource.
@RestApi(baseUrl: 'https://texttospeech.googleapis.com/v1')
abstract class SynthesizeClient {
  factory SynthesizeClient(Dio dio, {String baseUrl}) = _SynthesizeClient;

  /// Synthesizes the requested text and returns the generated audio data
  /// in a [SynthesizeSpeechResponse].
  @POST('/text:synthesize')
  Future<SynthesizeSpeechResponse> synthesize(
    @Query('key') String? apiKey,
    @Header('Accept') String accept,
    @Header('Content-Type') String contentType,
    @Body() SynthesizeSpeechRequest body,
  );
}

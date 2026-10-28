import 'package:dio/dio.dart';
import 'package:google_texttospeech/google_texttospeech.dart';
import 'package:retrofit/retrofit.dart';

part 'voices.g.dart';

/// REST client for the texttospeech.googleapis.com v1 `voices` resource.
@RestApi(baseUrl: 'https://texttospeech.googleapis.com/v1')
abstract class VoicesClient {
  factory VoicesClient(Dio dio, {String baseUrl}) = _VoicesClient;

  /// Returns the list of voices that is available from the
  /// Text-to-Speech API.
  @GET('/voices')
  Future<ListVoicesResponse> list(
    @Query('key') String? apiKey,
    @Header('Accept') String accept, {
    @Query('languageCode') String? languageCode,
  });
}

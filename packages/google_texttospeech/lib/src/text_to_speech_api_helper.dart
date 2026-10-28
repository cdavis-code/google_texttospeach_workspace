import 'package:dio/dio.dart';

abstract class TextToSpeechApiHelper {
  final String? token;
  final String? apiKey;
  final Dio dio;

  final accept = 'application/json';

  final contentType = 'application/json';

  TextToSpeechApiHelper({required this.dio, this.token, this.apiKey});
}

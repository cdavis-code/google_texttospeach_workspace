import 'package:google_texttospeech/google_texttospeech.dart';

abstract class RefreshTokenGenerator {
  Future<Token> generate();
}

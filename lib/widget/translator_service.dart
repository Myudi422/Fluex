import 'package:translator/translator.dart';

class TranslatorService {
  static Future<String?> translateDescription(String originalDescription) async {
    final translator = GoogleTranslator();
    
    try {
      final translation = await translator.translate(originalDescription, to: 'id');
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      // You can handle the error here, e.g., return the original description or a default value.
      return originalDescription;
    }
  }
}

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ocr_result.dart';

class OcrServiceException implements Exception {
  final String message;
  OcrServiceException(this.message);

  @override
  String toString() => message;
}

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<OcrResult> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _recognizer.processImage(
        inputImage,
      );

      final blocks = recognizedText.blocks
          .map(
            (TextBlock block) => OcrTextBlock(
              text: block.text,
              boundingBox: block.boundingBox,
              lines: block.lines
                  .map(
                    (TextLine line) => OcrTextLine(
                      text: line.text,
                      boundingBox: line.boundingBox,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();

      return OcrResult(fullText: recognizedText.text, blocks: blocks);
    } catch (e) {
      throw OcrServiceException('Failed to recognize text: $e');
    }
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}

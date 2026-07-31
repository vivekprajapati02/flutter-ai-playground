import 'dart:ui';

class OcrTextLine {
  final String text;
  final Rect? boundingBox;
  const OcrTextLine({required this.text, this.boundingBox});
}

class OcrTextBlock {
  final String text;
  final Rect? boundingBox;
  final List<OcrTextLine> lines;
  const OcrTextBlock({
    required this.text,
    required this.lines,
    this.boundingBox,
  });
}

class OcrResult {
  final String fullText;
  final List<OcrTextBlock> blocks;
  const OcrResult({required this.fullText, required this.blocks});

  bool get hasText => fullText.trim().isNotEmpty;

  static const empty = OcrResult(fullText: '', blocks: []);
}

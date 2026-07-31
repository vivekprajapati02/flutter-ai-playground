import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ocr_result.dart';
import '../services/ocr_service.dart';

class OcrController extends GetxController {
  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();

  final Rx<File?> pickedImage = Rx<File?>(null);
  final Rx<OcrResult?> result = Rx<OcrResult?>(null);
  final RxBool isProcessing = false.obs;

  Future<void> pickFromGallery() => _pickAndRecognize(ImageSource.gallery);

  Future<void> pickFromCamera() => _pickAndRecognize(ImageSource.camera);

  Future<void> _pickAndRecognize(ImageSource source) async {
    if (isProcessing.value) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (file == null) {
        return;
      }

      pickedImage.value = File(file.path);
      result.value = null;
      await runOcr(file.path);
    } on PlatformException catch (e) {
      final msg = e.code == 'camera_access_denied'
          ? 'Camera permission was denied. Enable it in system settings to scan labels.'
          : 'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: ${e.message}';
      Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unexpected error picking image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> runOcr(String imagePath) async {
    isProcessing.value = true;
    try {
      final ocrResult = await _ocrService.recognizeText(imagePath);
      result.value = ocrResult;
      if (!ocrResult.hasText) {
        Get.snackbar(
          'No text found',
          'No readable text was detected. Try a clearer, well-lit photo.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on OcrServiceException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unexpected error running OCR: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> copyResultToClipboard() async {
    final text = result.value?.fullText ?? '';
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      'Extracted text copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    _ocrService.dispose();
    super.onClose();
  }
}

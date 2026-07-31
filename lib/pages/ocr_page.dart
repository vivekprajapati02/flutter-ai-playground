import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ocr_controller.dart';
import '../widgets/detected_text_card.dart';

class OcrPage extends GetView<OcrController> {
  const OcrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Scan Product Label'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePreview(context),
              const SizedBox(height: 16),
              _buildPickButtons(context),
              const SizedBox(height: 20),
              _buildResultArea(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final file = controller.pickedImage.value;
      if (file == null) {
        return Container(
          height: 220,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: 56,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Take or pick a photo of a product label\nto extract its text',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          file,
          height: 260,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    });
  }

  Widget _buildPickButtons(BuildContext context) {
    return Obx(() {
      final disabled = controller.isProcessing.value;
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: disabled ? null : controller.pickFromCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Camera'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: disabled ? null : controller.pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildResultArea(BuildContext context) {
    return Obx(() {
      if (controller.isProcessing.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Extracting text...'),
              ],
            ),
          ),
        );
      }

      final result = controller.result.value;
      if (result == null) {
        return const SizedBox.shrink();
      }

      if (!result.hasText) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No text detected in this image. Try a clearer, well-lit photo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }

      return DetectedTextCard(
        text: result.fullText,
        onCopy: controller.copyResultToClipboard,
      );
    });
  }
}

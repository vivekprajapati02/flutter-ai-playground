import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/rag_service.dart';
import '../services/settings_service.dart';

class SettingsController extends GetxController {
  final SettingsService _settingsService = SettingsService();

  late final TextEditingController baseUrlController;
  final RxBool isTestingConnection = false.obs;
  final Rx<bool?> connectionOk = Rx<bool?>(null);

  @override
  void onInit() {
    super.onInit();
    baseUrlController = TextEditingController(
      text: _settingsService.getOrDefault().baseUrl,
    );
  }

  Future<void> saveBaseUrl() async {
    final url = baseUrlController.text.trim();
    if (url.isEmpty) {
      Get.snackbar(
        'Invalid URL',
        'Base URL cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await _settingsService.save(url);
    Get.snackbar(
      'Saved',
      'Backend base URL updated.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> testConnection() async {
    final url = baseUrlController.text.trim();
    if (url.isEmpty) {
      Get.snackbar(
        'Invalid URL',
        'Base URL cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isTestingConnection.value = true;
    connectionOk.value = null;
    try {
      final ragService = RagService(baseUrl: url);
      final ok = await ragService.checkHealth();
      connectionOk.value = ok;
    } finally {
      isTestingConnection.value = false;
    }
  }

  @override
  void onClose() {
    baseUrlController.dispose();
    super.onClose();
  }
}

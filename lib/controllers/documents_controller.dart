import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../models/rag_document.dart';
import '../services/rag_service.dart';
import '../services/settings_service.dart';

class DocumentsController extends GetxController {
  final SettingsService _settingsService = SettingsService();
  late RagService _ragService;

  final RxList<RagDocument> documents = <RagDocument>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _ragService = RagService(baseUrl: _settingsService.getOrDefault().baseUrl);
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    isLoading.value = true;
    try {
      final result = await _ragService.listDocuments();
      documents.assignAll(result);
    } on RagServiceException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unexpected error: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    if (!path.toLowerCase().endsWith('.pdf')) {
      Get.snackbar(
        'Invalid file',
        'Please select a PDF file.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isUploading.value = true;
    uploadProgress.value = 0;
    try {
      await _ragService.uploadDocument(
        path,
        onProgress: (p) => uploadProgress.value = p,
      );
      await fetchDocuments();
    } on RagServiceException catch (e) {
      Get.snackbar('Upload failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'Upload failed',
        'Unexpected error: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _ragService.deleteDocument(id);
      documents.removeWhere((d) => d.id == id);
    } on RagServiceException catch (e) {
      Get.snackbar('Delete failed', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'Delete failed',
        'Unexpected error: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

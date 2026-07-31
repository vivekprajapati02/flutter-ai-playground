import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/documents_controller.dart';
import '../controllers/rag_chat_controller.dart';
import '../services/settings_service.dart';
import '../widgets/document_list_tile.dart';
import 'pdf_viewer_page.dart';
import 'rag_chat_page.dart';

class DocumentsPage extends GetView<DocumentsController> {
  const DocumentsPage({super.key});

  void _openChat() {
    Get.lazyPut<RagChatController>(() => RagChatController());
    Get.to(() => const RagChatPage());
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = SettingsService().getOrDefault().baseUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'RAG Chat',
            onPressed: _openChat,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isUploading.value) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Obx(
                  () => LinearProgressIndicator(value: controller.uploadProgress.value),
                ),
              ),
              Expanded(child: _buildList(context, baseUrl)),
            ],
          );
        }
        return _buildList(context, baseUrl);
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.uploadDocument,
        tooltip: 'Upload PDF',
        child: const Icon(Icons.upload_file),
      ),
    );
  }

  Widget _buildList(BuildContext context, String baseUrl) {
    return Obx(() {
      if (controller.isLoading.value && controller.documents.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.documents.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.fetchDocuments,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(
                  child: Text('No documents yet. Tap the upload button to add one.'),
                ),
              ),
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.fetchDocuments,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: controller.documents.length,
          itemBuilder: (context, index) {
            final doc = controller.documents[index];
            return DocumentListTile(
              document: doc,
              onDelete: () => controller.deleteDocument(doc.id),
              onTap: () => Get.to(
                () => PdfViewerPage(
                  documentId: doc.id,
                  baseUrl: baseUrl,
                  filename: doc.filename,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

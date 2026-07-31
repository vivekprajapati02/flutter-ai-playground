import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/rag_chat_controller.dart';
import '../models/rag_source.dart';
import '../services/settings_service.dart';
import '../widgets/rag_message_bubble.dart';
import 'pdf_viewer_page.dart';

class RagChatPage extends GetView<RagChatController> {
  const RagChatPage({super.key});

  void _openSource(RagSource source) {
    final documentId = source.documentId;
    if (documentId == null) {
      Get.snackbar(
        'Unavailable',
        'This source does not reference a specific document.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final baseUrl = SettingsService().getOrDefault().baseUrl;
    Get.to(
      () => PdfViewerPage(
        documentId: documentId,
        baseUrl: baseUrl,
        filename: source.filename,
        initialPage: source.page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RAG Chat'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildScopeSelector(context),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    return RagMessageBubble(
                      message: controller.messages[index],
                      onSourceTap: _openSource,
                    );
                  },
                ),
              ),
            ),
            Obx(
              () => controller.isLoading.value
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Searching documents...'),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const Divider(height: 1),
            _buildInputRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Obx(
        () => DropdownButtonFormField(
          initialValue: controller.selectedDocument.value?.id,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Scope',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All documents'),
            ),
            ...controller.availableDocuments.map(
              (doc) => DropdownMenuItem<String?>(
                value: doc.id,
                child: Text(doc.filename, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (id) {
            if (id == null) {
              controller.selectDocument(null);
              return;
            }
            final doc = controller.availableDocuments.firstWhereOrNull(
              (d) => d.id == id,
            );
            controller.selectDocument(doc);
          },
        ),
      ),
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.textController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => controller.askQuestion(),
              decoration: InputDecoration(
                hintText: 'Ask a question about your documents...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => IconButton.filled(
              onPressed: controller.isLoading.value ? null : controller.askQuestion,
              icon: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}

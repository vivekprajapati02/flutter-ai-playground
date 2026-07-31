import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/rag_conversation.dart';
import '../models/rag_document.dart';
import '../models/rag_message.dart';
import '../services/rag_history_service.dart';
import '../services/rag_service.dart';
import '../services/settings_service.dart';

class RagChatController extends GetxController {
  final SettingsService _settingsService = SettingsService();
  final RagHistoryService _historyService = RagHistoryService();
  late RagService _ragService;

  final RxList<RagMessage> messages = <RagMessage>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<RagDocument?> selectedDocument = Rx<RagDocument?>(null);
  final RxList<RagDocument> availableDocuments = <RagDocument>[].obs;

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String? _conversationId;

  @override
  void onInit() {
    super.onInit();
    _ragService = RagService(baseUrl: _settingsService.getOrDefault().baseUrl);
    _loadAvailableDocuments();
    _loadLastConversation();
  }

  Future<void> _loadAvailableDocuments() async {
    try {
      final docs = await _ragService.listDocuments();
      availableDocuments.assignAll(docs);
    } catch (_) {
      // Non-fatal — the "All documents" scope still works without this.
    }
  }

  void _loadLastConversation() {
    final all = _historyService.getAll();
    if (all.isEmpty) return;
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final latest = all.first;
    _conversationId = latest.id;
    messages.assignAll(latest.messages);
  }

  void selectDocument(RagDocument? doc) {
    selectedDocument.value = doc;
  }

  Future<void> askQuestion() async {
    final question = textController.text.trim();
    if (question.isEmpty || isLoading.value) return;

    final userMessage = RagMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: question,
      isUser: true,
    );
    messages.add(userMessage);
    textController.clear();
    _scrollToBottom();

    isLoading.value = true;
    try {
      final answer = await _ragService.ask(
        question,
        documentId: selectedDocument.value?.id,
      );
      messages.add(answer);
      await _autoSaveConversation();
    } on RagServiceException catch (e) {
      messages.add(
        RagMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          content: e.message,
          isUser: false,
          isError: true,
        ),
      );
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      final msg = 'Unexpected error: $e';
      messages.add(
        RagMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          content: msg,
          isUser: false,
          isError: true,
        ),
      );
      Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  Future<void> _autoSaveConversation() async {
    final id =
        _conversationId ??= DateTime.now().microsecondsSinceEpoch.toString();
    final existing = _historyService.getById(id);
    final firstUserMessage = messages.firstWhereOrNull((m) => m.isUser);
    final conversation =
        existing ??
        RagConversation(
          id: id,
          title: firstUserMessage != null
              ? _deriveTitle(firstUserMessage.content)
              : 'RAG Chat',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    conversation.messages = messages.toList();
    await _historyService.save(conversation);
  }

  String _deriveTitle(String firstUserText) => firstUserText.length > 40
      ? '${firstUserText.substring(0, 40)}...'
      : firstUserText;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

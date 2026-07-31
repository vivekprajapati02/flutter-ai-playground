import 'package:get/get.dart';

import '../models/conversation.dart';
import '../models/rag_document.dart';
import '../services/history_service.dart';
import '../services/rag_history_service.dart';
import '../services/rag_service.dart';
import '../services/settings_service.dart';

class HomeController extends GetxController {
  final HistoryService _historyService = HistoryService();
  final RagHistoryService _ragHistoryService = RagHistoryService();
  final SettingsService _settingsService = SettingsService();

  final RxList<Conversation> recentChats = <Conversation>[].obs;
  final RxList<RagDocument> recentDocuments = <RagDocument>[].obs;

  final RxInt documentCount = 0.obs;
  final RxInt chatCount = 0.obs;
  final RxInt questionCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    final chats = _historyService.getAll()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final ragChats = _ragHistoryService.getAll();

    recentChats.assignAll(chats.take(4));
    chatCount.value = chats.length + ragChats.length;

    final regularQuestions = chats.fold<int>(
      0,
      (sum, c) => sum + c.messages.where((m) => m.isUser).length,
    );
    final ragQuestions = ragChats.fold<int>(
      0,
      (sum, c) => sum + c.messages.where((m) => m.isUser).length,
    );
    questionCount.value = regularQuestions + ragQuestions;

    try {
      final ragService = RagService(
        baseUrl: _settingsService.getOrDefault().baseUrl,
      );
      final docs = await ragService.listDocuments();
      recentDocuments.assignAll(docs.take(3));
      documentCount.value = docs.length;
    } catch (_) {
      // Backend may be unreachable from Home — leave document stats at
      // their last-known values rather than surfacing an error here.
    }
  }
}

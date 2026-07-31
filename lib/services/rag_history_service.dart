import 'package:hive_flutter/hive_flutter.dart';

import '../models/rag_conversation.dart';

class RagHistoryService {
  static const String boxName = 'rag_conversations';

  Box<RagConversation> get _box => Hive.box<RagConversation>(boxName);

  List<RagConversation> getAll() => _box.values.toList();

  RagConversation? getById(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(RagConversation conversation) async {
    conversation.updatedAt = DateTime.now();
    await _box.put(conversation.id, conversation);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}

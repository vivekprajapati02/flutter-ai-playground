import 'package:hive_flutter/hive_flutter.dart';

import '../models/conversation.dart';

class HistoryService {
  static const String boxName = 'conversations';

  Box<Conversation> get _box => Hive.box<Conversation>(boxName);

  List<Conversation> getAll() => _box.values.toList();

  Conversation? getById(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Conversation conversation) async {
    conversation.updatedAt = DateTime.now();
    await _box.put(conversation.id, conversation);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> togglePin(String id) async {
    final c = _box.get(id);
    if (c == null) return;
    c.pinned = !c.pinned;
    await c.save();
  }

  List<Conversation> search(String query) {
    if (query.trim().isEmpty) return getAll();
    final q = query.toLowerCase();
    return _box.values.where((c) {
      if (c.title.toLowerCase().contains(q)) return true;
      return c.messages.any((m) => m.content.toLowerCase().contains(q));
    }).toList();
  }
}

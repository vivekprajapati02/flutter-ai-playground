import 'package:get/get.dart';

import '../models/conversation.dart';
import '../services/history_service.dart';

class HistoryController extends GetxController {
  final HistoryService _service = HistoryService();

  final RxList<Conversation> _all = <Conversation>[].obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void reload() {
    _all.assignAll(_service.getAll());
  }

  List<Conversation> get filtered {
    final list = searchQuery.value.trim().isEmpty
        ? _all.toList()
        : _service.search(searchQuery.value);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<Conversation> get pinned =>
      filtered.where((c) => c.pinned).toList();

  Map<String, List<Conversation>> get groupedUnpinned {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));

    final groups = <String, List<Conversation>>{
      'Today': [],
      'Yesterday': [],
      'Last Week': [],
      'Older': [],
    };
    for (final c in filtered.where((c) => !c.pinned)) {
      final d = DateTime(c.updatedAt.year, c.updatedAt.month, c.updatedAt.day);
      if (d == today) {
        groups['Today']!.add(c);
      } else if (d == yesterday) {
        groups['Yesterday']!.add(c);
      } else if (d.isAfter(lastWeek)) {
        groups['Last Week']!.add(c);
      } else {
        groups['Older']!.add(c);
      }
    }
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    reload();
  }

  Future<void> togglePin(String id) async {
    await _service.togglePin(id);
    reload();
  }
}

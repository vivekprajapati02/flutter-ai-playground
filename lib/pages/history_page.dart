import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/main_shell_controller.dart';
import '../models/conversation.dart';

class HistoryPage extends GetView<HistoryController> {
  const HistoryPage({super.key});

  void _openConversation(Conversation conversation) {
    Get.find<ChatController>().loadConversation(conversation);
    Get.find<MainShellController>().changeTab(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Chat History'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => controller.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final pinned = controller.pinned;
                final grouped = controller.groupedUnpinned;

                if (pinned.isEmpty && grouped.isEmpty) {
                  return const Center(child: Text('No conversations yet.'));
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    if (pinned.isNotEmpty) ...[
                      _sectionHeader(context, 'Pinned'),
                      ...pinned.map((c) => _conversationTile(context, c)),
                    ],
                    for (final entry in grouped.entries) ...[
                      _sectionHeader(context, entry.key),
                      ...entry.value.map((c) => _conversationTile(context, c)),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _conversationTile(BuildContext context, Conversation conversation) {
    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => controller.delete(conversation.id),
      child: ListTile(
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${conversation.messages.length} messages'),
        trailing: IconButton(
          icon: Icon(
            conversation.pinned ? Icons.push_pin : Icons.push_pin_outlined,
          ),
          tooltip: conversation.pinned ? 'Unpin' : 'Pin',
          onPressed: () => controller.togglePin(conversation.id),
        ),
        onTap: () => _openConversation(conversation),
      ),
    );
  }
}

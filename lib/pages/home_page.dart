import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/main_shell_controller.dart';
import '../controllers/ocr_controller.dart';
import '../widgets/home_action_card.dart';
import '../widgets/stat_tile.dart';
import 'ocr_page.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  void _goToTab(int index) {
    Get.find<MainShellController>().changeTab(index);
  }

  void _openOcr() {
    Get.lazyPut<OcrController>(() => OcrController());
    Get.to(() => const OcrPage());
  }

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit app?'),
        content: const Text('Are you sure you want to exit AI Playground?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Quick Actions'),
                const SizedBox(height: 12),
                _buildQuickActions(context),
                const SizedBox(height: 28),
                _buildRecentChats(context),
                const SizedBox(height: 28),
                _buildRecentDocuments(context),
                const SizedBox(height: 28),
                _buildStatistics(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Playground',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Build with Flutter + FastAPI + Gemini',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        HomeActionCard(
          icon: Icons.chat_bubble_outline,
          title: 'AI Chat',
          subtitle: 'Streaming chat with LLMs.',
          onTap: () => _goToTab(1),
        ),
        HomeActionCard(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Document Chat',
          subtitle: 'Upload PDFs and ask questions.',
          onTap: () => _goToTab(2),
        ),
        HomeActionCard(
          icon: Icons.document_scanner_outlined,
          title: 'OCR Scanner',
          subtitle: 'Extract text from images.',
          onTap: _openOcr,
        ),
        HomeActionCard(
          icon: Icons.sell_outlined,
          title: 'Product Detection',
          subtitle: 'Recognize products using AI.',
          onTap: _openOcr,
        ),
      ],
    );
  }

  Widget _buildRecentChats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, 'Recent Chats'),
            TextButton(
              onPressed: () => _goToTab(3),
              child: const Text('See all'),
            ),
          ],
        ),
        Obx(() {
          if (controller.recentChats.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No conversations yet.'),
            );
          }
          return Column(
            children: controller.recentChats
                .map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(c.title, overflow: TextOverflow.ellipsis),
                    onTap: () => _goToTab(3),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildRecentDocuments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, 'Recent Documents'),
            TextButton(
              onPressed: () => _goToTab(2),
              child: const Text('See all'),
            ),
          ],
        ),
        Obx(() {
          if (controller.recentDocuments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No documents yet.'),
            );
          }
          return Column(
            children: controller.recentDocuments
                .map(
                  (d) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: Text(d.filename, overflow: TextOverflow.ellipsis),
                    onTap: () => _goToTab(2),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Statistics'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Obx(
              () => Row(
                children: [
                  StatTile(
                    value: '${controller.documentCount.value}',
                    label: 'Documents',
                  ),
                  StatTile(
                    value: '${controller.chatCount.value}',
                    label: 'Chats',
                  ),
                  StatTile(
                    value: '${controller.questionCount.value}',
                    label: 'Questions',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

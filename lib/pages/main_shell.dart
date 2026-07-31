import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/documents_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/main_shell_controller.dart';
import '../controllers/settings_controller.dart';
import 'chat_page.dart';
import 'documents_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

/// Hosts Home/Chat/Documents/History/Settings as persistent bottom-nav tabs.
/// OCR, RAG Chat, and the PDF viewer remain pushed detail pages reachable
/// from Home or Documents rather than tabs of their own.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(MainShellController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ChatController>(() => ChatController());
    Get.lazyPut<DocumentsController>(() => DocumentsController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<SettingsController>(() => SettingsController());

    final shell = Get.find<MainShellController>();

    const pages = [
      HomePage(),
      ChatPage(),
      DocumentsPage(),
      HistoryPage(),
      SettingsPage(),
    ];

    return Obx(
      () => Scaffold(
        body: IndexedStack(index: shell.currentIndex.value, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex.value,
          onDestinationSelected: shell.changeTab,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.folder_open_outlined), selectedIcon: Icon(Icons.folder), label: 'Documents'),
            NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

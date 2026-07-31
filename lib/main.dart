import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/conversation.dart';
import 'models/conversation_adapter.dart';
import 'models/rag_conversation.dart';
import 'models/rag_conversation_adapter.dart';
import 'models/rag_settings.dart';
import 'models/rag_settings_adapter.dart';
import 'pages/main_shell.dart';
import 'services/history_service.dart';
import 'services/rag_history_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Hive.initFlutter();
  Hive.registerAdapter(ConversationAdapter());
  Hive.registerAdapter(RagConversationAdapter());
  Hive.registerAdapter(RagSettingsAdapter());
  await Hive.openBox<Conversation>(HistoryService.boxName);
  await Hive.openBox<RagConversation>(RagHistoryService.boxName);
  await Hive.openBox<RagSettings>(SettingsService.boxName);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainShell(),
    );
  }
}

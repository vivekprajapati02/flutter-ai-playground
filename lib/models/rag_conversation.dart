import 'dart:convert';

import 'package:hive/hive.dart';

import 'rag_message.dart';

class RagConversation extends HiveObject {
  String id;
  String title;
  DateTime createdAt;
  DateTime updatedAt;
  String messagesJson;

  RagConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messagesJson = '[]',
  });

  List<RagMessage> get messages => (jsonDecode(messagesJson) as List)
      .map((e) => RagMessage.fromStorageJson(Map<String, dynamic>.from(e)))
      .toList();

  set messages(List<RagMessage> value) {
    messagesJson = jsonEncode(value.map((m) => m.toStorageJson()).toList());
  }
}

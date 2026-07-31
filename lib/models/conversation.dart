import 'dart:convert';

import 'package:hive/hive.dart';

import 'chat_message.dart';

class Conversation extends HiveObject {
  String id;
  String title;
  DateTime createdAt;
  DateTime updatedAt;
  bool pinned;
  String messagesJson;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
    this.messagesJson = '[]',
  });

  List<ChatMessage> get messages => (jsonDecode(messagesJson) as List)
      .map((e) => ChatMessage.fromStorageJson(Map<String, dynamic>.from(e)))
      .toList();

  set messages(List<ChatMessage> value) {
    messagesJson = jsonEncode(value.map((m) => m.toStorageJson()).toList());
  }
}

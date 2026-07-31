import 'package:hive/hive.dart';

import 'rag_conversation.dart';

/// Hand-written TypeAdapter — avoids hive_generator/build_runner.
/// typeId 0 is Conversation; typeId 1 is reserved for RagConversation;
/// do not reuse either for another type.
class RagConversationAdapter extends TypeAdapter<RagConversation> {
  @override
  final int typeId = 1;

  @override
  RagConversation read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return RagConversation(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: DateTime.parse(fields[2] as String),
      updatedAt: DateTime.parse(fields[3] as String),
      messagesJson: fields[4] as String? ?? '[]',
    );
  }

  @override
  void write(BinaryWriter writer, RagConversation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(3)
      ..write(obj.updatedAt.toIso8601String())
      ..writeByte(4)
      ..write(obj.messagesJson);
  }
}

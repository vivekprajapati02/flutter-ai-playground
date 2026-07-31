import 'package:hive/hive.dart';

import 'conversation.dart';

/// Hand-written TypeAdapter — avoids hive_generator/build_runner.
/// typeId 0 is reserved for Conversation; do not reuse for another type.
class ConversationAdapter extends TypeAdapter<Conversation> {
  @override
  final int typeId = 0;

  @override
  Conversation read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return Conversation(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: DateTime.parse(fields[2] as String),
      updatedAt: DateTime.parse(fields[3] as String),
      pinned: fields[4] as bool? ?? false,
      messagesJson: fields[5] as String? ?? '[]',
    );
  }

  @override
  void write(BinaryWriter writer, Conversation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(3)
      ..write(obj.updatedAt.toIso8601String())
      ..writeByte(4)
      ..write(obj.pinned)
      ..writeByte(5)
      ..write(obj.messagesJson);
  }
}

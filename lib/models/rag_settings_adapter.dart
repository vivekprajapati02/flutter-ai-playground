import 'package:hive/hive.dart';

import 'rag_settings.dart';

/// Hand-written TypeAdapter — avoids hive_generator/build_runner.
/// typeId 0 is Conversation, typeId 1 is RagConversation; typeId 2 is
/// reserved for RagSettings; do not reuse any of these for another type.
class RagSettingsAdapter extends TypeAdapter<RagSettings> {
  @override
  final int typeId = 2;

  @override
  RagSettings read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return RagSettings(baseUrl: fields[0] as String);
  }

  @override
  void write(BinaryWriter writer, RagSettings obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.baseUrl);
  }
}

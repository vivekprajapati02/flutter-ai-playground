import 'package:hive_flutter/hive_flutter.dart';

import '../models/rag_settings.dart';

class SettingsService {
  static const String boxName = 'rag_settings';
  static const String _key = 'settings';
  static const String defaultBaseUrl = 'http://192.168.1.3:8000';

  Box<RagSettings> get _box => Hive.box<RagSettings>(boxName);

  RagSettings getOrDefault() {
    return _box.get(_key) ?? RagSettings(baseUrl: defaultBaseUrl);
  }

  Future<void> save(String baseUrl) async {
    await _box.put(_key, RagSettings(baseUrl: baseUrl));
  }
}

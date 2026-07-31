import 'package:hive/hive.dart';

class RagSettings extends HiveObject {
  String baseUrl;

  RagSettings({required this.baseUrl});
}

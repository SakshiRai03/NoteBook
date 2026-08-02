import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

Future<void> initHive([String? storagePath]) async {
  try {
    if (storagePath != null) {
      Hive.init(storagePath);
    } else {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      Hive.init(directory.path);
    }
  } catch (_) {
    Hive.init(Directory.current.path);
  }
}

import 'package:hive_flutter/hive_flutter.dart';

import '../../features/notes/data/models/note_model.dart';
import '../config/app_config.dart';
import 'hive_initializer.dart';

class HiveService {
  HiveService({this.storagePath});

  final String? storagePath;

  Future<void> init() async {
    if (Hive.isBoxOpen(AppConfig.notesBoxName) &&
        Hive.isBoxOpen(AppConfig.queueBoxName)) {
      return;
    }
    await initHive(storagePath);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NoteModelAdapter());
    }
    if (!Hive.isBoxOpen(AppConfig.notesBoxName)) {
      await Hive.openBox(AppConfig.notesBoxName);
    }
    if (!Hive.isBoxOpen(AppConfig.queueBoxName)) {
      await Hive.openBox(AppConfig.queueBoxName);
    }
  }

  Box<dynamic> get notesBox => Hive.box(AppConfig.notesBoxName);

  Box<dynamic> get queueBox => Hive.box(AppConfig.queueBoxName);

  Future<void> clear() async {
    await notesBox.clear();
    await queueBox.clear();
  }
}

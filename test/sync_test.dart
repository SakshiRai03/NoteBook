import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:notebook_app/core/database/hive_service.dart';
import 'package:notebook_app/core/network/dio_client.dart';
import 'package:notebook_app/core/services/sync_service.dart';
import 'package:notebook_app/core/sync/sync_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sync service exposes online status', () async {
    final dir = Directory.systemTemp.createTempSync('notebook_sync_test_');
    Hive.init(dir.path);
    final hiveService = HiveService(storagePath: dir.path);
    await hiveService.init();
    await hiveService.clear();

    final service = SyncService(
      hiveService,
      DioClient(),
      SyncQueue(hiveService),
      () async => true,
    );
    final online = await service.isOnline;
    expect(online, isA<bool>());
  });
}

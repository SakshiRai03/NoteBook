import 'package:get_it/get_it.dart';

import '../../features/notes/data/repositories/notes_repository_impl.dart';
import '../../features/notes/domain/repositories/notes_repository.dart';
import '../database/hive_service.dart';
import '../network/dio_client.dart';
import '../services/sync_service.dart';
import '../sync/sync_queue.dart';

final getIt = GetIt.instance;

Future<void> initDependencies({String? storagePath}) async {
  final hiveService = HiveService(storagePath: storagePath);
  await hiveService.init();
  getIt.registerSingleton<HiveService>(hiveService);

  getIt.registerLazySingleton<DioClient>(() => DioClient());
  getIt.registerLazySingleton<SyncQueue>(() => SyncQueue(getIt<HiveService>()));
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      getIt<HiveService>(),
      getIt<DioClient>(),
      getIt<SyncQueue>(),
    ),
  );
  getIt.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(
      getIt<HiveService>(),
      getIt<DioClient>(),
      getIt<SyncQueue>(),
      () => getIt<SyncService>().syncNow(),
    ),
  );
}

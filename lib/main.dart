import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'features/notes/presentation/pages/notes_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;
  StackTrace? startupStackTrace;
  try {
    await initDependencies();
  } catch (error, stackTrace) {
    startupError = error;
    startupStackTrace = stackTrace;
    debugPrint('Startup initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  runApp(
    NotebookApp(
      startupError: startupError,
      startupStackTrace: startupStackTrace,
    ),
  );
}

class NotebookApp extends StatelessWidget {
  const NotebookApp({super.key, this.startupError, this.startupStackTrace});

  final Object? startupError;
  final StackTrace? startupStackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: startupError == null
          ? const NotesPage()
          : StartupErrorPage(
              error: startupError!,
              stackTrace: startupStackTrace,
            ),
    );
  }
}

class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({required this.error, this.stackTrace, super.key});

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            'The app could not initialize local storage.\n\n$error\n\n${stackTrace ?? ''}',
          ),
        ),
      ),
    );
  }
}

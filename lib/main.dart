import 'package:flutter/material.dart';

import 'app.dart';

/// Entry point.
///
/// Deliberately does almost nothing before [runApp]: the previous version
/// awaited Sentry, dotenv, the database and the on-device Gemma/MediaPipe
/// engine before the first frame, and any failure there (e.g. reading a
/// missing key from the empty CI-generated `token.env`) left the app stuck
/// on the native launch screen forever. All services now initialise lazily,
/// after the UI is already on screen, and none of them can block startup.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TodoApp());
}

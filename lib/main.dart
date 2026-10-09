import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'data/local/local_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!useFakes) await LocalData.init();
  runApp(const ProviderScope(child: App()));
}

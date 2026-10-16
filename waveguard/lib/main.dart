import 'package:flutter/material.dart';
import 'app.dart';
import 'services/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(WaveGuardApp(dependencies: await bootstrap()));
}

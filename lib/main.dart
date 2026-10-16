import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reflexo/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ReflexoApp());
}

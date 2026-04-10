import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const EcoDexApp());
}

class EcoDexApp extends StatelessWidget {
  const EcoDexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoDex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'monospace',
        scaffoldBackgroundColor: const Color(0xFFF0F0C8),
      ),
      home: const LoginScreen(),
    );
  }
}
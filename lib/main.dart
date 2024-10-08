import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auth_app/screens/splash-screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor:
              Color(0xFF808080), // Background color of selected text
          selectionHandleColor:
              Color(0xFF808080), // Color of the selection handles (pins)
        ),
      ),
    );
  }
}

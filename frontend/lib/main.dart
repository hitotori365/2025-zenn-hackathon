import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'views/speech_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(ProviderScope(
    child: SpeechToTextApp(),
  ));
}

class SpeechToTextApp extends StatelessWidget {
  const SpeechToTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech to Text',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SpeechToTextScreen(),
    );
  }
}

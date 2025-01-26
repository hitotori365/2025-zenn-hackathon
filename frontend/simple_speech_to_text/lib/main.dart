import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'speech_provider.dart';

void main() {
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

class SpeechToTextScreen extends ConsumerWidget {
  const SpeechToTextScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 状態を参照するためのインスタンス
    // 状態が変更されるとWidgetが再構築される
    final speechState = ref.watch(speechStateProvider);
    // メソッドにアクセスするためのインスタンス
    final speechNotifier = ref.read(speechStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Speech to Text (Confidence: ${(speechState.confidence * 100).toStringAsFixed(1)}%)',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    speechState.text,
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            FloatingActionButton(
              onPressed: () async {
                speechNotifier.changeMicMode();
              },
              child: Icon(
                speechState.isListening ? Icons.mic : Icons.mic_none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

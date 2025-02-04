import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/speech_provider.dart';

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

class SpeechToTextScreen extends ConsumerStatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  _SpeechToTextScreenState createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends ConsumerState<SpeechToTextScreen> {
  final TextEditingController _messageController = TextEditingController();

  String _generateMessage() {
    return _messageController.text.trim();
  }

  void _clearMessageController() {
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechStateProvider);
    final speechNotifier = ref.read(speechStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Speech to Text',
        ),
        leading: TextButton(
          onPressed: speechNotifier.clearLists,
          child: Text("クリア"),
        ),
      ),
      body: Column(
        children: [
          // チャットリスト
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: speechState.messages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    speechState.messages[index],
                    style: const TextStyle(fontSize: 16.0),
                  ),
                );
              },
            ),
          ),
          // 音声読み取りボタン
          TextButton.icon(
            onPressed: () async {
              // モード切り替え
              speechNotifier.changeMicMode();
            },
            icon: speechState.isListening
                ? Icon(Icons.mic)
                : Icon(Icons.mic_none),
            label:
                speechState.isListening ? Text("音声読み取り終了") : Text("音声読み取り開始"),
          ),
          // テキストフィールド
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: () {
                    String message = _generateMessage();
                    speechNotifier.addLists(message);
                    _clearMessageController();
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

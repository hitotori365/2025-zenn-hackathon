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

class SpeechToTextScreen extends ConsumerStatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  _SpeechToTextScreenState createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends ConsumerState<SpeechToTextScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = []; // List to store chat messages

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add(message); // Add the message to the chat list
      });
      _messageController.clear(); // Clear the input field
    }
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechStateProvider);
    final speechNotifier = ref.read(speechStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Speech to Text (Confidence: ${(speechState.confidence * 100).toStringAsFixed(1)}%)',
        ),
      ),
      body: Column(
        children: [
          // チャットリスト
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _messages[index],
                    style: const TextStyle(fontSize: 16.0),
                  ),
                );
              },
            ),
          ),
          // 音声読み取りボタン
          TextButton.icon(
            onPressed: () async {
              final String text = speechState.text;
              // モード切り替え
              speechNotifier.changeMicMode();
              print("text: $text");
              if (text.isNotEmpty && speechState.isListening) {
                // テキストが入力されていればメッセージに追加
                print("add text");
                _messages.add(text);
              }
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
                  onPressed: _sendMessage,
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

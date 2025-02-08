import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/speech_provider.dart';
import '../utils/message_controller.dart';
import '../utils/scrolling_controller.dart';
import 'chat_list_view.dart';
import 'completion_screen.dart';

class SpeechToTextScreen extends ConsumerStatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  _SpeechToTextScreenState createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends ConsumerState<SpeechToTextScreen> {
  static const int PROGRESS_THRESHOLD = 20;

  @override
  void initState() {
    super.initState();
    final messageController = ref.read(messageControllerProvider.notifier);
    messageController.addListener(() {
      // 入力テキストが変化すると再描画する
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechStateProvider);
    final speechNotifier = ref.read(speechStateProvider.notifier);
    final scrollingController = ref.watch(scrollingControllerProvider.notifier);
    final messageController = ref.read(messageControllerProvider.notifier);
    final inputText = messageController.textEditingController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Text'),
        leading: TextButton(
          onPressed: speechNotifier.clearLists,
          child: const Text("クリア"),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ChatListView(
                scrollingController,
              ),
              TextButton.icon(
                onPressed: speechNotifier.changeMicMode,
                icon:
                    Icon(speechState.isListening ? Icons.mic : Icons.mic_none),
                label: Text(speechState.isListening ? "音声読み取り終了" : "音声読み取り開始"),
              ),
              if (speechState.totalPoints >= PROGRESS_THRESHOLD)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const CompletionScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "もう藁人形には頼らない",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController.textEditingController,
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
                      onPressed: (speechState.isLoading || inputText.isEmpty)
                          ? null
                          : () {
                              String message = messageController.message;
                              speechNotifier.addLists(message);
                              messageController.clearMessage();
                            },
                      backgroundColor:
                          (speechState.isLoading || inputText.isEmpty)
                              ? Colors.grey[300]
                              : Colors.blue,
                      child: Icon(
                        Icons.send,
                        color: (speechState.isLoading || inputText.isEmpty)
                            ? Colors.grey[600]
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (speechState.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

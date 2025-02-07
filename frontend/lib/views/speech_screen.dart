import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/speech_provider.dart';
import '../utils/message_controller.dart';

class SpeechToTextScreen extends ConsumerStatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  _SpeechToTextScreenState createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends ConsumerState<SpeechToTextScreen> {
  /// アプリ進捗の閾値
  static const int PROGRESS_THRESHOLD = 20;

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechStateProvider);
    final speechNotifier = ref.read(speechStateProvider.notifier);
    final messageController = ref.watch(messageControllerProvider.notifier);

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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: speechState.messages.length,
                  itemBuilder: (context, index) {
                    final isUserMessage = index % 2 == 0;
                    return Align(
                      alignment: isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUserMessage
                              ? Colors.blue[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          speechState.messages[index],
                          style: TextStyle(
                            color:
                                isUserMessage ? Colors.black87 : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "呪い終える",
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
                      onPressed: speechState.isLoading
                          ? null
                          : () {
                              String message = messageController.message;
                              speechNotifier.addLists(message);
                              messageController.clearMessage();
                            },
                      child: speechState.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (speechState.isLoading)
            Container(
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

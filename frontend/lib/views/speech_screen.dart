import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/scrolling_controller.dart';
import '../providers/speech_provider.dart';
import 'completion_screen.dart';

class SpeechToTextScreen extends ConsumerStatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  _SpeechToTextScreenState createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends ConsumerState<SpeechToTextScreen> {
  final TextEditingController _messageController = TextEditingController();
  static const int PROGRESS_THRESHOLD = 5;
  bool _hasText = false;

  String _generateMessage() {
    return _messageController.text.trim();
  }

  void _clearMessageController() {
    _messageController.clear();
  }


  @override
  void initState() {
    super.initState();
    // TextEditingControllerにリスナーを追加
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechStateProvider);
    final speechNotifier = ref.read(speechStateProvider.notifier);
    final scrollingController = ref.watch(scrollingControllerProvider.notifier);

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
                  controller: scrollingController.scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: speechState.messages.length,
                  itemBuilder: (context, index) {
                    final isUserMessage = index % 2 == 0;
                    return Align(
                      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUserMessage ? Colors.blue[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          speechState.messages[index],
                          style: TextStyle(
                            color: isUserMessage ? Colors.black87 : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              TextButton.icon(
                onPressed: speechNotifier.changeMicMode,
                icon: Icon(
                    speechState.isListening ? Icons.mic : Icons.mic_none
                ),
                label: Text(
                    speechState.isListening ? "音声読み取り終了" : "音声読み取り開始"
                ),
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
                      onPressed: (speechState.isLoading || _messageController.text.trim().isEmpty)
                          ? null
                          : () {
                        String message = _generateMessage();
                        speechNotifier.addLists(message);
                        _clearMessageController();
                      },
                      backgroundColor: (speechState.isLoading || _messageController.text.trim().isEmpty)
                          ? Colors.grey[300]
                          : Colors.blue,
                      child: Icon(
                        Icons.send,
                        color: (speechState.isLoading || _messageController.text.trim().isEmpty)
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

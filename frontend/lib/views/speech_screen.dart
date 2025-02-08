import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/speech_provider.dart';
import '../utils/message_controller.dart';
import '../utils/scrolling_controller.dart';
import 'chat_list_view.dart';
import 'finish_button_view.dart';
import 'text_field_view.dart';

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
              ChatListView(),
              TextButton.icon(
                onPressed: speechNotifier.changeMicMode,
                icon:
                    Icon(speechState.isListening ? Icons.mic : Icons.mic_none),
                label: Text(speechState.isListening ? "音声読み取り終了" : "音声読み取り開始"),
              ),
              if (speechState.totalPoints >= PROGRESS_THRESHOLD)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: FinishButtonView(),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFieldView(),
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

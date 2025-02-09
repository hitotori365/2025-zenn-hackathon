import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/message_provider.dart';
import '../providers/speech_provider.dart';
import 'chat_list_view.dart';
import 'finish_button_view.dart';
import 'text_field_view.dart';

class SpeechToTextScreen extends ConsumerStatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  _SpeechToTextScreenState createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends ConsumerState<SpeechToTextScreen> {
  static const int progressThreshold = 5;

  @override
  void initState() {
    super.initState();
    final messageController = ref.read(messageProvider.notifier);
    messageController.addListener(() {
      // 入力テキストが変化すると再描画する
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechStateProvider);
    final speechNotifier = ref.read(speechStateProvider.notifier);
    final Color listenButtonColor = speechState.isListening ? Colors.redAccent : Colors.lightGreenAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ワラドール・トーク'),
        leading: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: speechNotifier.resetChat,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background.png'), // 画像ファイルのパス
              fit: BoxFit.contain, // 画像のフィット方法
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  ChatListView(),
                  TextButton.icon(
                    onPressed: speechNotifier.changeMicMode,
                    icon: Icon(
                      speechState.isListening ? Icons.mic : Icons.mic_none,
                      color: listenButtonColor,
                    ),
                    label: Text(
                      speechState.isListening ? "音声読み取り終了" : "音声読み取り開始",
                      style: TextStyle(
                        color: listenButtonColor,
                        fontSize: 16.0,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      side: BorderSide(
                        color: listenButtonColor,
                      ),
                    ),
                  ),
                  if (speechState.totalPoints >= progressThreshold)
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
        ),
      ),
    );
  }
}

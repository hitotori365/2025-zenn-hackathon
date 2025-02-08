import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/message_provider.dart';
import '../providers/speech_provider.dart';

class TextFieldView extends ConsumerWidget {
  const TextFieldView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechStateProvider);
    final speechNotifier = ref.read(speechStateProvider.notifier);
    final messageController = ref.read(messageProvider.notifier);
    final inputText = messageController.textEditingController.text.trim();

    return Row(
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
          backgroundColor: (speechState.isLoading || inputText.isEmpty)
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/scrolling_provider.dart';
import '../providers/speech_provider.dart';

/// チャット一覧
class ChatListView extends ConsumerWidget {
  const ChatListView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechStateProvider);
    final scrollingController = ref.read(scrollingProvider.notifier);

    return Expanded(
      child: ListView.builder(
        controller: scrollingController.scrollController,
        padding: const EdgeInsets.all(8.0),
        itemCount: speechState.messages.length,
        itemBuilder: (context, index) {
          final isUserMessage = index % 2 == 0;
          return Align(
            alignment:
                isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
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
    );
  }
}

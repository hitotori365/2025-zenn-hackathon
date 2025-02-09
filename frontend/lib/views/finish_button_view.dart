import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/next_action_provider.dart';

import 'completion_screen.dart';

/// チャット終了ボタン
class FinishButtonView extends ConsumerWidget {
  const FinishButtonView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // 終了時のアクションを取得
        await ref.read(nextActionProvider.notifier).getNextAction();

        // 完了画面へ遷移
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CompletionScreen(),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 12,
        ),
        side: const BorderSide(
          color: Colors.blue,
        ),
      ),
      child: const Text(
        "もう藁人形には頼らない",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// メッセージ入力用のコントローラを管理するプロバイダー
final messageControllerProvider =
    NotifierProvider<MessageController, String>(MessageController.new);

class MessageController extends Notifier<String> {
  final TextEditingController _textEditingController = TextEditingController();

  /// 初期値（空文字列）
  @override
  String build() {
    return "";
  }

  /// `TextEditingController` へのアクセス
  TextEditingController get textEditingController => _textEditingController;

  /// メッセージを取得（空白削除）
  String get message => _textEditingController.text.trim();

  /// メッセージをクリア
  void clearMessage() {
    _textEditingController.clear();
    state = "";
  }
}

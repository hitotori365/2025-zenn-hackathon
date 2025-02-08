import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// メッセージを管理するコントローラを提供するプロバイダ
final messageProvider =
    NotifierProvider<MessageController, String>(MessageController.new);

/// メッセージを管理するコントローラ
class MessageController extends Notifier<String> {
  final TextEditingController _controller = TextEditingController();

  /// 初期値（空文字列）
  @override
  String build() {
    return "";
  }

  /// `TextEditingController` へのアクセス
  TextEditingController get textEditingController => _controller;

  /// メッセージを取得（空白削除）
  String get message => _controller.text.trim();

  /// メッセージをクリア
  void clearMessage() {
    _controller.clear();
    state = "";
  }

  /// TextEditingControllerにリスナーを追加
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }
}

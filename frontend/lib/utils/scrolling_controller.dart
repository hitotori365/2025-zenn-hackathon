import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scrollingControllerProvider =
    NotifierProvider<ScrollingController, String>(ScrollingController.new);

class ScrollingController extends Notifier<String> {
  /// 初期値（空文字列）
  @override
  String build() {
    return "";
  }

  /// 画面スクロール管理用インスタンス
  final ScrollController scrollController = ScrollController();

  /// 下部までスクロールする
  Future<void> scrollToBottom() async {
    try {
      await Future.delayed(Duration(milliseconds: 200));
      await scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    } catch (error) {
      print(error.toString());
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// speech-to-text を管理するProvider
final _speechProvider = Provider<stt.SpeechToText>((_) {
  return stt.SpeechToText();
});

/// StateとNotifierの両方を提供しアクセス可能にするProvider
///
/// StateへのアクセスとNotifierのメソッドを一つのエントリーポイントで提供する
final speechStateProvider =
    StateNotifierProvider<_SpeechStateNotifier, _SpeechState>((ref) {
  // PeachToTextのインスタンスを取得
  final speech = ref.read(_speechProvider);
  // StateNotifierを生成
  return _SpeechStateNotifier(speech);
});

/// 状態を更新するStateNotifier
///
/// [state]を管理する
class _SpeechStateNotifier extends StateNotifier<_SpeechState> {
  /// speech-to-text機能のインスタンス
  final stt.SpeechToText _speech;

  _SpeechStateNotifier(this._speech) : super(_SpeechState());

  /// マイクボタンがタップされたときの処理
  void changeMicMode() async {
    bool hasInitialized = await _initialize();
    hasInitialized && !state.isListening ? _startListening() : _stopListening();
  }

  /// speech-to-textの初期化
  Future<bool> _initialize() async {
    return await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );
  }

  /// listening開始
  void _startListening() {
    _speech.listen(onResult: (result) {
      // 認識されたテキストと信頼度を更新
      state = state.copyWith(
        text: result.recognizedWords,
        confidence: result.hasConfidenceRating ? result.confidence : 1.0,
      );
    });
    // listening中の状態に更新
    state = state.copyWith(isListening: true);
  }

  /// listening停止
  void _stopListening() {
    _speech.stop();
    // listening停止の状態に更新
    state = state.copyWith(isListening: false);
  }
}

/// データを保持するState
class _SpeechState {
  /// 音声認識中か
  final bool isListening;

  /// 認識されたテキスト
  final String text;

  /// 信頼度
  final double confidence;

  _SpeechState({
    this.isListening = false,
    this.text = 'Press the button and start speaking!',
    this.confidence = 1.0,
  });

  /// 特定のプロパティを更新する新しいStateを返す
  _SpeechState copyWith({
    bool? isAvailable,
    bool? isListening,
    String? text,
    double? confidence,
  }) {
    return _SpeechState(
      isListening: isListening ?? this.isListening,
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
    );
  }
}

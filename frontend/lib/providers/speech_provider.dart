import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/api_service.dart';
import '../utils/scrolling_controller.dart';

final _speechProvider = Provider<stt.SpeechToText>((_) {
  return stt.SpeechToText();
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final speechStateProvider =
    StateNotifierProvider<_SpeechStateNotifier, _SpeechState>((ref) {
  final speech = ref.read(_speechProvider);
  final apiService = ref.read(apiServiceProvider);
  final scrollingController = ref.read(scrollingControllerProvider.notifier);
  return _SpeechStateNotifier(speech, apiService, scrollingController);
});

class _SpeechStateNotifier extends StateNotifier<_SpeechState> {
  final stt.SpeechToText _speech;
  final ApiService _apiService;
  final ScrollingController _scrollingController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  _SpeechStateNotifier(
      this._speech, this._apiService, this._scrollingController)
      : super(_SpeechState());

  void changeMicMode() async {
    bool hasInitialized = await _initialize();
    hasInitialized && !state.isListening ? _startListening() : _stopListening();
  }

  Future<bool> _initialize() async {
    return await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );
  }

  void _startListening() {
    state = state.copyWith(
      isListening: true,
      text: "",
    );

    _speech.listen(onResult: (result) {
      state = state.copyWith(
        text: result.recognizedWords,
        confidence: result.hasConfidenceRating ? result.confidence : 1.0,
      );
    });
  }

  void _stopListening() {
    _speech.stop();
    state = state.copyWith(isListening: false);
    print("stop listening.");

    if (state.text.isNotEmpty) {
      print("add text");
      addLists(state.text);
    }
  }

  Future<void> playAudio(String base64Audio) async {
    try {
      // base64をデコード
      final bytes = base64Decode(base64Audio);

      // Web用の音声再生処理
      final blob = html.Blob([bytes], 'audio/wav');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // AudioPlayerで再生
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      // 使用後にURLを解放
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> addLists(String text) async {
    List<String> messages = state.messages;
    messages.add(text);
    // ローディング開始
    state = state.copyWith(
      messages: messages,
      isLoading: true,
    );
    // 下部までスクロール
      _scrollingController.scrollToBottom();

    try {
      final apiResponse = await _apiService.sendMessage(text);
      print('response: ${apiResponse.response}');
      print('point: ${apiResponse.point}');
      print('progress: ${apiResponse.progress}');

      // メッセージ追加
      messages.add(apiResponse.response);
      // ポイント計算
      final newTotalPoints = state.totalPoints + apiResponse.point;
      print('newTotalPoints: $newTotalPoints');
      // ローディング終了
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        totalPoints: newTotalPoints,
      );
      // 下部までスクロール
      _scrollingController.scrollToBottom();

      // オーディオ再生
      if (apiResponse.audio.isNotEmpty) {
        await playAudio(apiResponse.audio);
      }
    } catch (e) {
      print('Error: $e');
      // エラー時もローディング終了
      state = state.copyWith(isLoading: false);
    }
  }

  void clearLists() {
    state = state.copyWith(
      messages: [],
      isLoading: false,
      totalPoints: 0,
    );
  }
}

class _SpeechState {
  final bool isListening;
  final bool isLoading; // 追加
  final String text;
  final double confidence;
  final List<String> messages;
  final int totalPoints;

  _SpeechState({
    this.isListening = false,
    this.isLoading = false, // 初期値の設定
    this.text = '',
    this.confidence = 1.0,
    List<String>? messages,
    this.totalPoints = 0,
  }) : messages = messages ?? [];

  _SpeechState copyWith({
    bool? isListening,
    bool? isLoading, // 追加
    String? text,
    double? confidence,
    List<String>? messages,
    int? totalPoints,
  }) {
    return _SpeechState(
      isListening: isListening ?? this.isListening,
      isLoading: isLoading ?? this.isLoading, // 追加
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      messages: messages ?? this.messages,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

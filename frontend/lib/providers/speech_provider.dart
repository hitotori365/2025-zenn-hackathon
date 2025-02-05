import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/api_service.dart';

final _speechProvider = Provider<stt.SpeechToText>((_) {
  return stt.SpeechToText();
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final speechStateProvider =
    StateNotifierProvider<_SpeechStateNotifier, _SpeechState>((ref) {
  final speech = ref.read(_speechProvider);
  final apiService = ref.read(apiServiceProvider);
  return _SpeechStateNotifier(speech, apiService);
});

class _SpeechStateNotifier extends StateNotifier<_SpeechState> {
  final stt.SpeechToText _speech;
  final ApiService _apiService;

  _SpeechStateNotifier(this._speech, this._apiService) : super(_SpeechState());

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

  Future<void> addLists(String text) async {
    List<String> messages = state.messages;
    messages.add(text);
    state = state.copyWith(messages: messages);

    try {
      final apiResponse = await _apiService.sendMessage(text);
      print('response: ${apiResponse.response}');
      print('point: ${apiResponse.point}');
      print('progress: ${apiResponse.progress}');

      messages.add(apiResponse.response);
      state = state.copyWith(messages: messages);
    } catch (e) {
      print('Error: $e');
    }
  }

  void clearLists() {
    state = state.copyWith(messages: []);
  }
}

class _SpeechState {
  final bool isListening;
  final String text;
  final double confidence;
  final List<String> messages;

  _SpeechState({
    this.isListening = false,
    this.text = '',
    this.confidence = 1.0,
    List<String>? messages,
  }) : messages = messages ?? [];

  _SpeechState copyWith({
    bool? isListening,
    String? text,
    double? confidence,
    List<String>? messages,
  }) {
    return _SpeechState(
      isListening: isListening ?? this.isListening,
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      messages: messages ?? this.messages,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// APIレスポンスの状態を管理するStateクラス
class NextActionState {
  final String? action;
  final String? reason;
  final bool isLoading;

  NextActionState({
    this.action,
    this.reason,
    this.isLoading = false,
  });

  NextActionState copyWith({
    String? action,
    String? reason,
    bool? isLoading,
  }) {
    return NextActionState(
      action: action ?? this.action,
      reason: reason ?? this.reason,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// StateNotifierの実装
class NextActionStateNotifier extends StateNotifier<NextActionState> {
  final ApiService _apiService;

  NextActionStateNotifier(this._apiService) : super(NextActionState());

  Future<void> getNextAction() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiService.sendActionRequest();
      state = state.copyWith(
        action: response.action,
        reason: response.reason,
        isLoading: false,
      );
    } catch (e) {
      print('Error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void reset() {
    state = NextActionState();
    _apiService.resetMessageHistory();
  }
}

// Providerの定義
final nextActionProvider = StateNotifierProvider<NextActionStateNotifier, NextActionState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return NextActionStateNotifier(apiService);
});

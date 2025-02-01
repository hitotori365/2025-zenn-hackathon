import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiResponse {
  final String response;
  final int point;

  ApiResponse({required this.response, required this.point});
}

class ApiService {
  List<Map<String, dynamic>> messageHistory = [];
  final String _token = dotenv.env['API_TOKEN']!;

  Future<ApiResponse> sendMessage(String message) async {

    // ユーザーメッセージを追加
    final userMessage = {
      'role': 'user',
      'content': message
    };
    messageHistory.add(userMessage);

    final response = await http.post(
      Uri.parse('https://my-app-service-132373106783.asia-northeast1.run.app/chat'),
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'messages': messageHistory.map((m) => {
          'role': m['role'],
          'content': m['content']
        }).toList()
      }),
    );

    if (response.statusCode == 200) {
      final decodedResponse = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedResponse);
      final assistantMessage = {
        'role': 'assistant',
        'content': data['response']
      };
      messageHistory.add(assistantMessage);

      return ApiResponse(response: data['response'], point: data['point']);
    }
    throw Exception('API failed');
  }
}

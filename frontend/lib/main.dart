import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Audio Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AudioChatScreen(),
    );
  }
}

class AudioChatScreen extends StatefulWidget {
  const AudioChatScreen({Key? key}) : super(key: key);

  @override
  _AudioChatScreenState createState() => _AudioChatScreenState();
}

class _AudioChatScreenState extends State<AudioChatScreen> {
  late WebSocketChannel channel;
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  String _transcription = '';
  static const int SAMPLE_RATE = 16000;
  static const int CHUNK_SIZE = 1600;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _connectWebSocket();
  }

  Future<void> _initializeAudio() async {
    // マイク権限の要求
    await Permission.microphone.request();

    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  void _connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws'),
    );

    channel.stream.listen(
      (message) {
        _handleServerMessage(message);
      },
      onError: (error) => print('Error: $error'),
      onDone: () => print('WebSocket connection closed'),
    );
  }

  Future<void> _handleServerMessage(dynamic message) async {
    try {
      final data = jsonDecode(message);
      setState(() {
        _transcription = data['transcript'];
      });

      if (data['is_final'] && data.containsKey('audio')) {
        final audioBytes = base64Decode(data['audio']);
        await _playAudio(audioBytes);
      }
    } catch (e) {
      print('Error handling server message: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecording) {
      setState(() => _isRecording = true);

      await _recorder!.startRecorder(
        toFile: 'temp.wav',  // 一時ファイルとして保存
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: SAMPLE_RATE,
      );

      _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );

      _recorder!.onProgress!.listen((event) async {
        // ここで録音データを取得して送信
        if (_isRecording) {
          // 固定長のデータを生成（実際のデータ取得方法は環境によって異なる場合があります）
          List<int> dummyData = List.filled(CHUNK_SIZE, 0);
          final base64Audio = base64Encode(dummyData);
          channel.sink.add(base64Audio);
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _recorder!.stopRecorder();
      setState(() => _isRecording = false);
    }
  }

  Future<void> _playAudio(List<int> audioBytes) async {
    try {
      await _player!.startPlayer(
        fromDataBuffer: Uint8List.fromList(audioBytes),
        codec: Codec.pcm16,
        sampleRate: SAMPLE_RATE,
        numChannels: 1,
      );
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Audio Chat'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Transcription: $_transcription',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
          ],
        ),
      ),
    );
  }
}
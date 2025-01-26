class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketChannel channel;
  bool isRecording = false;
  late html.MediaStream audioStream;
  late html.MediaRecorder mediaRecorder;
  final List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    connectWebSocket();
    initializeAudio();
  }

  void connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws'),
    );
    
    channel.stream.listen(
      (message) {
        handleServerMessage(message);
      },
      onError: (error) => print('Error: $error'),
      onDone: () => print('WebSocket connection closed'),
    );
  }

  Future<void> initializeAudio() async {
    try {
      audioStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'audio': true,
      });
      
      mediaRecorder = html.MediaRecorder(audioStream);
      mediaRecorder.addEventListener('dataavailable', (event) {
        final blob = (event as html.BlobEvent).data;
        // Convert blob to base64 and send to server
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        reader.onLoadEnd.listen((event) {
          final base64Data = base64Encode(reader.result as List<int>);
          channel.sink.add(base64Data);
        });
      });
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  void handleServerMessage(String message) {
    try {
      final data = jsonDecode(message);
      setState(() {
        messages.add(data);
      });
      
      if (data['audio'] != null) {
        playAudioResponse(data['audio']);
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void toggleRecording() {
    setState(() {
      isRecording = !isRecording;
      if (isRecording) {
        mediaRecorder.start(100); // Start recording with 100ms timeslice
      } else {
        mediaRecorder.stop();
      }
    });
  }

  Future<void> playAudioResponse(String base64Audio) async {
    // Implement audio playback logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Client'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  title: Text(message['transcript'] ?? ''),
                  subtitle: message['is_final'] 
                    ? const Text('Final') 
                    : const Text('Interim'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: toggleRecording,
              child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    audioStream.getTracks().forEach((track) => track.stop());
    super.dispose();
  }
}
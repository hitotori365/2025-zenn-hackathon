import asyncio
import base64
import pyaudio
import websockets
import json
import signal
import sys

CHUNK_SIZE = 1600  # 100ms of audio at 16kHz
SAMPLE_RATE = 16000
FORMAT = pyaudio.paInt16
CHANNELS = 1

class AudioClient:
    def __init__(self, websocket_url="ws://localhost:8000/ws"):
        self.websocket_url = websocket_url
        self.audio = pyaudio.PyAudio()
        self.stream = None
        self.is_running = False

    def start_audio_stream(self):
        self.stream = self.audio.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=SAMPLE_RATE,
            input=True,
            frames_per_buffer=CHUNK_SIZE
        )
        self.is_running = True
        print("Audio stream started")

    def stop_audio_stream(self):
        self.is_running = False
        if self.stream:
            self.stream.stop_stream()
            self.stream.close()
        if self.audio:
            self.audio.terminate()
        print("Audio stream stopped")

    async def run(self):
        try:
            async with websockets.connect(self.websocket_url) as websocket:
                print("Connected to WebSocket server")
                self.start_audio_stream()

                while self.is_running:
                    # 音声データの読み取りと送信
                    audio_data = self.stream.read(CHUNK_SIZE, exception_on_overflow=False)
                    if audio_data:
                        # Base64エンコードして送信
                        audio_base64 = base64.b64encode(audio_data).decode('utf-8')
                        await websocket.send(audio_base64)

                    try:
                        # 非ブロッキングで結果を受信
                        response = await asyncio.wait_for(websocket.recv(), timeout=0.1)
                        result = json.loads(response)
                        if result["is_final"]:
                            print(f"\nFinal: {result['transcript']}")
                        else:
                            print(f"Interim: {result['transcript']}", end='\r')
                    except asyncio.TimeoutError:
                        continue
                    except Exception as e:
                        print(f"Error receiving response: {e}")
                        break

        except Exception as e:
            print(f"Connection error: {e}")
        finally:
            self.stop_audio_stream()

    def signal_handler(self, sig, frame):
        print("\nStopping client...")
        self.is_running = False

def main():
    client = AudioClient()
    signal.signal(signal.SIGINT, client.signal_handler)
    print("Starting audio client... Press Ctrl+C to exit")
    
    asyncio.get_event_loop().run_until_complete(client.run())

if __name__ == "__main__":
    main()
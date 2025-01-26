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
        self.input_stream = None
        self.output_stream = None
        self.is_running = False

    def start_audio_stream(self):
        # input_streamとして初期化
        self.input_stream = self.audio.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=SAMPLE_RATE,
            input=True,
            frames_per_buffer=CHUNK_SIZE
        )

        # output_streamの初期化
        self.output_stream = self.audio.open(
            format=FORMAT,
            channels=CHANNELS,
            rate=SAMPLE_RATE,
            output=True,
            frames_per_buffer=CHUNK_SIZE
        )

        self.is_running = True
        print("Audio streams started")

    def stop_audio_stream(self):
        self.is_running = False
        if self.input_stream:
            try:
                self.input_stream.stop_stream()
                self.input_stream.close()
            except Exception as e:
                print(f"Error closing input stream: {e}")

        if self.output_stream:
            try:
                self.output_stream.stop_stream()
                self.output_stream.close()
            except Exception as e:
                print(f"Error closing output stream: {e}")

        if self.audio:
            try:
                self.audio.terminate()
            except Exception as e:
                print(f"Error terminating audio: {e}")

        print("Audio streams stopped")

    async def run(self):
        try:
            async with websockets.connect(self.websocket_url) as websocket:
                print("Connected to WebSocket server")
                self.start_audio_stream()

                while self.is_running:
                    try:
                        # 音声データの読み取りと送信
                        audio_data = self.input_stream.read(CHUNK_SIZE, exception_on_overflow=False)
                        if audio_data:
                            print(f"\nSending audio data length: {len(audio_data)}")
                            print(f"First 10 bytes of audio data: {audio_data[:10]}")
                            audio_base64 = base64.b64encode(audio_data).decode('utf-8')
                            print(f"Base64 encoded length: {len(audio_base64)}")
                            print(f"First 100 chars of base64: {audio_base64[:100]}")
                            await websocket.send(audio_base64)

                        # サーバーからのレスポンスを受信
                        try:
                            response = await asyncio.wait_for(websocket.recv(), timeout=0.1)
                            result = json.loads(response)
                            
                            if result["is_final"]:
                                print(f"\nFinal: {result['transcript']}")
                                # 音声データが含まれている場合は再生
                                if "audio" in result:
                                    audio_data = base64.b64decode(result["audio"])
                                    self.output_stream.write(audio_data)
                            else:
                                print(f"Interim: {result['transcript']}", end='\r')
                                
                        except asyncio.TimeoutError:
                            continue
                        except Exception as e:
                            print(f"Error receiving response: {e}")
                            break

                    except Exception as e:
                        print(f"Error processing audio: {e}")
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
    
    try:
        asyncio.get_event_loop().run_until_complete(client.run())
    except KeyboardInterrupt:
        print("\nStopped by user")
    except Exception as e:
        print(f"Error in main: {e}")

if __name__ == "__main__":
    main()
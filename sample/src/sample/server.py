from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import base64
from google.cloud import speech, texttospeech
import uvicorn
import signal
import sys
from typing import Generator

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SAMPLE_RATE = 16000
CHUNK_SIZE = int(SAMPLE_RATE / 10)

class AudioBuffer:
    def __init__(self):
        self.buffer = []
        self.is_closed = False

    def add_data(self, data: bytes):
        self.buffer.append(data)

    def get_data(self) -> Generator[bytes, None, None]:
        while self.buffer:
            yield self.buffer.pop(0)

def create_streaming_config():
    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=SAMPLE_RATE,
        language_code="ja-JP",
        max_alternatives=1,
    )
    return speech.StreamingRecognitionConfig(
        config=config, interim_results=True
    )

def text_to_speech(text: str) -> bytes:
    """テキストを音声に変換する"""
    client = texttospeech.TextToSpeechClient()
    
    synthesis_input = texttospeech.SynthesisInput(text=text)
    
    voice = texttospeech.VoiceSelectionParams(
        language_code="ja-JP",
        name="ja-JP-Standard-C",  # 音声の種類を選択
        ssml_gender=texttospeech.SsmlVoiceGender.NEUTRAL
    )
    
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.LINEAR16,
        sample_rate_hertz=SAMPLE_RATE
    )
    
    response = client.synthesize_speech(
        input=synthesis_input,
        voice=voice,
        audio_config=audio_config
    )
    
    return response.audio_content

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("Connection opened")

    speech_client = speech.SpeechClient()
    streaming_config = create_streaming_config()
    audio_buffer = AudioBuffer()

    async def process_audio():
        while not audio_buffer.is_closed:
            if audio_buffer.buffer:
                requests = (
                    speech.StreamingRecognizeRequest(audio_content=content)
                    for content in audio_buffer.get_data()
                )
                try:
                    responses = speech_client.streaming_recognize(streaming_config, requests)
                    for response in responses:
                        if not response.results:
                            continue
                        result = response.results[0]
                        if not result.alternatives:
                            continue
                        
                        transcript = result.alternatives[0].transcript
                        is_final = result.is_final
                        
                        print(f"Recognized: {transcript}")
                        
                        # 最終結果の場合のみ音声合成を実行
                        if is_final:
                            try:
                                audio_response = text_to_speech(transcript)
                                audio_base64 = base64.b64encode(audio_response).decode('utf-8')
                                
                                await websocket.send_json({
                                    "transcript": transcript,
                                    "is_final": is_final,
                                    "audio": audio_base64
                                })
                            except Exception as e:
                                print(f"Text-to-speech error: {e}")
                        else:
                            # 中間結果は従来通りテキストのみ送信
                            await websocket.send_json({
                                "transcript": transcript,
                                "is_final": is_final
                            })
                            
                except Exception as e:
                    print(f"Recognition error: {e}")
            await asyncio.sleep(0.1)

    try:
        audio_process_task = asyncio.create_task(process_audio())
        
        while True:
            try:
                data = await websocket.receive_text()
                audio_data = base64.b64decode(data)
                audio_buffer.add_data(audio_data)
            except Exception as e:
                print(f"Error receiving data: {e}")
                break

    except Exception as e:
        print(f"Connection error: {e}")
    finally:
        audio_buffer.is_closed = True
        if 'audio_process_task' in locals():
            audio_process_task.cancel()
        print("Connection closed")

def signal_handler(sig, frame):
    print("\nShutting down server...")
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    
    config = uvicorn.Config(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
    server = uvicorn.Server(config)
    
    try:
        server.run()
    except KeyboardInterrupt:
        print("\nServer stopped by user")
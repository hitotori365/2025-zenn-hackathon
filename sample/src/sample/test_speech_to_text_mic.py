# test_speech_to_text_mic.py
import pyaudio
import wave
from google.cloud import speech
import os

def record_audio(filename, duration=5):
    """マイクから音声を録音する"""
    CHUNK = 1024
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    RATE = 16000

    p = pyaudio.PyAudio()

    print(f"{duration}秒間の録音を開始します...")

    stream = p.open(format=FORMAT,
                    channels=CHANNELS,
                    rate=RATE,
                    input=True,
                    frames_per_buffer=CHUNK)

    frames = []

    for i in range(0, int(RATE / CHUNK * duration)):
        data = stream.read(CHUNK)
        frames.append(data)

    print("録音終了")

    stream.stop_stream()
    stream.close()
    p.terminate()

    # WAVファイルとして保存
    wf = wave.open(filename, 'wb')
    wf.setnchannels(CHANNELS)
    wf.setsampwidth(p.get_sample_size(FORMAT))
    wf.setframerate(RATE)
    wf.writeframes(b''.join(frames))
    wf.close()

def transcribe_file(speech_file):
    """音声ファイルから文字起こしを行う"""
    client = speech.SpeechClient()

    with open(speech_file, "rb") as audio_file:
        content = audio_file.read()

    audio = speech.RecognitionAudio(content=content)
    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=16000,
        language_code="ja-JP",
    )

    response = client.recognize(config=config, audio=audio)

    for result in response.results:
        print("認識結果: {}".format(result.alternatives[0].transcript))
        print("信頼度: {}".format(result.alternatives[0].confidence))

if __name__ == "__main__":
    # 環境変数の確認
    print(f"認証ファイル: {os.getenv('GOOGLE_APPLICATION_CREDENTIALS')}")
    
    # 録音とテスト
    filename = "test_recording.wav"
    record_audio(filename, duration=5)
    transcribe_file(filename)
    
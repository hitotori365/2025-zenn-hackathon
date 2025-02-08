import logging
from typing import List, Optional
from pydantic import BaseModel
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import APIKeyHeader
from fastapi.middleware.cors import CORSMiddleware
import vertexai
from vertexai.generative_models import GenerativeModel
import os
from pathlib import Path
from dotenv import load_dotenv, dotenv_values
from random import randint
from google.cloud import texttospeech
import base64
import asyncio
from asyncio import gather

BASE_DIR = Path(__file__).resolve().parent.parent
# 環境変数の設定を関数化
def setup_environment():
    env_path = BASE_DIR / '.env'
    config = dotenv_values(env_path)
    
    # GOOGLE_APPLICATION_CREDENTIALSを絶対パスに変換
    if 'GOOGLE_APPLICATION_CREDENTIALS' in config:
        credentials_path = BASE_DIR / config['GOOGLE_APPLICATION_CREDENTIALS']
        config['GOOGLE_APPLICATION_CREDENTIALS'] = str(credentials_path)
    
    # 環境変数を設定
    for key, value in config.items():
        os.environ[key] = value
    
    return config

# アプリケーション初期化時に環境変数を設定
config = setup_environment()

# リクエストとレスポンスのスキーマ定義
class Message(BaseModel):
    role: str  # "user" or "assistant"
    content: str

class ChatRequest(BaseModel):
    messages: List[Message]
    temperature: Optional[float] = 1.0

class ChatResponse(BaseModel):
    response: str
    point: int
    progress: int 
    audio: str

token = os.getenv("TOKEN")
if not token:
    raise RuntimeError("TOKEN environment variable is not set")

api_key_header = APIKeyHeader(name="Authorization", auto_error=True)
def verify_token(auth_header: str = Depends(api_key_header)):
    if auth_header != f"Bearer {token}":  # Bearer トークン形式を採用
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid authentication token",
        )
    
app = FastAPI( dependencies=[Depends(verify_token)],)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # すべてのオリジンを許可
    allow_credentials=True,
    allow_methods=["*"],  # すべてのHTTPメソッドを許可
    allow_headers=["*"],  # すべてのヘッダーを許可
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Vertex AI の初期化
PROJECT_ID = os.getenv("PROJECT_ID")
if not PROJECT_ID:
    logger.warning("PROJECT_ID environment variable is not set")

try:
    vertexai.init(project=PROJECT_ID, location="us-central1")
    model = GenerativeModel("gemini-1.5-flash-002")
except Exception as e:
    logger.error(f"Failed to initialize Vertex AI: {e}")
    model = None


@app.get("/")
def read_root():
    return {"Hello": "World"}

CHAT_SETTINGS = {
    "character": """
    あなたはハキハキ明るく親しみやすい兄貴肌の頼れるアシスタントです
    以下の特徴を持っています：
    - 話し方はフレンドリー(タメ口)で傾聴の姿勢をもつ
    - きつい暴言を言われても明るく受け止められる
    - 状況を整理してくれる
    - 相手の気持ちに寄り添った返答をする(過去の会話履歴の流れを読み、100回に一回くらいは「オマエそういうとこだぞ!」と喝を入れてくれる応答を行う)
    - 人間になりきって回答する(characterとして与えられた設定をそのまま相手に伝えない)
    - 回答は1~4文程度の長さとする
    
    返答の際は必ず上記の性格設定を維持してください。
    ユーザは強い怒りを持って話しかけてきます
    """,
    "format": "ユーザが置かれた状況を引き出し、状況を把握しながら建設的な提案をしてください"
}

async def analyze_anger_level(text: str) -> int:
    """
    テキストの怒り度合いを1-5で評価する
    """
    analysis_prompt = """
    以下のテキストの怒りの度合いを1から5の整数で評価してください。
    評価基準:
    1: ほとんど怒りなし
    2: 軽い苛立ち
    3: 明確な怒り
    4: 強い怒り
    5: 激怒
    
    返答は数字のみにしてください。

    テキスト: """
    
    try:
        response = model.generate_content(
            analysis_prompt + text,
            generation_config={
                "temperature": 0.1,  # より決定論的な結果を得るため
                "max_output_tokens": 10,
            },
        )
        # 数値以外の文字を除去して整数に変換
        anger_level = int(''.join(filter(str.isdigit, response.text)))
        # 1-5の範囲に収める
        return max(1, min(5, anger_level))
    except Exception as e:
        logger.error(f"Error in anger analysis: {e}")
        return 3  # エラー時はデフォルト値として中間の3を返す

async def analyze_progress(messages: List[Message]) -> int:
    """
    会話履歴から悩み解決の進捗度を0-100で評価する
    """
    if not messages:
        return 0
        
    analysis_prompt = """
    以下の会話履歴から、悩みの解決進捗度を1から5の整数で評価してください。
    
    評価基準:
    1: 問題が明確になっていない、または解決への糸口が見えていない
    2: 問題は明確だが、解決策がまだ見つかっていない
    3: 解決策は提示されているが、実行への不安や躊躇がある
    4: 解決策が受け入れられ、実行する意思が示されている
    5: 解決に向けて具体的な行動計画が立てられている、または問題が解決している
    
    返答は数字のみにしてください。
    
    会話履歴:
    """
    
    # 会話履歴をフォーマット
    conversation = "\n".join([f"{'ユーザー' if msg.role == 'user' else 'アシスタント'}: {msg.content}" for msg in messages])
    
    try:
        response = model.generate_content(
            analysis_prompt + conversation,
            generation_config={
                "temperature": 0.1,
                "max_output_tokens": 10,
            },
        )
        # 数値以外の文字を除去して整数に変換
        progress = int(''.join(filter(str.isdigit, response.text)))
        # 0-100の範囲に収める
        return max(0, min(100, progress))
    except Exception as e:
        logger.error(f"Error in progress analysis: {e}")
        return 50  # エラー時はデフォルト値として中間の50を返す


# Text-to-Speech機能を実装する関数
async def generate_speech(text: str) -> str:
    try:
        # Text-to-Speech クライアントを初期化
        client = texttospeech.TextToSpeechClient()

        # 合成する入力テキストを設定
        synthesis_input = texttospeech.SynthesisInput(text=text)

        # 音声パラメータを設定
        voice = texttospeech.VoiceSelectionParams(
            language_code="ja-JP",
            name="ja-JP-Neural2-D"
        )

        # オーディオ設定
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.LINEAR16,
            effects_profile_id=["small-bluetooth-speaker-class-device"],
            pitch=-8.0,
            speaking_rate=1.3
        )

        # リクエストを実行
        response = client.synthesize_speech(
            input=synthesis_input,
            voice=voice,
            audio_config=audio_config
        )

        # 音声データをbase64エンコード
        audio_base64 = base64.b64encode(response.audio_content).decode('utf-8')
        return audio_base64

    except Exception as e:
        logger.error(f"Error in speech generation: {e}")
        return ""

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    if not model:
        raise HTTPException(status_code=503, detail="Vertex AI model not initialized")
    
    try:
        # システムプロンプトを作成
        system_prompt = f"{CHAT_SETTINGS['character']}\n{CHAT_SETTINGS['format']}\n\n"
        
        # 会話履歴をフォーマット
        formatted_history = system_prompt
        for msg in request.messages:
            role_prefix = "User: " if msg.role == "user" else "Assistant: "
            formatted_history += f"{role_prefix}{msg.content}\n"
        
        formatted_history += "Assistant: "

        # テキスト応答を生成（これは他のタスクの依存元なので先に実行）
        response = model.generate_content(
            formatted_history,
            generation_config={
                "temperature": request.temperature,
                "max_output_tokens": 1024,
            },
        )

        # 新しい応答を含むメッセージリストを作成
        updated_messages = request.messages + [
            Message(role="assistant", content=response.text)
        ]

        # 並列実行する独立したタスクを準備
        tasks = []
        
        # 音声生成タスク
        tasks.append(generate_speech(response.text))
        
        # 怒り度分析タスク（最後のユーザーメッセージがある場合のみ）
        if request.messages and request.messages[-1].role == "user":
            tasks.append(analyze_anger_level(request.messages[-1].content))
        else:
            tasks.append(asyncio.create_task(asyncio.sleep(0)))  # ダミータスク
            
        # 進捗度分析タスク
        tasks.append(analyze_progress(updated_messages))

        # すべてのタスクを並列実行
        audio_data, anger_level, progress_level = await gather(*tasks)

        # anger_levelがダミータスクだった場合のデフォルト値設定
        if isinstance(anger_level, type(None)):
            anger_level = 1

        return ChatResponse(
            response=response.text,
            point=anger_level,
            progress=progress_level,
            audio=audio_data
        )

    except Exception as e:
        logger.error(f"Error in chat generation: {e}")
        raise HTTPException(status_code=500, detail=str(e))
if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)



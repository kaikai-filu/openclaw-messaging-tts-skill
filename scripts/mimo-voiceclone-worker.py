#!/usr/bin/env python3
"""
MiMo VoiceClone TTS Worker

从环境变量读取参考音频和文本，调用 MiMo 语音克隆 API，
返回克隆人声的 mp3 文件。

环境变量:
  OUTPUT_PATH      — 输出 mp3 文件路径
  TEXT             — 要朗读的文本
  API_KEY          — MiMo API key
  API_URL          — MiMo API 端点（默认 mimo-v2.5-tts-voiceclone）
  REFERENCE_AUDIO — 参考音频文件路径（mp3）
  FORMAT           — 输出格式（默认 mp3）
"""

import json
import base64
import urllib.request
import ssl
import sys
import os

output_path = os.environ["OUTPUT_PATH"]
text = os.environ["TEXT"]
api_key = os.environ["API_KEY"]
api_url = os.environ["API_URL"]
reference_audio = os.environ["REFERENCE_AUDIO"]
fmt = os.environ.get("FORMAT", "mp3")

with open(reference_audio, "rb") as f:
    b64 = base64.b64encode(f.read()).decode()

data_url = f"data:audio/mp3;base64,{b64}"

payload = json.dumps({
    "model": "mimo-v2.5-tts-voiceclone",
    "messages": [{"role": "assistant", "content": text}],
    "audio": {"format": fmt, "voice": data_url}
}).encode()

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

req = urllib.request.Request(api_url, data=payload, headers={
    "api-key": api_key,
    "Content-Type": "application/json"
})

resp = urllib.request.urlopen(req, context=ctx, timeout=60)
result = json.loads(resp.read())

audio_data = result.get("choices", [{}])[0].get("message", {}).get("audio", {}).get("data", "")
if not audio_data:
    err = result.get("error", {})
    print(f"Error: {err}", file=sys.stderr)
    sys.exit(1)

audio_bytes = base64.b64decode(audio_data)
with open(output_path, "wb") as f:
    f.write(audio_bytes)

print(f"Saved: {output_path} ({len(audio_bytes)} bytes)")

#!/usr/bin/env python3
"""
TTS Router Worker — 智能选择 TTS 提供商。

路由逻辑：
  MIMO_API_KEY 存在 → 尝试 MiMo 白桦男声 TTS
    ├── 有参考音频 → VoiceClone 模式
    └── 失败 → Edge TTS 兜底
  MIMO_API_KEY 不存在/失败 → Edge TTS 兜底

环境变量:
  OUTPUT_PATH    — 输出音频文件路径
  TEXT           — 要朗读的文本
  MIMO_API_KEY   — MiMo API Key（可选）
  MIMO_API_URL   — MiMo API 端点
  REFERENCE_AUDIO — 参考音频路径（可选，用于克隆）
  TTS_VOICE      — MiMo TTS 音色（默认 白桦）
  EDGE_TTS_VOICE — Edge TTS 音色（默认 zh-CN-YunxiNeural）
"""
import json
import base64
import urllib.request
import ssl
import sys
import os
import subprocess

output_path = os.environ["OUTPUT_PATH"]
text = os.environ["TEXT"]
api_key = os.environ.get("MIMO_API_KEY", "")
api_url = os.environ.get("MIMO_API_URL",
    "https://token-plan-cn.xiaomimimo.com/v1/chat/completions")
ref_audio = os.environ.get("REFERENCE_AUDIO",
    "/Users/yzy/.openclaw/scripts/reference-voice.mp3")
voice = os.environ.get("TTS_VOICE", "白桦")
edge_voice = os.environ.get("EDGE_TTS_VOICE", "zh-CN-YunxiNeural")


def try_mimo() -> bool:
    """尝试 MiMo TTS，返回是否成功。"""
    if not api_key:
        return False

    # 构建 audio 参数
    # 走 MiMo 标准 TTS（指定音色），不走克隆避免参考音频过大被拒
    audio_arg = {"format": "mp3", "voice": voice}

    payload = json.dumps({
        "model": "mimo-v2.5-tts",
        "messages": [{"role": "assistant", "content": text}],
        "audio": audio_arg
    }).encode()

    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    req = urllib.request.Request(api_url, data=payload, headers={
        "api-key": api_key,
        "Content-Type": "application/json"
    })

    try:
        resp = urllib.request.urlopen(req, context=ctx, timeout=30)
        result = json.loads(resp.read())
        audio_data = result.get("choices", [{}])[0].get("message",
            {}).get("audio", {}).get("data", "")
        if audio_data:
            with open(output_path, "wb") as f:
                f.write(base64.b64decode(audio_data))
            return True
    except Exception as e:
        print(f"MiMo TTS failed: {e}", file=sys.stderr)

    return False


def try_edge() -> bool:
    """尝试 Edge TTS，返回是否成功。"""
    try:
        subprocess.run(
            ["edge-tts", "--text", text, "--voice", edge_voice,
             "--write-media", output_path],
            capture_output=True, timeout=30, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Edge TTS failed: {e}", file=sys.stderr)
    return False


def main():
    if try_mimo():
        size = os.path.getsize(output_path)
        print(f"Used MiMo TTS (voice: {voice}), {size} bytes")
        sys.exit(0)

    if try_edge():
        size = os.path.getsize(output_path)
        print(f"Used Edge TTS (voice: {edge_voice}), {size} bytes")
        sys.exit(0)

    print("Error: all TTS providers failed", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()

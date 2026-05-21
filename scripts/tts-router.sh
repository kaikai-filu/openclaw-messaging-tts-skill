#!/bin/bash
# OpenClaw TTS Router
# 智能选择 TTS 提供商：
#   1. 有 MIMO_API_KEY → MiMo 白桦男声 TTS（有参考音频则克隆）
#   2. MiMo 失败/没 key → Edge TTS 兜底
#
# 用法：tts-router.sh <output_path> <text>

set -e
OUTPUT_PATH="$1"
TEXT="$2"

if [ -z "$OUTPUT_PATH" ] || [ -z "$TEXT" ]; then
  echo "Usage: $0 <output_path> <text>" >&2
  exit 1
fi

# 读取 MiMo API Key：环境变量 > openclaw.json > 空
MIMO_API_KEY="${MIMO_API_KEY:-}"
if [ -z "$MIMO_API_KEY" ] && [ -f "$HOME/.openclaw/openclaw.json" ]; then
  MIMO_API_KEY=$(python3 -c "
import json
with open('$HOME/.openclaw/openclaw.json') as f:
    cfg = json.load(f)
print(cfg.get('messages',{}).get('tts',{}).get('providers',{}).get('xiaomi',{}).get('apiKey','') or '')
" 2>/dev/null)
fi

export OUTPUT_PATH TEXT MIMO_API_KEY
export MIMO_API_URL="${MIMO_API_URL:-https://token-plan-cn.xiaomimimo.com/v1/chat/completions}"
export REFERENCE_AUDIO="${REFERENCE_AUDIO:-/Users/yzy/.openclaw/scripts/reference-voice.mp3}"
export TTS_VOICE="${TTS_VOICE:-白桦}"
export EDGE_TTS_VOICE="${EDGE_TTS_VOICE:-zh-CN-YunxiNeural}"

# 委托 Python 路由器
exec python3 "$(dirname "$0")/tts-router-worker.py"

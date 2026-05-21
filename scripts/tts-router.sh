#!/bin/bash
# OpenClaw TTS Router
# 智能选择 TTS 提供商：
#   1. 如果有 MIMO_API_KEY 且有参考音频 → MiMo 白桦男声 TTS
#   2. 如果有 MIMO_API_KEY 但没参考音频 → MiMo 白桦男声 TTS（普通模式，不克隆）
#   3. 如果 MiMo 调用失败或没 key → Edge TTS 兜底
#
# 用法：tts-router.sh <output_path> <text>

set -e

OUTPUT_PATH="$1"
TEXT="$2"

if [ -z "$OUTPUT_PATH" ] || [ -z "$TEXT" ]; then
  echo "Usage: $0 <output_path> <text>"
  exit 1
fi

MIMO_API_KEY="${MIMO_API_KEY:-}"
MIMO_API_URL="${MIMO_API_URL:-https://token-plan-cn.xiaomimimo.com/v1/chat/completions}"
REFERENCE_AUDIO="${REFERENCE_AUDIO:-/Users/yzy/.openclaw/scripts/reference-voice.mp3}"
VOICE="${TTS_VOICE:-白桦}"

# ----- MiMo TTS 模式 -----
try_mimo() {
  local out="$1" txt="$2"

  # 构建音频参数
  local audio_arg="{\"format\": \"mp3\", \"voice\": \"$VOICE\"}"

  # 如果有参考音频，走克隆模式
  if [ -f "$REFERENCE_AUDIO" ]; then
    local b64
    b64=$(base64 < "$REFERENCE_AUDIO" | tr -d '\n')
    audio_arg="{\"format\": \"mp3\", \"voice\": \"data:audio/mp3;base64,$b64\"}"
  fi

  # 构建请求体
  local payload
  payload=$(cat <<EOF
{
  "model": "mimo-v2.5-tts",
  "messages": [{"role": "assistant", "content": $(echo "$txt" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}],
  "audio": $audio_arg
}
EOF
)

  # 调 MiMo API
  local result
  result=$(curl -s -X POST "$MIMO_API_URL" \
    -H "api-key: $MIMO_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    --connect-timeout 10 \
    --max-time 30 2>/dev/null) || return 1

  # 解析返回
  local audio_data
  audio_data=$(echo "$result" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    data = d.get('choices', [{}])[0].get('message', {}).get('audio', {}).get('data', '')
    if data:
        import base64
        sys.stdout.buffer.write(base64.b64decode(data))
except Exception as e:
    sys.exit(1)
" 2>/dev/null) || return 1

  if [ -z "$audio_data" ]; then
    return 1
  fi

  echo "$audio_data" > "$out"
  return 0
}

# ----- Edge TTS 模式 -----
try_edge() {
  local out="$1" txt="$2"
  local voice="${EDGE_TTS_VOICE:-zh-CN-YunxiNeural}"

  # 检查 edge-tts 是否安装
  if ! command -v edge-tts &>/dev/null; then
    echo "Error: edge-tts not installed. Install with: pip install edge-tts" >&2
    return 1
  fi

  edge-tts --text "$txt" --voice "$voice" --write-media "$out" 2>/dev/null
}

# ----- 主流程 -----

# 尝试 MiMo（如果有 key）
if [ -n "$MIMO_API_KEY" ]; then
  if try_mimo "$OUTPUT_PATH" "$TEXT"; then
    echo "Used MiMo TTS (voice: $VOICE)"
    exit 0
  else
    echo "MiMo TTS failed, falling back to Edge TTS..." >&2
  fi
fi

# 兜底：Edge TTS
if try_edge "$OUTPUT_PATH" "$TEXT"; then
  echo "Used Edge TTS"
  exit 0
fi

# 都失败了
echo "Error: all TTS providers failed" >&2
exit 1

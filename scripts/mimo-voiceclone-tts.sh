#!/bin/bash
# MiMo VoiceClone TTS Script
# Usage: openclaw-messaging-tts-skill.sh <output_path> <text>
#
# 从 OpenClaw TTS provider 调用，参数由 {{OutputPath}} {{Text}} 传入

set -e

OUTPUT_PATH="$1"
TEXT="$2"
API_KEY=***
API_URL="${MIMO_API_URL:-https://token-plan-cn.xiaomimimo.com/v1/chat/completions}"
REFERENCE_AUDIO="${REFERENCE_AUDIO:-/Users/yzy/.openclaw/scripts/reference-voice.mp3}"
FORMAT="${MIMO_TTS_FORMAT:-mp3}"

if [ -z "$OUTPUT_PATH" ] || [ -z "$TEXT" ]; then
  echo "Usage: $0 <output_path> <text>"
  exit 1
fi

if [ ! -f "$REFERENCE_AUDIO" ]; then
  echo "Reference audio not found: $REFERENCE_AUDIO"
  exit 1
fi

export OUTPUT_PATH TEXT API_KEY API_URL REFERENCE_AUDIO FORMAT
exec python3 "$(dirname "$0")/mimo-voiceclone-worker.py"

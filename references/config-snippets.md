# 配置参考

## OpenClaw TTS 配置（openclaw.json）

```json
{
  "messages": {
    "tts": {
      "auto": "always",
      "provider": "mimo-voiceclone",
      "providers": {
        "mimo-voiceclone": {
          "command": "/Users/yzy/.openclaw/scripts/openclaw-messaging-tts-skill.sh",
          "args": ["{{OutputPath}}", "{{Text}}"],
          "outputFormat": "mp3",
          "timeoutMs": 60000
        }
      }
    }
  }
}
```

## MiMo 模型与 API 配置

```json
{
  "models": {
    "providers": {
      "mimo": {
        "baseUrl": "https://token-plan-cn.xiaomimimo.com/v1",
        "apiKey": "<你的 api-key>",
        "api": "openai-completions",
        "models": [
          {
            "id": "mimo-v2.5-pro",
            "name": "mimo-v2.5-pro",
            "contextWindow": 1048576,
            "maxTokens": 32000,
            "input": ["text"],
            "reasoning": true
          },
          {
            "id": "mimo-v2.5",
            "name": "mimo-v2.5",
            "contextWindow": 262144,
            "reasoning": true,
            "input": ["text", "image"],
            "maxTokens": 32000
          }
        ],
        "headers": {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:148.0) Gecko/20100101 Firefox/148.0"
        }
      }
    }
  }
}
```

## TOOLS.md 语音规则

```markdown
## 语音回复规则

- **每条回复都带语音气泡**（用 `[[tts:text]]...[[/tts:text]]`）
- 语音和文字内容要匹配
- 文字过长 → 摘要性地读（挑重点）
- 超出语音长度限制 → 直接读，不做截断提示
- 目标：每条回复都有听得懂的语音版
```

## 参考音频位置

```
/Users/yzy/.openclaw/scripts/reference-voice.mp3
```

可以用 `REFERENCE_AUDIO` 环境变量覆盖路径。

## 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `MIMO_API_URL` | `https://token-plan-cn.xiaomimimo.com/v1/chat/completions` | API 端点 |
| `REFERENCE_AUDIO` | `/Users/yzy/.openclaw/scripts/reference-voice.mp3` | 参考音频路径 |
| `MIMO_TTS_FORMAT` | `mp3` | 输出音频格式 |

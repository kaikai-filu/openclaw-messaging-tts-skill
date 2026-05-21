# openclaw-messaging-tts-skill

让 [OpenClaw](https://openclaw.ai) AI Agent 的每条文字回复，在 Telegram / 微信等渠道自动生成语音消息。支持 **Edge TTS（免费）**、**MiMo VoiceClone（人声克隆）**、以及任意兼容 OpenAI TTS API 的第三方提供商。

## 功能

- 🎙️ **自动语音** — Agent 回复时自动合成语音，发到消息气泡
- 👤 **声音克隆** — 用 MiMo API 配合一段参考音频，克隆特定人声
- 🆓 **免费方案** — 内置 Edge TTS / sherpa-onnx-tts 支持，零成本起步
- 🔌 **可插拔** — 任意兼容 OpenAI TTS 格式的服务都能接入
- 🔐 **安全设计** — API Key 不进代码，通过环境变量注入

## 快速开始

### 1. 安装依赖

```bash
# Python 3（标准库即可）

# 可选：Edge TTS 免费方案
pip install edge-tts
```

### 2. 配置 TTS Provider

编辑 `openclaw.json`，在 `messages.tts` 中添加 provider：

```json
{
  "messages": {
    "tts": {
      "auto": "always",
      "provider": "xiaomi",
      "providers": {
        "xiaomi": {
          "apiKey": "<你的 MiMo API Key>",
          "baseUrl": "https://token-plan-cn.xiaomimimo.com/v1",
          "model": "mimo-v2.5-tts",
          "voice": "白桦",
          "format": "mp3"
        }
      }
    }
  }
}
```

### 3. 设置环境变量

```bash
# 必填（如果使用 voiceclone 脚本）
export MIMO_API_KEY="<你的 MiMo API Key>"

# 可选
export MIMO_API_URL="https://token-plan-cn.xiaomimimo.com/v1/chat/completions"
export REFERENCE_AUDIO="/path/to/reference-voice.mp3"
```

### 4. 配置 OpenClaw 调用路由脚本

```json
{
  "messages": {
    "tts": {
      "auto": "always",
      "provider": "tts-router",
      "providers": {
        "tts-router": {
          "command": "/path/to/scripts/tts-router.sh",
          "args": ["{{OutputPath}}", "{{Text}}"],
          "outputFormat": "mp3",
          "timeoutMs": 60000
        }
      }
    }
  }
}
```

路由逻辑：
1. ✅ 有 `MIMO_API_KEY` → 尝试 MiMo 白桦男声 TTS
2. ✅ 参考音频存在 → 自动走 VoiceClone 克隆模式
3. ✅ MiMo 失败或没 key → **自动降级 Edge TTS** 兜底
4. ❌ 都失败 → 报错

### 5. 在回复中触发语音

Agent 回复时使用标签即可自动生成语音消息：

```
[[tts:text]]要朗读的文字内容...[[/tts:text]]
```

## 支持的 TTS 提供商对比

| 提供商 | 需要 API Key | 特点 |
|--------|:----------:|------|
| **Edge TTS** (Microsoft) | ❌ 免费 | 多语种、自然发音、开箱即用 |
| **MiMo TTS** (普通) | ✅ | 支持"白桦"等多种音色，低延迟 |
| **MiMo VoiceClone** | ✅ | 用参考音频克隆人声 |
| 其他兼容 OpenAI TTS API 的服务 | ✅ | 自定义端点，灵活部署 |

## 文件结构

```
openclaw-messaging-tts-skill/
├── README.md
├── SKILL.md                    # OpenClaw Skill 定义
├── .env.example                # 环境变量模板
├── .gitignore
├── scripts/
│   ├── mimo-voiceclone-tts.sh  # VoiceClone Shell 入口
│   └── mimo-voiceclone-worker.py  # Python 核心 worker
└── references/
    └── config-snippets.md      # 配置参考模板
```

## 🔐 安全

**API Key 永远不要硬编码在代码里！**

- 所有 `.sh` 脚本从 `MIMO_API_KEY` 环境变量读取，无硬编码回退
- `.gitignore` 排除了 `.env`、`*.mp3`、`*.wav` 等敏感文件
- 参考 `.env.example` 创建自己的 `.env`，填入真实 key

更多安全细节见 [SKILL.md](./SKILL.md#-安全说明--api-key-放哪里)。

## 相关资源

- [OpenClaw TTS 配置文档](https://docs.openclaw.ai/configuration/messages)
- [MiMo 开放平台](https://token-plan-cn.xiaomimimo.com)
- [Edge TTS 项目](https://github.com/rany2/edge-tts)

## License

MIT

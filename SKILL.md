---
name: openclaw-messaging-tts-skill
description: "MiMo 语音克隆 TTS — 用参考音频克隆人声，通过消息气泡 TTS 发送语音回复。"
homepage: https://token-plan-cn.xiaomimimo.com/v1
allowed-tools:
  - exec
  - write
---

# MiMo VoiceClone TTS

用 MiMo `mimo-v2.5-tts-voiceclone` 模型，拿一段参考音频做声音克隆，把文本合成为克隆后的人声 mp3。

## 触发词

- 语音克隆 / TTS voiceclone / 语音合成 / 克隆声音

## 支持的 TTS 提供商

### 1. Edge TTS（免费，无需 API Key）
Microsoft Edge 内置 TTS，走本地 CLI：
```bash
pip install edge-tts
edge-tts --text "你好" --voice zh-CN-XiaoxiaoNeural --write-media output.mp3
```
OpenClaw 自带的 `sherpa-onnx-tts` skill 也可用。

### 2. MiMo VoiceClone（需要 API Key）
本 Skill 的核心，用参考音频克隆人声。

### 3. 其他第三方
兼容 OpenAI TTS API 格式的服务都可以（配置 `baseUrl` 指向自己的端点）。

## 智能路由（推荐）

`scripts/tts-router.sh` 提供自动降级逻辑，一步配置即可：

### OpenClaw 配置

```yaml
messages:
  tts:
    auto: always
    provider: tts-router
    providers:
      tts-router:
        command: /path/to/scripts/tts-router.sh
        args:
          - "{{OutputPath}}"
          - "{{Text}}"
        outputFormat: mp3
        timeoutMs: 60000
```

### 路由逻辑

```
MIMO_API_KEY 存在吗？
├── 是 → 尝试 MiMo TTS（白桦男声）
│   ├── 有 reference-voice.mp3 → VoiceClone 克隆模式
│   └── 没有参考音频 → 普通 TTS 模式
│   └── 成功 → ✅ 返回
│   └── 失败 → ⬇️ 降级
└── 否 / 失败 → Edge TTS 兜底
    ├── edge-tts CLI 可用 → ✅ 返回
    └── 都失败 → ❌ 报错
```

### 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `MIMO_API_KEY` | — | MiMo API Key（设了就优先用 MiMo）|
| `MIMO_API_URL` | `https://token-plan-cn.xiaomimimo.com/v1/chat/completions` | MiMo API 端点 |
| `REFERENCE_AUDIO` | `/Users/yzy/.openclaw/scripts/reference-voice.mp3` | 参考音频路径（克隆用）|
| `TTS_VOICE` | `白桦` | MiMo TTS 音色 |
| `EDGE_TTS_VOICE` | `zh-CN-YunxiNeural` | Edge TTS 音色 |

## 直接使用（不路由）

如果不需要智能降级，也可直接选用单一 provider。

### VoiceClone（Python 脚本）

`scripts/mimo-voiceclone-tts.sh` + `scripts/mimo-voiceclone-worker.py`

1. 读取参考音频 → base64 → `data:audio/mp3;base64,...`
2. POST 到 MiMo API `/v1/chat/completions`：

```json
{
  "model": "mimo-v2.5-tts-voiceclone",
  "messages": [{"role": "assistant", "content": "<文本>"}],
  "audio": {"format": "mp3", "voice": "data:audio/mp3;base64,..."}
}
```

3. 从返回 `choices[0].message.audio.data` 取 base64 音频，解码写出 mp3。

### MiMo TTS（xiaomi provider）

```yaml
provider: xiaomi
providers:
  xiaomi:
    apiKey: "***"
    baseUrl: "https://token-plan-cn.xiaomimimo.com/v1"
    model: "mimo-v2.5-tts"
    voice: "白桦"
    format: "mp3"
```

### Edge TTS

```bash
pip install edge-tts
edge-tts --text "你好" --voice zh-CN-XiaoxiaoNeural --write-media output.mp3
```

## 消息气泡集成

所有方式最终触发方式一致：回复中加上 TTS 标签，OpenClaw 自动调用配置的 provider 合成语音并发送。

```
[[tts:text]]要语音播报的文字内容...[[/tts:text]]
```

TOOLS.md 中配置的语音规则：
- 每条回复都带语音气泡
- 语音和文字内容要匹配
- 文字过长 → 摘要性朗读

## 依赖

- 参考音频文件 `reference-voice.mp3`
- Python 3（标准库即可，无需额外 pip 包）

## 🔐 安全说明 — API Key 放哪里？

> **不要在代码/脚本里硬编码 API Key！** 当前实际运行的脚本之前就有硬编码问题，已修复。

### ✅ 正确做法

#### 方案 A：环境变量（推荐）
在 `.zshrc` / `.bashrc` 中设置：
```bash
export MIMO_API_KEY="tp-xxxxx"
export MIMO_API_URL="https://token-plan-cn.xiaomimimo.com/v1/chat/completions"
export REFERENCE_AUDIO="/path/to/reference-voice.mp3"
```
脚本中从环境变量读取，无回退硬编码：
```bash
API_KEY="${MIMO_API_KEY:?Error: MIMO_API_KEY not set}"
```

#### 方案 B：OpenClaw 配置文件
API key 存在本地 `openclaw.json` 中，不会提交到 Git：
```json
{
  "messages": {
    "tts": {
      "providers": {
        "xiaomi": {
          "apiKey": "tp-xxxxx"
        }
      }
    }
  }
}
```

### ❌ 错误做法

- ❌ 在 `.sh` / `.py` 脚本里写死 `API_KEY="xxx"`
- ❌ 把 `openclaw.json` 提交到公开 GitHub
- ❌ 把 `reference-voice.mp3` 上传到公开仓库
- ❌ `.gitignore` 没配好就 push

### Git 安全

如果这个 Skill repo 要公开，`.gitignore` 至少包含：
```gitignore
# API Keys / secrets
.env
.env.*

# 个人语音样本
*.mp3
*.wav

# 不要提交 openclaw 配置
openclaw.json
```

**最佳实践：** 把 Skill 做成**模板仓库**，所有敏感信息通过 env 注入，`.sh` 文件里只写 `${VAR:?}` 占位。别人 clone 后设环境变量就能用，你的 key 不会暴露。

## 文件结构

```
openclaw-messaging-tts-skill/
  README.md
  SKILL.md
  scripts/
    tts-router.sh                # 智能路由脚本（推荐）
    mimo-voiceclone-tts.sh       # VoiceClone Shell 入口
    mimo-voiceclone-worker.py    # VoiceClone Python 核心 worker
  references/
    config-snippets.md           # 配置样例（占位符，无真实 key）
  assets/
    (输出的音频文件)
```

## API 参考

- **模型：** `mimo-v2.5-tts-voiceclone`
- **端点：** `https://token-plan-cn.xiaomimimo.com/v1/chat/completions`
- **方法：** POST
- **认证：** Header `api-key`
- **输入：** messages（content 为要朗读的文本）+ audio.voice（base64 data URL 参考音频）
- **输出：** choices[0].message.audio.data（base64 编码的 mp3）

## 常见问题

- 参考音频找不到 → 检查 `reference-voice.mp3` 路径和权限
- API 超时 → `timeoutMs` 已设为 60000ms，可酌情调整
- 语音不正常 → 确认参考音频格式为 mp3，且时长不宜过短（建议 5-30 秒）
- `MIMO_API_KEY: parameter null or not set` → 环境变量没设，参考安全章节配置

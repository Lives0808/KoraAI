# KoraAI

**一套 Dart 代码，同时运行在 Android 和 macOS 桌面上的 AI 助手：聊天 + 文档问答（RAG）。**

KoraAI 通过 **OpenAI 兼容协议** 对接任意模型服务 —— OpenAI、DeepSeek、Moonshot、通义千问、
OpenRouter、Ollama、vLLM、LM Studio 都可以，只要在 App 里改一下 Base URL 和 API Key。

```
┌──────────────┐        ┌──────────────┐
│   Android    │        │  macOS 桌面   │     同一份 lib/ 代码
└──────┬───────┘        └──────┬───────┘
       └───────────┬───────────┘
                   ▼
          ┌─────────────────┐      ┌──────────────────────────┐
          │  KoraAI (UI)    │─────▶│  OpenAI 兼容接口          │
          │  聊天 / 文档问答  │      │  /chat/completions (SSE) │
          └────────┬────────┘      │  /embeddings             │
                   ▼               └──────────────────────────┘
        ┌──────────────────────┐
        │ 本地 SQLite           │
        │ 对话 / 文档片段 / 向量 │
        └──────────────────────┘
```

---

## 功能

| | |
|---|---|
| 💬 **流式聊天** | SSE 逐字输出，可随时打断；多会话、重命名、自动生成标题 |
| 📄 **文档问答** | 导入 PDF / DOCX / Markdown / CSV / 代码文件，或直接粘贴文本 |
| 🔍 **混合检索** | 向量检索（embedding）+ BM25 关键词检索，RRF 融合排序 |
| 🧱 **引用可溯源** | 每条回答标注引用了哪些文档片段，点开可看原文 |
| 🌐 **中英双语** | 界面跟随系统语言，也可在设置里手动切换 |
| 🔌 **任意后端** | OpenAI / DeepSeek / Ollama / vLLM / LM Studio … 改地址即切换 |
| 🖥️ **响应式布局** | 桌面用侧边导航 + 三栏，手机用底部导航 + 抽屉 |
| 🔒 **数据本地优先** | 对话和向量都存在本机 SQLite，只有提问内容会发往你配置的服务 |

### 没有 embedding 接口也能用

DeepSeek 等部分服务只提供对话接口，没有 `/embeddings`。KoraAI 内置了**离线 BM25 索引**
（含中文分词与二元组处理），只要导入文档就能立刻做关键词检索问答，完全不需要联网建索引。
配置了向量模型后，检索会升级为「向量 + 关键词」混合模式。

---

## 快速开始

### 环境要求

| | 版本 |
|---|---|
| Flutter | 3.47+（Dart 3.13+） |
| Android | SDK 36、JDK 17 |
| macOS | Xcode 16+（编译桌面端必需） |

### 运行

```bash
git clone https://github.com/Lives0808/KoraAI.git
cd KoraAI
flutter pub get
flutter gen-l10n          # 生成多语言代码（首次或改了 .arb 后）

# macOS 桌面
flutter run -d macos

# Android（先连上设备或启动模拟器）
flutter run -d android
```

### 打包

```bash
flutter build apk --release          # → build/app/outputs/flutter-apk/app-release.apk
flutter build macos --release        # → build/macos/Build/Products/Release/KoraAI.app
```

> **关于 SQLite**：`pubspec.yaml` 里的 `hooks.user_defines.sqlite3.source: system`
> 让 `package:sqlite3` 使用系统自带的 SQLite，而不是在构建时从 GitHub Releases
> 下载预编译动态库。Android 走 sqflite 的原生通道，桌面端用 macOS 自带的
> `libsqlite3.dylib`，两者都够用。想换回官方锁定版本删掉这段即可。
>
> 在 Linux 上开发时需要 `libsqlite3-dev`（提供 `libsqlite3.so` 符号链接）。
> 本项目只启用了 Android 与 macOS 两个平台，其他平台需要自己 `flutter create --platforms=...`。

### 首次使用

1. 打开 App → **设置**
2. 选一个预设（OpenAI / DeepSeek / Ollama），或手动填 Base URL + API Key
3. 点 **测试连接** 确认可用
4. 回到 **聊天** 直接提问；想让它读你的资料，就去 **文档** 页导入文件，
   再用聊天页右上角的 📎 把文档关联到当前对话

---

## 工程结构

```
lib/
├── main.dart                      # 入口
├── app.dart                       # Provider 装配 / 主题 / 多语言
├── core/
│   ├── config/app_settings.dart   # 全部可配置项 + URL 归一化
│   ├── settings/settings_store.dart
│   ├── theme/app_theme.dart
│   └── utils/                     # ID 生成、token 估算、文本清洗
├── data/
│   ├── ai/openai_client.dart      # SSE 流式对话 + embeddings + /models
│   ├── db/                        # SQLite 打开、会话/文档仓储
│   ├── ingestion/
│   │   ├── text_extractor.dart    # PDF / DOCX / 纯文本 → 文本
│   │   ├── text_chunker.dart      # 段落感知的滑窗切片
│   │   └── document_indexer.dart  # 导入 → 切片 → 向量化流水线
│   ├── models/                    # Conversation / ChatMessage / Document / Chunk
│   └── retrieval/
│       ├── tokenizer.dart         # 中英混排分词（中文二元组）
│       ├── bm25_index.dart        # 离线 Okapi BM25
│       └── retriever.dart         # 混合检索 + RRF 融合
├── features/
│   ├── chat/                      # 聊天页、控制器、气泡、输入框、文档选择
│   ├── documents/                 # 文档管理页
│   ├── settings/                  # 设置页
│   └── home/home_shell.dart       # 响应式导航外壳
└── l10n/                          # app_en.arb / app_zh.arb + 生成代码
```

### 数据存放在哪

| 平台 | 路径 |
|---|---|
| macOS | `~/Library/Containers/ai.kora.koraAi/Data/Library/Application Support/ai.kora.koraAi/kora_ai.db` |
| Android | `/data/data/ai.kora.kora_ai/files/…/kora_ai.db` |

设置页底部的 **清空本地数据** 会一次性删除所有对话与文档索引。

---

## 检索是怎么工作的

1. **导入**：文件 → 抽文本（PDF 用 Syncfusion，DOCX 解 ZIP + XML）→ 按段落切 ~1000 字、重叠 150 字
2. **建索引**：始终写入 BM25 倒排索引；配置了向量模型时再调 `/embeddings` 存下向量
3. **提问**：问题同时走两路检索
   - BM25 打分（中文按字 + 二元组切分）
   - 余弦相似度（问题向量 × 片段向量）
4. **融合**：Reciprocal Rank Fusion 合并两个排名，同一文档最多取 3 段，避免单个大文件霸占上下文
5. **注入**：Top-K 片段编号后拼进 system prompt，模型被要求标注 `[1] [2]`，UI 里点引用即可看原文

---

## 安全说明

- **API Key 目前存在平台的 SharedPreferences 里**（明文）。桌面端请确保账号安全；
  如果要上架或多人共用设备，建议接入 `flutter_secure_storage`（macOS Keychain / Android Keystore），
  改动点只有 `lib/core/settings/settings_store.dart` 一个文件。
- 文档切片的**向量化**会把片段内容发给你配置的接口；不配置向量模型时，索引和检索全在本机完成。
- macOS 端已开启沙盒，entitlements 只申请了「出站网络」和「用户选择的文件只读」。

---

## 开发

```bash
flutter analyze          # 静态检查（当前 0 issue）
flutter test             # 单元测试：设置归一化、中文分词、切片、BM25 排序
```

CI 见 `.github/workflows/ci.yml`：每次 push 跑 analyze + test + 构建 APK。

## 第三方依赖与许可

| 依赖 | 用途 | 许可 |
|---|---|---|
| flutter / sqflite / provider / http / file_picker / archive / xml | 基础能力 | BSD / MIT / Apache-2.0 |
| flutter_markdown_plus | 渲染 Markdown 回答 | BSD-3-Clause |
| **syncfusion_flutter_pdf** | 提取 PDF 文本 | ⚠️ Syncfusion 商业许可，个人与小团队可免费申请 Community License |

Syncfusion 的 PDF 库是纯 Dart 实现（不需要原生依赖，这是选它的原因），但它**不是**开源许可。
如果这个项目要商用且不符合其免费条件，可以把 `lib/data/ingestion/text_extractor.dart`
里的 `_extractPdf` 换成 `pdfx`（Apache-2.0，但需要各平台的原生 pdfium 依赖）。

## 已知限制

- `.doc`（老格式）不支持，请先另存为 `.docx` 或 PDF
- 扫描版 PDF 没有文字层，需要 OCR，暂不支持
- 附件目前只用于当前对话的检索，不支持多模态图片输入

## 路线图

- [ ] `flutter_secure_storage` 保存 API Key
- [ ] 对话导出 Markdown / JSON
- [ ] 自定义工具调用（function calling）
- [ ] 本地 ONNX embedding，彻底离线
- [ ] iOS / Windows / Linux 构建产物

## 许可证

MIT，见 [LICENSE](LICENSE)。

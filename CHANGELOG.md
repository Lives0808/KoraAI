# Changelog

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。
格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [1.0.2] - 2026-09-29

三个来自社区（[@Verlintas](https://github.com/Verlintas)）的缺陷修复，都是会让数据
出问题的那种，值得单独发一版。

### 修复

- **设置页冷启动会覆盖已保存的配置**（#1）
  外壳的 `IndexedStack` 会在第一帧就构建设置页，那时 `SettingsController.load()`
  还没返回，输入框被默认值填充；用户随后改任何一个开关，都会把整份配置
  （接口地址、Key、模型）写回成默认值。现在等配置加载完再填充，加载期间显示
  进度指示器，并且写回时会把输入框内容与内存里的配置合并。
- **流式回答过程中删除会话会写坏数据**（#2）
  删除会话时后台流还在跑，流结束时会把回答写进一个已经不存在的会话，触发外键
  约束错误。现在删除会先停掉当前一轮，且流在任意阶段都可取消。
- **向量会挂到错误的文档片段上**（#3）
  `_embedBatch` 用追加的方式收集向量，一旦服务端少返回一个或返回顺序不同，后面
  的向量就会整体错位，导致检索命中错误的内容；`Float32List` 作为视图时写入
  `buffer.asUint8List()` 还会把整个底层缓冲区写进数据库。现在按 `index` 对位、
  校验维度、缺向量直接报错，并新增 `embeddingBytes` 正确处理视图偏移。

### 新增

- macOS 构建工作流 `.github/workflows/macos-release.yml`：不需要本地装 Xcode，
  由 GitHub 的 macOS runner 编译并上传 `KoraAI-<版本>-macos.zip` 与 sha256。

### 测试

- 新增 `settings_screen_test.dart`、`chat_lifecycle_test.dart`、
  `embedding_integrity_test.dart`，测试总数 14 → 28。

## [1.0.1] - 2026-09-28

### 新增

- README 顶部加状态徽章。
- 设置页「关于」里的版本号跟随发布版本。

## [1.0.0] - 2026-09-26

首个版本。

### 新增

- 一套 Flutter 代码同时支持 Android 与 macOS 桌面。
- 聊天：SSE 流式输出、可中断、重新生成、多会话管理、Markdown 渲染。
- 文档问答：导入 PDF / DOCX / Markdown / CSV / 代码文件，或粘贴文本。
- 混合检索：向量余弦相似度 + 离线 BM25（中文按字与二元组切词），RRF 融合排序。
  没有 embedding 接口的服务会自动退回纯关键词检索。
- 回答标注引用编号，可查看命中的原文片段。
- 中英双语界面，跟随系统语言；桌面侧边导航 / 手机底部导航自适应。
- 设置页内置 OpenAI / DeepSeek / Ollama 预设与连接测试。
- 文档、对话与向量全部存在本机 SQLite。

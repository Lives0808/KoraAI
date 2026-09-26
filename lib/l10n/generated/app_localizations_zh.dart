// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'KoraAI';

  @override
  String get appTagline => '聊天与文档问答，接入你自己的模型服务。';

  @override
  String get navChat => '聊天';

  @override
  String get navDocuments => '文档';

  @override
  String get navSettings => '设置';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonClose => '关闭';

  @override
  String get commonRetry => '重试';

  @override
  String get commonSave => '保存';

  @override
  String get commonAdd => '添加';

  @override
  String get commonCopy => '复制';

  @override
  String get commonCopied => '已复制到剪贴板';

  @override
  String get commonSearch => '搜索';

  @override
  String get chatNewChat => '新建对话';

  @override
  String get chatHistory => '历史记录';

  @override
  String get chatEmptyTitle => '问 KoraAI 任何问题';

  @override
  String get chatEmptyBody => '直接输入问题，或先导入文档，让回答基于你自己的资料。';

  @override
  String get chatInputHint => '发消息给 KoraAI…';

  @override
  String get chatSend => '发送';

  @override
  String get chatStop => '停止';

  @override
  String get chatRegenerate => '重新生成';

  @override
  String get chatThinking => '思考中…';

  @override
  String get chatSources => '引用来源';

  @override
  String chatSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条引用',
      zero: '无引用',
    );
    return '$_temp0';
  }

  @override
  String get chatAttachDocuments => '文档';

  @override
  String chatAttachedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已关联 $count 个文档',
      zero: '未关联文档',
    );
    return '$_temp0';
  }

  @override
  String get chatAttachHint => '关联文档后，回答会基于你的资料生成。';

  @override
  String get chatNoDocuments => '还没有文档，请先在「文档」页导入。';

  @override
  String get chatDeleteTitle => '删除对话？';

  @override
  String get chatDeleteBody => '该对话及其全部消息将被永久删除。';

  @override
  String get chatRename => '重命名';

  @override
  String get chatRenameTitle => '对话标题';

  @override
  String get chatUntitled => '新对话';

  @override
  String get chatNotConfigured => '请先在「设置」里配置接口地址和密钥。';

  @override
  String get docsTitle => '文档';

  @override
  String get docsImport => '导入文件';

  @override
  String get docsPaste => '粘贴文本';

  @override
  String get docsEmpty => '还没有文档';

  @override
  String get docsEmptyBody => '支持 PDF、DOCX、Markdown、CSV 及代码文件，全部保存在本机。';

  @override
  String docsChunks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个片段',
    );
    return '$_temp0';
  }

  @override
  String get docsStatusPending => '等待中';

  @override
  String get docsStatusIndexing => '索引中…';

  @override
  String get docsStatusReady => '就绪';

  @override
  String get docsStatusFailed => '失败';

  @override
  String get docsIndexed => '已向量化';

  @override
  String get docsKeywordOnly => '仅关键词索引';

  @override
  String get docsReindex => '重新索引';

  @override
  String get docsEmbed => '生成向量';

  @override
  String get docsDeleteTitle => '删除文档？';

  @override
  String get docsDeleteBody => '将从本机移除该文档及其索引，不会影响原始文件。';

  @override
  String get docsPasteTitle => '粘贴文本';

  @override
  String get docsPasteNameLabel => '标题';

  @override
  String get docsPasteNameHint => '例如：会议记录';

  @override
  String get docsPasteBodyLabel => '正文';

  @override
  String get docsPasteBodyHint => '粘贴你想提问的任意文本…';

  @override
  String get docsImporting => '索引中…';

  @override
  String get docsAttachToChat => '用于聊天';

  @override
  String get docsDetachFromChat => '从聊天移除';

  @override
  String get docsFileMissing => '源文件不可用';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsEndpointSection => '模型接口';

  @override
  String get settingsBaseUrl => '接口地址';

  @override
  String get settingsBaseUrlHelp =>
      '兼容 OpenAI 协议。例如：https://api.openai.com/v1、https://api.deepseek.com/v1、http://localhost:11434/v1';

  @override
  String get settingsApiKey => 'API Key';

  @override
  String get settingsApiKeyHelp => '本地服务（Ollama、LM Studio 等）可留空。';

  @override
  String get settingsChatModel => '对话模型';

  @override
  String get settingsEmbeddingModel => '向量模型';

  @override
  String get settingsEmbeddingHelp => '可选。留空时文档检索会退回离线关键词索引。';

  @override
  String get settingsRetrievalSection => '检索';

  @override
  String get settingsTopK => '每次回答引用的片段数';

  @override
  String get settingsUseVector => '存在向量时启用向量检索';

  @override
  String get settingsPromptSection => '提示词';

  @override
  String get settingsSystemPrompt => '系统提示词';

  @override
  String get settingsTemperature => '随机性（temperature）';

  @override
  String get settingsConnectionSection => '连接';

  @override
  String get settingsTestConnection => '测试连接';

  @override
  String get settingsTesting => '测试中…';

  @override
  String get settingsTestSuccess => '连接正常。';

  @override
  String get settingsLanguage => '界面语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsDataSection => '本地数据';

  @override
  String get settingsResetData => '清空本地数据';

  @override
  String get settingsResetDataBody => '删除本机保存的全部对话与文档索引。';

  @override
  String get settingsAbout => '关于';

  @override
  String settingsVersion(String version) {
    return '版本 $version';
  }

  @override
  String get settingsPresetOpenAi => 'OpenAI';

  @override
  String get settingsPresetDeepSeek => 'DeepSeek';

  @override
  String get settingsPresetOllama => 'Ollama（本地）';

  @override
  String get settingsPresets => '快速预设';
}

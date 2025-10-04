// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settings => '设置';

  @override
  String get general => '通用';

  @override
  String get providers => '服务提供商';

  @override
  String get mcpServer => 'MCP 服务器';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get dark => '深色';

  @override
  String get light => '浅色';

  @override
  String get system => '跟随系统';

  @override
  String get languageSettings => '语言设置';

  @override
  String get featureSettings => '功能设置';

  @override
  String get enableArtifacts => '启用人工制品';

  @override
  String get enableArtifactsDescription => '在对话中启用 AI 助手的人工制品，这将使用更多的令牌';

  @override
  String get enableToolUsage => '启用工具使用';

  @override
  String get enableToolUsageDescription => '在对话中启用工具的使用，这将使用更多的令牌';

  @override
  String get themeSettings => '主题设置';

  @override
  String get lightTheme => '浅色主题';

  @override
  String get darkTheme => '深色主题';

  @override
  String get followSystem => '跟随系统';

  @override
  String get showAvatar => '显示头像';

  @override
  String get showAssistantAvatar => '显示助手头像';

  @override
  String get showAssistantAvatarDescription => '在对话中显示 AI 助手的头像';

  @override
  String get showUserAvatar => '显示用户头像';

  @override
  String get showUserAvatarDescription => '在对话中显示用户的头像';

  @override
  String get systemPrompt => '系统提示词';

  @override
  String get systemPromptDescription => '这是与 AI 助手对话的系统提示词，用于设置助手的行为和风格';

  @override
  String get llmKey => 'LLM 密钥';

  @override
  String get toolKey => '工具密钥';

  @override
  String get saveSettings => '保存设置';

  @override
  String get apiKey => 'API 密钥';

  @override
  String enterApiKey(Object provider) {
    return '请输入您的 $provider API 密钥';
  }

  @override
  String get apiKeyValidation => 'API 密钥必须至少包含 10 个字符';

  @override
  String get apiEndpoint => 'API 端点';

  @override
  String get enterApiEndpoint => '请输入 API 端点 URL';

  @override
  String get apiVersion => 'API 版本';

  @override
  String get enterApiVersion => '输入 API 版本';

  @override
  String get platformNotSupported => '当前平台不支持 MCP Server';

  @override
  String get mcpServerDesktopOnly => 'MCP Server 仅支持桌面端（Windows、macOS、Linux）';

  @override
  String get searchServer => '搜索服务器...';

  @override
  String get noServerConfigs => '未找到服务器配置';

  @override
  String get addProvider => '添加服务商';

  @override
  String get refresh => '刷新';

  @override
  String get install => '安装';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get command => '命令 或 服务地址';

  @override
  String get arguments => '参数';

  @override
  String get environmentVariables => '环境变量';

  @override
  String get serverName => '服务器名称';

  @override
  String get commandExample => '例如：npx、uvx、https://mcpserver.com';

  @override
  String get argumentsExample => '参数之间用空格分隔，包含空格的参数请用引号包围，例如：-y obsidian-mcp \'/Users/username/Documents/Obsidian Vault\'';

  @override
  String get envVarsFormat => '每行一个，格式：KEY=VALUE';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get confirmDelete => '确认删除';

  @override
  String confirmDeleteServer(Object name) {
    return '您确定要删除服务器 \"$name\" 吗？';
  }

  @override
  String get error => '错误';

  @override
  String commandNotExist(Object command, Object path) {
    return '命令 \"$command\" 不存在，请先安装\n\n当前 PATH：\n$path';
  }

  @override
  String get all => '全部';

  @override
  String get installed => '已安装';

  @override
  String get modelSettings => '模型设置';

  @override
  String temperature(Object value) {
    return '采样温度: $value';
  }

  @override
  String get temperatureTooltip => '采样温度控制输出的随机性：\n• 0.0：适合代码生成和数学解题\n• 1.0：适合数据抽取和分析\n• 1.3：适合通用对话和翻译\n• 1.5：适合创意写作和诗歌创作';

  @override
  String topP(Object value) {
    return '核采样: $value';
  }

  @override
  String get topPTooltip => 'Top P（核采样）是temperature的替代方案。模型只考虑累积概率超过P的标记。建议不要同时修改temperature和top_p。';

  @override
  String get maxTokens => '最大令牌数';

  @override
  String get maxTokensTooltip => '生成的最大令牌数。一个令牌大约等于4个字符。较长的对话需要更多的令牌。';

  @override
  String frequencyPenalty(Object value) {
    return '频率惩罚: $value';
  }

  @override
  String get frequencyPenaltyTooltip => '频率惩罚参数。正值会根据新标记在文本中的现有频率来惩罚它们，降低模型逐字重复同样内容的可能性。';

  @override
  String presencePenalty(Object value) {
    return '存在惩罚: $value';
  }

  @override
  String get presencePenaltyTooltip => '存在惩罚参数。正值会根据新标记是否出现在文本中来惩罚它们，增加模型谈论新主题的可能性。';

  @override
  String get enterMaxTokens => '输入最大令牌数';

  @override
  String get share => '分享';

  @override
  String get modelConfig => '模型配置';

  @override
  String get debug => '调试';

  @override
  String get webSearchTest => '网页搜索测试';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get last7Days => '前 7 天';

  @override
  String get last30Days => '前 30 天';

  @override
  String get earlier => '更早';

  @override
  String get confirmDeleteSelected => '确定要删除选中的对话吗？';

  @override
  String get confirmThisChat => '您确定要删除这些对话吗？';

  @override
  String get ok => '确定';

  @override
  String get askMeAnything => '问我任何问题...';

  @override
  String get uploadFiles => '上传文件';

  @override
  String get welcomeMessage => '今天我能帮您什么？';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制到剪贴板';

  @override
  String get retry => '重试';

  @override
  String get brokenImage => '图片损坏';

  @override
  String toolCall(Object name) {
    return '调用 $name';
  }

  @override
  String toolResult(Object name) {
    return '调用 $name 结果';
  }

  @override
  String get selectModel => '选择模型';

  @override
  String get close => '关闭';

  @override
  String get selectFromGallery => '从图库选择';

  @override
  String get selectFile => '选择文件';

  @override
  String get uploadFile => '上传文件';

  @override
  String get openBrowser => '打开浏览器';

  @override
  String get codeCopiedToClipboard => '代码已复制到剪贴板';

  @override
  String get thinking => '思考中';

  @override
  String get thinkingEnd => '思考结束';

  @override
  String get tool => '工具';

  @override
  String get userCancelledToolCall => '工具执行失败';

  @override
  String get code => '代码';

  @override
  String get preview => '预览';

  @override
  String get loadContentFailed => '加载内容失败，请重试';

  @override
  String get openingBrowser => '正在打开浏览器';

  @override
  String get functionCallAuth => '工具调用授权';

  @override
  String get allowFunctionExecution => '是否允许执行以下工具:';

  @override
  String parameters(Object params) {
    return '参数: $params';
  }

  @override
  String get allow => '允许';

  @override
  String get loadDiagramFailed => '加载图表失败，请重试';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get chinese => '中文';

  @override
  String get turkish => '土耳其语';

  @override
  String get functionRunning => '正在执行工具...';

  @override
  String get thinkingProcess => '思考中';

  @override
  String get thinkingProcessWithDuration => '思考中, 用时';

  @override
  String get thinkingEndWithDuration => '思考完成，用时';

  @override
  String get thinkingEndComplete => '思考完成';

  @override
  String seconds(Object seconds) {
    return '$seconds秒';
  }

  @override
  String get fieldRequired => '此字段为必填项';

  @override
  String get autoApprove => '自动批准';

  @override
  String get verify => '验证密钥';

  @override
  String get howToGet => '如何获取';

  @override
  String get modelList => '模型列表';

  @override
  String get enableModels => '启用模型';

  @override
  String get disableAllModels => '禁用所有模型';

  @override
  String get saveSuccess => '设置保存成功';

  @override
  String get genTitleModel => '标题生成';

  @override
  String get serverNameTooLong => '服务名称长度不能超过 50 个字符';

  @override
  String get confirm => '确认';

  @override
  String get providerName => '提供商名称';

  @override
  String get apiStyle => 'API 风格';

  @override
  String get enterProviderName => '输入提供商名称';

  @override
  String get providerNameRequired => '提供商名称为必填项';

  @override
  String get addModel => '添加模型';

  @override
  String get modelName => '模型名称';

  @override
  String get enterModelName => '输入模型名称';

  @override
  String get noApiConfigs => '无可用的 API 配置';

  @override
  String get add => '添加';

  @override
  String get fetch => '获取';

  @override
  String get on => '开启';

  @override
  String get off => '关闭';

  @override
  String get apiUrl => 'API 地址';

  @override
  String get selectApiStyle => '请选择 API 风格';

  @override
  String get serverType => '服务类型';

  @override
  String get reset => '重置';

  @override
  String get start => '启动';

  @override
  String get stop => '停止';

  @override
  String get search => '搜索';

  @override
  String newVersionFound(Object version) {
    return '发现新版本 $version';
  }

  @override
  String get newVersionAvailable => '发现新版本';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateLater => '稍后更新';

  @override
  String get ignoreThisVersion => '忽略此版本';

  @override
  String get releaseNotes => '更新内容：';

  @override
  String get openUrlFailed => '无法打开链接';

  @override
  String get checkingForUpdates => '正在检查更新...';

  @override
  String get checkUpdate => '检查更新';

  @override
  String get appDescription => 'ChatMCP 是一款跨平台的 AI 客户端，致力于让更多人方便地使用 AI。';

  @override
  String get visitWebsite => '站点';

  @override
  String get aboutApp => '关于';

  @override
  String get networkError => '网络连接问题，请检查网络后重试';

  @override
  String get noElementError => '未找到匹配内容，请重试';

  @override
  String get permissionError => '权限不足，请检查设置';

  @override
  String get unknownError => '发生未知错误';

  @override
  String get timeoutError => '请求超时，请稍后重试';

  @override
  String get notFoundError => '未找到请求的资源';

  @override
  String get invalidError => '无效的请求或参数';

  @override
  String get unauthorizedError => '未授权访问，请检查权限';

  @override
  String get minimize => '最小化';

  @override
  String get maximize => '最大化';

  @override
  String get conversationSettings => '对话设置';

  @override
  String get maxMessages => '最大消息数';

  @override
  String get maxMessagesDescription => '限制传递给 LLM 的最大消息数量 (1-1000)';

  @override
  String get maxLoops => '最大循环数';

  @override
  String get maxLoopsDescription => '限制工具调用的最大循环次数，防止无限循环 (1-1000)';

  @override
  String get mcpServers => 'MCP 服务器';

  @override
  String get getApiKey => '获取 API 秘钥';

  @override
  String get proxySettings => '代理设置';

  @override
  String get enableProxy => '启用代理';

  @override
  String get enableProxyDescription => '启用代理后，网络请求将通过配置的代理服务器';

  @override
  String get proxyType => '代理类型';

  @override
  String get proxyHost => '代理地址';

  @override
  String get proxyPort => '代理端口';

  @override
  String get proxyUsername => '用户名';

  @override
  String get proxyPassword => '密码';

  @override
  String get enterProxyHost => '请输入代理服务器地址';

  @override
  String get enterProxyPort => '请输入代理端口';

  @override
  String get enterProxyUsername => '请输入用户名（可选）';

  @override
  String get enterProxyPassword => '请输入密码（可选）';

  @override
  String get proxyHostRequired => '代理地址为必填项';

  @override
  String get proxyPortInvalid => '代理端口必须在 1-65535 之间';

  @override
  String get saved => '已保存';

  @override
  String get dataSync => '数据同步';

  @override
  String get syncServerRunning => '同步服务器运行中';

  @override
  String get maintenance => '维护';

  @override
  String get cleanupLogs => '清理旧日志';

  @override
  String get cleanupLogsDescription => '清理日志文件';

  @override
  String get confirmCleanup => '确认清理';

  @override
  String get confirmCleanupMessage => '确定要删除日志文件吗？此操作不可撤销。';

  @override
  String get cleanupSuccess => '旧日志清理完成';

  @override
  String get cleanupFailed => '清理失败';

  @override
  String get syncServerStopped => '同步服务器已停止';

  @override
  String get scanQRToConnect => '其他设备扫描此二维码连接：';

  @override
  String get addressCopied => '地址已复制到剪贴板';

  @override
  String get otherDevicesCanScan => '其他设备可以扫描此二维码快速连接';

  @override
  String get startServer => '启动服务器';

  @override
  String get stopServer => '停止服务器';

  @override
  String get connectToOtherDevices => '连接到其他设备';

  @override
  String get scanQRCode => '扫描二维码连接';

  @override
  String get connectionHistory => '连接历史：';

  @override
  String get connect => '连接';

  @override
  String get manualInputAddress => '或手动输入服务器地址：';

  @override
  String get serverAddress => '服务器地址';

  @override
  String get syncFromServer => '从服务器同步';

  @override
  String get pushToServer => '推送到服务器';

  @override
  String get usageInstructions => '使用说明';

  @override
  String get desktopAsServer => '桌面端作为服务器：';

  @override
  String get desktopStep1 => '1. 点击\"启动服务器\"按钮';

  @override
  String get desktopStep2 => '2. 显示二维码给手机扫描';

  @override
  String get desktopStep3 => '3. 手机扫码后可进行数据同步';

  @override
  String get mobileConnect => '手机端连接：';

  @override
  String get mobileStep1 => '1. 点击\"扫描二维码连接\"';

  @override
  String get mobileStep2 => '2. 扫描桌面端显示的二维码';

  @override
  String get mobileStep3 => '3. 选择同步方向（上传/下载）';

  @override
  String get uploadDescription => '• 上传：将本设备数据推送到服务器';

  @override
  String get downloadDescription => '• 下载：从服务器获取数据到本设备';

  @override
  String get syncContent => '• 同步内容：聊天记录、设置、MCP配置';

  @override
  String get syncServerStarted => '同步服务器已启动';

  @override
  String get syncServerStartFailed => '启动服务器失败';

  @override
  String get syncServerStopFailed => '停止服务器失败';

  @override
  String get scanQRCodeTitle => '扫描二维码';

  @override
  String get flashOn => '开启闪光灯';

  @override
  String get flashOff => '关闭闪光灯';

  @override
  String get aimQRCode => '将二维码对准扫描框';

  @override
  String get scanSyncQRCode => '扫描桌面端显示的同步二维码';

  @override
  String get manualInputAddressButton => '手动输入地址';

  @override
  String get manualInputServerAddress => '手动输入服务器地址';

  @override
  String get enterValidServerAddress => '请输入有效的服务器地址';

  @override
  String scanSuccessConnectTo(Object deviceName) {
    return '扫描成功，连接到: $deviceName';
  }

  @override
  String get scanSuccessAddressFilled => '扫描成功，已填入服务器地址';

  @override
  String get scannerOpenFailed => '打开扫码器失败';

  @override
  String get pleaseInputServerAddress => '请先扫码或输入服务器地址';

  @override
  String get connectingToServer => '正在连接服务器...';

  @override
  String get downloadingData => '正在下载数据...';

  @override
  String get importingData => '正在导入数据...';

  @override
  String get reinitializingData => '正在重新初始化应用数据...';

  @override
  String get dataSyncSuccess => '数据同步成功';

  @override
  String get preparingData => '正在准备数据...';

  @override
  String get uploadingData => '正在上传数据...';

  @override
  String get dataPushSuccess => '数据推送成功';

  @override
  String get syncFailed => '同步失败';

  @override
  String get pushFailed => '推送失败';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes分钟前';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours小时前';
  }

  @override
  String daysAgo(Object days) {
    return '$days天前';
  }

  @override
  String serverSelected(Object deviceName) {
    return '已选择服务器: $deviceName';
  }

  @override
  String get connectionRecordDeleted => '已删除连接记录';

  @override
  String viewAllConnections(Object count) {
    return '查看全部 $count 个连接';
  }

  @override
  String get clearAllHistory => '清空所有';

  @override
  String get clearAllConnectionHistory => '已清空所有连接历史';

  @override
  String get unknownDevice => '未知设备';

  @override
  String get unknownPlatform => '未知平台';

  @override
  String get inmemory => '内置';

  @override
  String get toggleSidebar => '切换侧边栏';

  @override
  String get deleteChat => '删除聊天';

  @override
  String get selectAll => '全选';

  @override
  String get newChat => '新聊天';

  @override
  String get send => '发送';

  @override
  String get more => '更多';

  @override
  String get noMoreData => '没有更多了';

  @override
  String get speak => 'Speak';
}

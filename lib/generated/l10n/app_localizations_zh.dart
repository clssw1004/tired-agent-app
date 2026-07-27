// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'TiredAgent';

  @override
  String get navManagers => '管理器';

  @override
  String get navSessions => '固定会话';

  @override
  String get navSettings => '设置';

  @override
  String get managersTitle => '管理器';

  @override
  String get managersWelcome => '欢迎使用 tiredAgent';

  @override
  String get managersWelcomeDesc => '添加 Manager 服务器来管理你的代理和会话';

  @override
  String get managersAdd => '添加 Manager';

  @override
  String get managersConnect => '连接';

  @override
  String get managersAdded => 'Manager 已添加';

  @override
  String get managersReconnect => '重连';

  @override
  String get managersReconnected => '已重连';

  @override
  String get managersReconnectFailed => '重连失败';

  @override
  String get managersRemove => '移除';

  @override
  String managersRemoveTitle(String name) {
    return '移除 \"$name\"？';
  }

  @override
  String get managersRemoveDesc => '将删除 Manager 配置文件和已保存的令牌，之后可重新添加。';

  @override
  String get managersSessionExpired => '会话已过期，输入 API 令牌重连。';

  @override
  String get managersAccessToken => '访问令牌';

  @override
  String get statusConnected => '已连接';

  @override
  String get statusConnecting => '连接中…';

  @override
  String get statusError => '错误';

  @override
  String get statusDisconnected => '未连接';

  @override
  String get timeSecondsAgo => '秒前';

  @override
  String get timeMinutesAgo => '分钟前';

  @override
  String get timeHoursAgo => '小时前';

  @override
  String get timeDaysAgo => '天前';

  @override
  String get agentAddTitle => '添加 Agent';

  @override
  String get agentRegister => '注册';

  @override
  String agentAdded(String name) {
    return 'Agent $name 已添加';
  }

  @override
  String agentAddFailed(String error) {
    return '添加 Agent 失败：$error';
  }

  @override
  String agentRemoveTitle(String name) {
    return '移除 Agent \"$name\"？';
  }

  @override
  String get agentRemoveDesc => '将注销该 Agent 并删除其会话，之后可重新添加。';

  @override
  String agentRemoved(String name) {
    return 'Agent $name 已移除';
  }

  @override
  String agentRemoveFailed(String error) {
    return '移除 Agent 失败：$error';
  }

  @override
  String get agentNoAgents => '暂无 Agent';

  @override
  String get agentNoAgentsDesc => '注册 Agent 以开始创建会话';

  @override
  String get agentManagerNotFound => '未找到 Manager';

  @override
  String get agentRetry => '重试';

  @override
  String get agentRemoveTooltip => '移除 Agent';

  @override
  String get agentAddTooltip => '添加 Agent';

  @override
  String get sessionsFilterAll => '全部';

  @override
  String get sessionsFilterRunning => '运行中';

  @override
  String get sessionsFilterExited => '已退出';

  @override
  String get sessionsNewTooltip => '新建会话';

  @override
  String get sessionsKillTitle => '终止此会话？';

  @override
  String get sessionsKillDesc => '将终止正在运行的进程并从列表中移除。';

  @override
  String get sessionsKillBtn => '终止';

  @override
  String get sessionsDeleteTitle => '删除会话日志？';

  @override
  String get sessionsDeleteDesc => '将删除数据库记录和磁盘上的输出日志，此操作不可恢复。';

  @override
  String get sessionsDeleteBtn => '删除';

  @override
  String get sessionsConfirm => '确认';

  @override
  String get sessionsPruneTitle => '清理过期会话？';

  @override
  String get sessionsPruneDesc => '将删除所有超过 24 小时未活动的会话。';

  @override
  String get sessionsPruneBtn => '清理';

  @override
  String sessionsPruned(int count) {
    return '已清理 $count 个会话';
  }

  @override
  String get sessionsEmpty => '暂无会话';

  @override
  String get sessionsLoading => '加载中…';

  @override
  String get sessionsPinTitle => '固定会话';

  @override
  String get sessionsPinLabel => '显示名称';

  @override
  String get sessionsPinned => '已固定';

  @override
  String get sessionsUnpinned => '已取消固定';

  @override
  String get sessionsNotConnected => '未连接';

  @override
  String get sessionsManagerNotFound => '未找到 Manager';

  @override
  String sessionsCount(int count) {
    return '$count 个会话';
  }

  @override
  String get sessionTitle => '会话';

  @override
  String get sessionKillTitle => '终止此会话？';

  @override
  String get sessionKillDesc => '将终止正在运行的进程。';

  @override
  String get sessionKillBtn => '终止';

  @override
  String sessionKillFailed(String error) {
    return '终止失败：$error';
  }

  @override
  String get sessionDeleteTitle => '删除会话日志？';

  @override
  String get sessionDeleteDesc => '将删除数据库记录和磁盘上的输出日志，此操作不可恢复。';

  @override
  String get sessionDeleteBtn => '删除';

  @override
  String sessionDeleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String get sessionKillTooltip => '终止会话';

  @override
  String get sessionDeleteTooltip => '删除会话';

  @override
  String get sessionReconnectTooltip => '重连';

  @override
  String get sessionNotConnected => 'Manager 未连接';

  @override
  String get sessionNotFound => '未找到会话';

  @override
  String get createTitle => '新建会话';

  @override
  String get createPreset => '预设';

  @override
  String get createPreview => '预览';

  @override
  String get createCommand => '命令';

  @override
  String get createArguments => '参数';

  @override
  String get createOptions => '选项';

  @override
  String get createSessionLabel => '会话标签';

  @override
  String get createWorkingDir => '工作目录';

  @override
  String get createCancel => '取消';

  @override
  String get createLaunch => '启动';

  @override
  String get createSave => '保存';

  @override
  String get createSaveAsPreset => '另存为预设';

  @override
  String get createPresetName => '预设名称';

  @override
  String get createSelectPreset => '选择预设';

  @override
  String get createHomeDir => 'Agent 主目录';

  @override
  String get createAutoLabel => '留空自动生成';

  @override
  String get createTerminalSizeHint => '会话启动后终端大小自动匹配';

  @override
  String get createNotConnected => '未连接';

  @override
  String get createSectionRecent => '最近使用';

  @override
  String get createSectionCustom => '自定义';

  @override
  String get createArgsHint => '--no-input  --verbose';

  @override
  String get createOptionsCancel => '取消';

  @override
  String get createOptionsApply => '应用';

  @override
  String get pinnedTitle => '固定会话';

  @override
  String get pinnedEmpty => '暂无固定会话';

  @override
  String get pinnedEmptyDesc => '在 Agent 的会话列表中点击 📌\n可将常用会话固定到此处';

  @override
  String get pinnedUnpinTitle => '取消固定？';

  @override
  String pinnedUnpinDesc(String label) {
    return '从固定会话中移除 \"$label\"？';
  }

  @override
  String get pinnedUnpin => '取消固定';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsApp => '应用';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get pinLabel => '固定';

  @override
  String get unpinLabel => '取消固定';

  @override
  String get reconnectLabel => '重连';

  @override
  String get removeLabel => '移除';

  @override
  String get labelName => '名称';

  @override
  String get labelUrl => 'URL';

  @override
  String get labelToken => '令牌';

  @override
  String get labelAgentName => 'Agent 名称';

  @override
  String get labelAgentUrl => 'Agent URL';

  @override
  String get labelAgentToken => 'Agent 令牌';

  @override
  String get statusRunning => '运行中';

  @override
  String get statusStarting => '启动中';

  @override
  String get statusExited => '已退出';
}

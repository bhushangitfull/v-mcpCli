import 'package:chatmcp/utils/platform.dart';
import 'package:flutter/material.dart';
import 'llm_setting.dart';
import 'mcp_server.dart';
import 'general_setting.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'network_sync_setting.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  List<SettingTab> _getTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      // SettingTab(title: l10n.general, icon: CupertinoIcons.settings, content: GeneralSettings()),
      SettingTab(title: l10n.providers, icon: CupertinoIcons.cube, content: KeysSettings()),
      SettingTab(title: l10n.mcpServer, icon: CupertinoIcons.hammer, content: McpServer()),
      // if (!kIsBrowser) SettingTab(title: l10n.dataSync, icon: CupertinoIcons.cloud_download, content: NetworkSyncSetting()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabs(context);

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 5,
            labelStyle: TextStyle(fontSize: kIsMobile ? 10 : 14),
            tabs: tabs.map((tab) => Tab(icon: Icon(tab.icon), text: tab.title)).toList(),
            onTap: (index) {
              setState(() {});
            },
          ),
        ),
        body: TabBarView(children: tabs.map((tab) => tab.content).toList()),
      ),
    );
  }
}

// 选项卡数据模型
class SettingTab {
  final String title;
  final IconData icon;
  final Widget content;

  SettingTab({required this.title, required this.icon, required this.content});
}

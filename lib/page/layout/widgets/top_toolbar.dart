import 'package:chatmcp/components/widgets/base.dart';
import 'package:chatmcp/widgets/ink_icon.dart';
import 'package:flutter/material.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import './model_selector.dart';
import 'package:window_manager/window_manager.dart' as wm;
import 'package:chatmcp/utils/platform.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/provider/chat_provider.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:chatmcp/provider/mcp_server_provider.dart';
// test page
import 'package:chatmcp/widgets/markdown/markit_widget.dart';
import 'package:chatmcp/utils/event_bus.dart';
import 'package:chatmcp/page/layout/widgets/chat_setting.dart';
import 'package:chatmcp/widgets/upgrade.dart';
import 'package:chatmcp/page/layout/widgets/window_controls.dart';
import 'package:chatmcp/components/widgets/custom_popup.dart';

class TopToolbar extends StatelessWidget {
  final bool hideSidebar;
  final VoidCallback onToggleSidebar;

  const TopToolbar({super.key, required this.hideSidebar, required this.onToggleSidebar});

  void _onShowChatSetting(BuildContext context) {
    if (kIsMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(body: SafeArea(child: const ChatSetting())),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Padding(padding: const EdgeInsets.all(16), child: const ChatSetting()),
          ),
        ),
      );
    }
  }

  Widget _buildMoreMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BasePopup(
      showArrow: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ProviderManager.chatProvider.activeChat != null)
            InkWell(
              onTap: () {
                emit(ShareEvent(false));
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.share, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.share, style: TextStyle(color: AppColors.getThemeTextColor(context))),
                  ],
                ),
              ),
            ),
          InkWell(
            onTap: () {
              _onShowChatSetting(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.slider_horizontal_3, size: 18),
                  const SizedBox(width: 12),
                  Text(l10n.modelConfig, style: TextStyle(color: AppColors.getThemeTextColor(context))),
                ],
              ),
            ),
          ),
          if (kIsDebug)
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: Text(l10n.webSearchTest)),
                      body: const MarkitTestPage(),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.ant, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.debug, style: TextStyle(color: AppColors.getThemeTextColor(context))),
                  ],
                ),
              ),
            ),
          // delete chat
          if (ProviderManager.chatProvider.activeChat != null)
            InkWell(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.confirmDelete),
                    content: Text('${l10n.confirmThisChat}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(MaterialLocalizations.of(context).okButtonLabel)),
                    ],
                  ),
                );
                if (confirm == true) {
                  final chat = ProviderManager.chatProvider.activeChat;
                  if (chat != null) {
                    ProviderManager.chatProvider.deleteChat(chat.id!);
                  }
                  Navigator.of(context).pop(); // Close the popup after deleting
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.delete, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.delete, style: TextStyle(color: AppColors.getThemeTextColor(context))),
                  ],
                ),
              ),
            ),
        ],
      ),
      maxWidth: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: InkIcon(icon: CupertinoIcons.ellipsis_vertical, size: 18, tooltip: AppLocalizations.of(context)!.more),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        return Consumer<McpServerProvider>(
          builder: (context, mcpProvider, child) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () async {
                  debugPrint('double tap');
                  if (kIsDesktop) {
                    try {
                      bool isMaximized = await wm.windowManager.isMaximized();
                      if (isMaximized) {
                        await wm.windowManager.unmaximize();
                      } else {
                        await wm.windowManager.maximize();
                      }
                    } catch (e) {
                      debugPrint('窗口操作失败: $e');
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.getToolbarBottomBorderColor(context))),
                  ),
                  padding: kIsDesktop ? EdgeInsets.only(left: hideSidebar ? (kIsMacOS ? 70 : 8) : 0, top: 2) : null,
                  child: kIsDesktop ? wm.DragToMoveArea(child: _buildToolbarContent(context)) : _buildToolbarContent(context),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToolbarContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hideSidebar && kIsDesktop) ...[
                // Show app logo and name when sidebar is hidden
                
                  CText(text: 'MCP-C', size: 12, fontWeight: FontWeight.w700),
                  const Gap(size: 24),
              

                InkIcon(icon: CupertinoIcons.sidebar_right, onTap: onToggleSidebar, tooltip: AppLocalizations.of(context)!.toggleSidebar),
                const Gap(size: 8),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 50),
                  child: Row(
                    children: [
                      if (kIsAndroid || (kIsBrowser && MediaQuery.of(context).size.width < 768)) ...[
                        Gap(size: 12),
                        InkIcon(
                          icon: CupertinoIcons.sidebar_left,
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ],
                      const ModelSelector(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildDefaultToolbarActions(context),
      ],
    );
  }

  Widget _buildDefaultToolbarActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width < 400 ? 30 : 120),
          child: UpgradeNotice(),
        ),
        if (ProviderManager.chatProvider.activeChat != null) ...[
          Gap(size: 8),
          InkIcon(
            icon: CupertinoIcons.add,
            onTap: () {
              ProviderManager.chatProvider.clearActiveChat();
            },
            tooltip: AppLocalizations.of(context)!.newChat,
          ),
        ],
        if (kIsWindows || kIsLinux) ...[const Gap(size: 8), const WindowControls()],
        _buildMoreMenu(context),
      ],
    );
  }
}

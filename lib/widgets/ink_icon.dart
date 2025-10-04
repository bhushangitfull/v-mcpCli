import 'package:flutter/material.dart';
import 'package:chatmcp/utils/color.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class InkIcon extends StatelessWidget {
  final IconData icon;
  final void Function()? onTap;
  final bool disabled;
  final Color? hoverColor;
  final String? tooltip;
  final Color? color;
  final double? size;
  final String? text;
  final Widget? child;
  const InkIcon({
    super.key,
    required this.icon,
    this.onTap,
    this.disabled = false,
    this.hoverColor,
    this.tooltip,
    this.color,
    this.size = 16,
    this.text,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveSize = size != 16
        ? size!
        : (kIsWeb
              ? 16.0
              : (Platform.isAndroid || Platform.isIOS)
              ? 24.0
              : 16.0);

    final Widget iconWidget = Material(
      color: const Color.fromARGB(0, 64, 218, 230),
      child: InkWell(
        onTap: disabled ? null : onTap,
        hoverColor: hoverColor ?? AppColors.getInkIconHoverColor(context),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Icon(
                icon,
                size: effectiveSize,
                color: color ?? Theme.of(context).iconTheme.color ?? const Color.fromARGB(255, 51, 219, 241),
              ),
              if (text != null) Text(text!),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return iconWidget;
    }

    return Tooltip(message: tooltip!, child: iconWidget);
  }
}

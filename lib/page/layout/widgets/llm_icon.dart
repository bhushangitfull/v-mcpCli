import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class LlmIcon extends StatelessWidget {
  final String icon;
  final Color? color;
  final double size;
  final String? tooltip;

  const LlmIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 16, 
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
   
    final double effectiveSize = size != 16
        ? size
        : (kIsWeb
              ? 16.0
              : (Platform.isAndroid || Platform.isIOS)
              ? 24.0
              : 16.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : Colors.black;

    final Widget iconWidget;
    if (icon.isNotEmpty) {
      iconWidget = ColorAwareSvg(assetName: 'assets/logo/$icon.svg', size: effectiveSize, color: color ?? defaultColor);
    } else {
      iconWidget = ColorAwareSvg(assetName: 'assets/logo/ai-chip.svg', size: effectiveSize, color: color ?? defaultColor);
    }

    if (tooltip == null) {
      return iconWidget;
    }

    return Tooltip(message: tooltip!, child: iconWidget);
  }
}

class ColorAwareSvg extends StatelessWidget {
  final String assetName;
  final double size;
  final Color color;

  
  static final Map<String, bool> _colorCache = {};

  const ColorAwareSvg({super.key, required this.assetName, required this.size, required this.color});

  
  Future<bool> _detectSvgHasColors(BuildContext context) async {

    if (_colorCache.containsKey(assetName)) {
      return _colorCache[assetName]!;
    }

    try {
   
      final String svgString = await rootBundle.loadString(assetName);

      bool hasColor = false;

   
      if (svgString.contains('fill="#') || svgString.contains('stroke="#')) {
      
        hasColor =
            !svgString.contains('fill="#000000"') &&
            !svgString.contains('fill="#ffffff"') &&
            !svgString.contains('stroke="#000000"') &&
            !svgString.contains('stroke="#ffffff"');
      }

     
      if (!hasColor) {
        hasColor =
            svgString.contains('fill="rgb') ||
            svgString.contains('stroke="rgb') ||
            svgString.contains('fill="hsl') ||
            svgString.contains('stroke="hsl');
      }

      if (svgString.contains("style") || svgString.contains("color")) {
        hasColor = true;
      }

      _colorCache[assetName] = hasColor;
      return hasColor;
    } catch (e) {
    
      _colorCache[assetName] = false;
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
     
      future: _detectSvgHasColors(context),
      builder: (context, snapshot) {
       
        if (!snapshot.hasData) {
          return SizedBox(width: size, height: size, child: const CircularProgressIndicator(strokeWidth: 2));
        }

     
        final hasOwnColors = snapshot.data ?? false;
        return SvgPicture.asset(
          assetName,
          width: size,
          height: size,
          allowDrawingOutsideViewBox: true,
          placeholderBuilder: (context) => Icon(CupertinoIcons.cloud, size: size),
          colorFilter: hasOwnColors ? null : ColorFilter.mode(color, BlendMode.srcIn),
        );
      },
    );
  }
}

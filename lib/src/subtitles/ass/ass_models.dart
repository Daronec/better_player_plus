import 'package:flutter/material.dart';

/// ASS Style definition
class AssStyle {
  const AssStyle({
    required this.name,
    this.fontName = 'Arial',
    this.fontSize = 20.0,
    this.primaryColor = Colors.white,
    this.secondaryColor = Colors.yellow,
    this.outlineColor = Colors.black,
    this.shadowColor = Colors.black,
    this.backColor = Colors.transparent,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikeOut = false,
    this.scaleX = 100.0,
    this.scaleY = 100.0,
    this.spacing = 0.0,
    this.angle = 0.0,
    this.borderStyle = 1,
    this.outlineWidth = 2.0,
    this.shadowDepth = 2.0,
    this.alignment = 2, // Bottom center
    this.marginL = 10,
    this.marginR = 10,
    this.marginV = 10,
    this.encoding = 1,
  });

  final String name;
  final String fontName;
  final double fontSize;
  final Color primaryColor;
  final Color secondaryColor;
  final Color outlineColor;
  final Color shadowColor;
  final Color backColor;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikeOut;
  final double scaleX;
  final double scaleY;
  final double spacing;
  final double angle;
  final int borderStyle;
  final double outlineWidth;
  final double shadowDepth;
  final int alignment; // 1-9: bottom-left to top-right
  final int marginL;
  final int marginR;
  final int marginV;
  final int encoding;

  Alignment get alignmentFlutter {
    switch (alignment) {
      case 1:
        return Alignment.bottomLeft;
      case 2:
        return Alignment.bottomCenter;
      case 3:
        return Alignment.bottomRight;
      case 4:
        return Alignment.centerLeft;
      case 5:
        return Alignment.center;
      case 6:
        return Alignment.centerRight;
      case 7:
        return Alignment.topLeft;
      case 8:
        return Alignment.topCenter;
      case 9:
        return Alignment.topRight;
      default:
        return Alignment.bottomCenter;
    }
  }
}

/// ASS Tag override (from {\...} tags)
class AssTag {
  const AssTag({
    this.type,
    this.value,
    this.values,
  });

  final String? type; // b, i, u, s, fs, c, 3c, 4c, alpha, pos, move, etc.
  final dynamic value;
  final List<dynamic>? values;
}

/// ASS Event (dialogue line)
class AssEvent {
  const AssEvent({
    required this.layer,
    required this.start,
    required this.end,
    required this.style,
    required this.name,
    required this.marginL,
    required this.marginR,
    required this.marginV,
    required this.effect,
    required this.text,
    this.tags = const [],
  });

  final int layer;
  final Duration start;
  final Duration end;
  final String style;
  final String name;
  final int marginL;
  final int marginR;
  final int marginV;
  final String effect;
  final String text;
  final List<AssTag> tags;
}

/// Rendered ASS line for display
class RenderedAssLine {
  const RenderedAssLine({
    required this.text,
    required this.position,
    required this.style,
    this.karaokeProgress = 1.0,
    this.fadeIn = 0.0,
    this.fadeOut = 0.0,
  });

  final String text;
  final Offset position;
  final AssStyle style;
  final double karaokeProgress; // 0.0 to 1.0
  final double fadeIn; // 0.0 to 1.0
  final double fadeOut; // 0.0 to 1.0
}


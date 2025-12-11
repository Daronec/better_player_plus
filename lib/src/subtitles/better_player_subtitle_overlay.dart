import 'package:flutter/material.dart';

/// Overlay widget for displaying subtitle cues from Android ExoPlayer
class BetterPlayerSubtitleOverlay extends StatelessWidget {
  const BetterPlayerSubtitleOverlay({super.key, required this.text, this.style});

  final String text;
  final BetterPlayerSubtitleOverlayStyle? style;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveStyle = style ?? const BetterPlayerSubtitleOverlayStyle();

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: text.isNotEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Align(
          alignment: effectiveStyle.alignment,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: effectiveStyle.alignment == Alignment.bottomCenter ? effectiveStyle.bottomPadding : 0,
              top: effectiveStyle.alignment == Alignment.topCenter ? effectiveStyle.bottomPadding : 0,
              left: effectiveStyle.horizontalPadding,
              right: effectiveStyle.horizontalPadding,
            ),
            child: Container(
              padding: effectiveStyle.backgroundColor != null
                  ? EdgeInsets.symmetric(horizontal: effectiveStyle.padding, vertical: effectiveStyle.padding / 2)
                  : EdgeInsets.zero,
              decoration: effectiveStyle.backgroundColor != null
                  ? BoxDecoration(
                      color: effectiveStyle.backgroundColor,
                      borderRadius: BorderRadius.circular(effectiveStyle.borderRadius),
                    )
                  : null,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: effectiveStyle.fontSize,
                  height: effectiveStyle.lineHeight,
                  color: effectiveStyle.color,
                  fontWeight: effectiveStyle.fontWeight,
                  fontFamily: effectiveStyle.fontFamily,
                  shadows: effectiveStyle.shadowsEnabled
                      ? [
                          Shadow(
                            color: effectiveStyle.shadowColor,
                            blurRadius: effectiveStyle.shadowBlurRadius,
                            offset: effectiveStyle.shadowOffset,
                          ),
                          Shadow(
                            color: effectiveStyle.shadowColor,
                            blurRadius: effectiveStyle.shadowBlurRadius * 1.5,
                            offset: effectiveStyle.shadowOffset,
                          ),
                          Shadow(color: effectiveStyle.shadowColor, blurRadius: effectiveStyle.outlineWidth),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Style configuration for subtitle overlay
class BetterPlayerSubtitleOverlayStyle {
  const BetterPlayerSubtitleOverlayStyle({
    this.fontSize = 20.0,
    this.color = Colors.white,
    this.fontWeight = FontWeight.w500,
    this.fontFamily,
    this.lineHeight = 1.3,
    this.bottomPadding = 40.0,
    this.horizontalPadding = 16.0,
    this.padding = 8.0,
    this.backgroundColor,
    this.borderRadius = 4.0,
    this.shadowsEnabled = true,
    this.shadowColor = Colors.black,
    this.shadowBlurRadius = 4.0,
    this.shadowOffset = Offset.zero,
    this.alignment = Alignment.bottomCenter,
    this.outlineWidth = 4.0,
  });

  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final String? fontFamily;
  final double lineHeight;
  final double bottomPadding;
  final double horizontalPadding;
  final double padding;
  final Color? backgroundColor;
  final double borderRadius;
  final bool shadowsEnabled;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final Alignment alignment;
  final double outlineWidth;

  BetterPlayerSubtitleOverlayStyle copyWith({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    String? fontFamily,
    double? lineHeight,
    double? bottomPadding,
    double? horizontalPadding,
    double? padding,
    Color? backgroundColor,
    double? borderRadius,
    bool? shadowsEnabled,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    Alignment? alignment,
    double? outlineWidth,
  }) => BetterPlayerSubtitleOverlayStyle(
    fontSize: fontSize ?? this.fontSize,
    color: color ?? this.color,
    fontWeight: fontWeight ?? this.fontWeight,
    fontFamily: fontFamily ?? this.fontFamily,
    lineHeight: lineHeight ?? this.lineHeight,
    bottomPadding: bottomPadding ?? this.bottomPadding,
    horizontalPadding: horizontalPadding ?? this.horizontalPadding,
    padding: padding ?? this.padding,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderRadius: borderRadius ?? this.borderRadius,
    shadowsEnabled: shadowsEnabled ?? this.shadowsEnabled,
    shadowColor: shadowColor ?? this.shadowColor,
    shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
    shadowOffset: shadowOffset ?? this.shadowOffset,
    alignment: alignment ?? this.alignment,
    outlineWidth: outlineWidth ?? this.outlineWidth,
  );
}

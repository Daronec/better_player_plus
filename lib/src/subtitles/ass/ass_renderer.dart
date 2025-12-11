import 'package:better_player_plus/src/subtitles/ass/ass_models.dart';
import 'package:flutter/material.dart';

/// Renders ASS events at a specific time position
class AssRenderer {
  AssRenderer({
    required this.events,
    required this.styles,
    required this.videoWidth,
    required this.videoHeight,
  });

  final List<AssEvent> events;
  final Map<String, AssStyle> styles;
  final double videoWidth;
  final double videoHeight;

  /// Render ASS lines for current position
  List<RenderedAssLine> render(Duration position) {
    final activeEvents = events.where((e) => position >= e.start && position <= e.end).toList();
    if (activeEvents.isEmpty) {
      return [];
    }

    final renderedLines = <RenderedAssLine>[];

    for (final event in activeEvents) {
      final style = styles[event.style] ?? styles.values.first;
      final effectiveStyle = _applyTags(style, event.tags);
      final linePosition = _calculatePosition(effectiveStyle, event);
      final karaokeProgress = _calculateKaraoke(event, position);
      final fade = _calculateFade(event, position);

      renderedLines.add(RenderedAssLine(
        text: event.text,
        position: linePosition,
        style: effectiveStyle,
        karaokeProgress: karaokeProgress,
        fadeIn: fade.fadeIn,
        fadeOut: fade.fadeOut,
      ));
    }

    return renderedLines;
  }

  /// Apply override tags to style
  AssStyle _applyTags(AssStyle baseStyle, List<AssTag> tags) {
    var style = baseStyle;
    
    for (final tag in tags) {
      switch (tag.type) {
        case 'b':
          style = AssStyle(
            name: style.name,
            fontName: style.fontName,
            fontSize: style.fontSize,
            primaryColor: style.primaryColor,
            secondaryColor: style.secondaryColor,
            outlineColor: style.outlineColor,
            shadowColor: style.shadowColor,
            backColor: style.backColor,
            bold: tag.value as bool? ?? style.bold,
            italic: style.italic,
            underline: style.underline,
            strikeOut: style.strikeOut,
            scaleX: style.scaleX,
            scaleY: style.scaleY,
            spacing: style.spacing,
            angle: style.angle,
            borderStyle: style.borderStyle,
            outlineWidth: style.outlineWidth,
            shadowDepth: style.shadowDepth,
            alignment: style.alignment,
            marginL: style.marginL,
            marginR: style.marginR,
            marginV: style.marginV,
            encoding: style.encoding,
          );
        case 'i':
          style = AssStyle(
            name: style.name,
            fontName: style.fontName,
            fontSize: style.fontSize,
            primaryColor: style.primaryColor,
            secondaryColor: style.secondaryColor,
            outlineColor: style.outlineColor,
            shadowColor: style.shadowColor,
            backColor: style.backColor,
            bold: style.bold,
            italic: tag.value as bool? ?? style.italic,
            underline: style.underline,
            strikeOut: style.strikeOut,
            scaleX: style.scaleX,
            scaleY: style.scaleY,
            spacing: style.spacing,
            angle: style.angle,
            borderStyle: style.borderStyle,
            outlineWidth: style.outlineWidth,
            shadowDepth: style.shadowDepth,
            alignment: style.alignment,
            marginL: style.marginL,
            marginR: style.marginR,
            marginV: style.marginV,
            encoding: style.encoding,
          );
        case 'fs':
          style = AssStyle(
            name: style.name,
            fontName: style.fontName,
            fontSize: tag.value as double? ?? style.fontSize,
            primaryColor: style.primaryColor,
            secondaryColor: style.secondaryColor,
            outlineColor: style.outlineColor,
            shadowColor: style.shadowColor,
            backColor: style.backColor,
            bold: style.bold,
            italic: style.italic,
            underline: style.underline,
            strikeOut: style.strikeOut,
            scaleX: style.scaleX,
            scaleY: style.scaleY,
            spacing: style.spacing,
            angle: style.angle,
            borderStyle: style.borderStyle,
            outlineWidth: style.outlineWidth,
            shadowDepth: style.shadowDepth,
            alignment: style.alignment,
            marginL: style.marginL,
            marginR: style.marginR,
            marginV: style.marginV,
            encoding: style.encoding,
          );
        case 'c':
        case '1c':
          if (tag.value is Color) {
            style = AssStyle(
              name: style.name,
              fontName: style.fontName,
              fontSize: style.fontSize,
              primaryColor: tag.value as Color,
              secondaryColor: style.secondaryColor,
              outlineColor: style.outlineColor,
              shadowColor: style.shadowColor,
              backColor: style.backColor,
              bold: style.bold,
              italic: style.italic,
              underline: style.underline,
              strikeOut: style.strikeOut,
              scaleX: style.scaleX,
              scaleY: style.scaleY,
              spacing: style.spacing,
              angle: style.angle,
              borderStyle: style.borderStyle,
              outlineWidth: style.outlineWidth,
              shadowDepth: style.shadowDepth,
              alignment: style.alignment,
              marginL: style.marginL,
              marginR: style.marginR,
              marginV: style.marginV,
              encoding: style.encoding,
            );
          }
        case '3c':
          if (tag.value is Color) {
            style = AssStyle(
              name: style.name,
              fontName: style.fontName,
              fontSize: style.fontSize,
              primaryColor: style.primaryColor,
              secondaryColor: style.secondaryColor,
              outlineColor: tag.value as Color,
              shadowColor: style.shadowColor,
              backColor: style.backColor,
              bold: style.bold,
              italic: style.italic,
              underline: style.underline,
              strikeOut: style.strikeOut,
              scaleX: style.scaleX,
              scaleY: style.scaleY,
              spacing: style.spacing,
              angle: style.angle,
              borderStyle: style.borderStyle,
              outlineWidth: style.outlineWidth,
              shadowDepth: style.shadowDepth,
              alignment: style.alignment,
              marginL: style.marginL,
              marginR: style.marginR,
              marginV: style.marginV,
              encoding: style.encoding,
            );
          }
      }
    }

    return style;
  }

  /// Calculate position from tags or style alignment
  Offset _calculatePosition(AssStyle style, AssEvent event) {
    // Check for \pos tag
    final posTag = event.tags.firstWhere(
      (t) => t.type == 'pos',
      orElse: () => const AssTag(),
    );
    
    if (posTag.values != null && posTag.values!.length >= 2) {
      // Absolute positioning
      return Offset(posTag.values![0], posTag.values![1]);
    }

    // Check for \move tag
    final moveTag = event.tags.firstWhere(
      (t) => t.type == 'move',
      orElse: () => const AssTag(),
    );
    
    if (moveTag.values != null && moveTag.values!.length >= 4) {
      // Animated movement (simplified - use start position)
      return Offset(moveTag.values![0], moveTag.values![1]);
    }

    // Use alignment-based positioning
    final alignment = style.alignmentFlutter;
    double x = videoWidth / 2;
    double y = videoHeight - style.marginV - 50;

    if (alignment == Alignment.bottomLeft || 
        alignment == Alignment.centerLeft || 
        alignment == Alignment.topLeft) {
      x = style.marginL.toDouble();
    } else if (alignment == Alignment.bottomRight || 
               alignment == Alignment.centerRight || 
               alignment == Alignment.topRight) {
      x = videoWidth - style.marginR.toDouble();
    }

    if (alignment == Alignment.topLeft || 
        alignment == Alignment.topCenter || 
        alignment == Alignment.topRight) {
      y = style.marginV.toDouble() + 50;
    } else if (alignment == Alignment.centerLeft || 
               alignment == Alignment.center || 
               alignment == Alignment.centerRight) {
      y = videoHeight / 2;
    }

    return Offset(x, y);
  }

  /// Calculate karaoke progress
  double _calculateKaraoke(AssEvent event, Duration currentPosition) {
    // Find karaoke tags (\k, \K, \kf, \ko)
    final karaokeTags = event.tags.where((t) => t.type == 'k').toList();
    if (karaokeTags.isEmpty) {
      return 1;
    }

    // Simplified karaoke - return full progress for now
    // Full implementation would track cumulative karaoke timing
    return 1;
  }

  /// Calculate fade in/out
  _FadeResult _calculateFade(AssEvent event, Duration currentPosition) {
    final fadeTag = event.tags.firstWhere(
      (t) => t.type == 'fade',
      orElse: () => const AssTag(),
    );

    if (fadeTag.values == null || fadeTag.values!.length < 2) {
      return const _FadeResult(fadeIn: 1, fadeOut: 1);
    }

    final fadeInMs = fadeTag.values![0] as int;
    final fadeOutMs = fadeTag.values!.length > 2 ? fadeTag.values![2] as int : fadeTag.values![1] as int;

    final elapsed = currentPosition - event.start;
    final totalDuration = event.end - event.start;

    double fadeIn = 1;
    if (fadeInMs > 0 && elapsed.inMilliseconds < fadeInMs) {
      fadeIn = elapsed.inMilliseconds / fadeInMs;
    }

    double fadeOut = 1;
    if (fadeOutMs > 0) {
      final fadeOutStart = totalDuration.inMilliseconds - fadeOutMs;
      if (elapsed.inMilliseconds > fadeOutStart) {
        fadeOut = 1 - ((elapsed.inMilliseconds - fadeOutStart) / fadeOutMs);
      }
    }

    return _FadeResult(fadeIn: fadeIn, fadeOut: fadeOut);
  }
}

class _FadeResult {
  const _FadeResult({required this.fadeIn, required this.fadeOut});
  final double fadeIn;
  final double fadeOut;
}


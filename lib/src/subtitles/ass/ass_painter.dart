import 'package:better_player_plus/src/subtitles/ass/ass_models.dart';
import 'package:flutter/material.dart';

/// Custom painter for rendering ASS subtitles
class AssPainter extends CustomPainter {
  AssPainter({
    required this.lines,
    required this.videoSize,
  });

  final List<RenderedAssLine> lines;
  final Size videoSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (lines.isEmpty) {
      return;
    }

    // Scale factor for video size to canvas size
    final scaleX = size.width / videoSize.width;
    final scaleY = size.height / videoSize.height;

    for (final line in lines) {
      final opacity = line.fadeIn * line.fadeOut;
      if (opacity <= 0) {
        continue;
      }

      // Scale position
      final scaledPosition = Offset(
        line.position.dx * scaleX,
        line.position.dy * scaleY,
      );

      _drawLine(canvas, line, scaledPosition, opacity);
    }
  }

  void _drawLine(Canvas canvas, RenderedAssLine line, Offset position, double opacity) {
    final style = line.style;
    
    // Create text style
    final textStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      decoration: style.underline 
          ? TextDecoration.underline 
          : (style.strikeOut ? TextDecoration.lineThrough : TextDecoration.none),
      color: style.primaryColor.withOpacity(opacity),
      fontFamily: style.fontName,
      letterSpacing: style.spacing,
    );

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: line.text,
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    // Calculate text position based on alignment
    final textOffset = _calculateTextOffset(position, textPainter.size, style.alignmentFlutter);

    // Draw outline/shadow
    if (style.outlineWidth > 0) {
      _drawOutline(canvas, textPainter, textOffset, style, opacity);
    }

    // Draw shadow
    if (style.shadowDepth > 0) {
      _drawShadow(canvas, textPainter, textOffset, style, opacity);
    }

    // Draw main text
    final mainTextStyle = textStyle.copyWith(
      color: style.primaryColor.withOpacity(opacity),
    );
    
    TextPainter(
      text: TextSpan(text: line.text, style: mainTextStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout()
     ..paint(canvas, textOffset);

    // Draw karaoke effect if needed
    if (line.karaokeProgress < 1.0) {
      _drawKaraoke(canvas, textPainter, textOffset, line, style, opacity);
    }
  }

  void _drawOutline(Canvas canvas, TextPainter textPainter, Offset offset, AssStyle style, double opacity) {
    // Draw outline in multiple directions for better coverage
    for (var dx = -style.outlineWidth; dx <= style.outlineWidth; dx += style.outlineWidth / 2) {
      for (var dy = -style.outlineWidth; dy <= style.outlineWidth; dy += style.outlineWidth / 2) {
        if (dx == 0 && dy == 0) {
          continue;
        }
        textPainter.paint(canvas, offset + Offset(dx, dy));
      }
    }
  }

  void _drawShadow(Canvas canvas, TextPainter textPainter, Offset offset, AssStyle style, double opacity) {
    textPainter.paint(canvas, offset + Offset(style.shadowDepth, style.shadowDepth));
  }

  void _drawKaraoke(Canvas canvas, TextPainter textPainter, Offset offset, RenderedAssLine line, AssStyle style, double opacity) {
    // Simplified karaoke - draw secondary color for unhighlighted portion
    final progress = line.karaokeProgress;
    if (progress <= 0) {
      return;
    }

    final textWidth = textPainter.width;
    final highlightWidth = textWidth * progress;

    // Draw unhighlighted portion
    final unhighlightedRect = Rect.fromLTWH(offset.dx, offset.dy, textWidth - highlightWidth, textPainter.height);
    canvas
      ..save()
      ..clipRect(unhighlightedRect);
    
    final unhighlightedStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      color: style.secondaryColor.withOpacity(opacity),
      fontFamily: style.fontName,
    );
    
    TextPainter(
      text: TextSpan(text: line.text, style: unhighlightedStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout()
     ..paint(canvas, offset);
    canvas.restore();
  }

  Offset _calculateTextOffset(Offset position, Size textSize, Alignment alignment) {
    double x = position.dx;
    double y = position.dy;

    // Adjust based on alignment
    if (alignment == Alignment.bottomCenter || 
        alignment == Alignment.center || 
        alignment == Alignment.topCenter) {
      x -= textSize.width / 2;
    } else if (alignment == Alignment.bottomRight || 
               alignment == Alignment.centerRight || 
               alignment == Alignment.topRight) {
      x -= textSize.width;
    }

    y -= textSize.height;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant AssPainter oldDelegate) =>
      oldDelegate.lines != lines || oldDelegate.videoSize != videoSize;
}


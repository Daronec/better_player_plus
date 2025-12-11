import 'package:better_player_plus/src/subtitles/ass/ass_cache.dart';
import 'package:better_player_plus/src/subtitles/ass/ass_models.dart';
import 'package:flutter/material.dart';

/// Optimized painter using cached images for hardware acceleration
class AssOptimizedPainter extends CustomPainter {
  AssOptimizedPainter({
    required this.lines,
    required this.videoSize,
    required this.cache,
    required this.devicePixelRatio,
  });

  final List<RenderedAssLine> lines;
  final Size videoSize;
  final AssImageCache cache;
  final double devicePixelRatio;

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

      _drawLine(canvas, line, scaledPosition, opacity, size);
    }
  }

  void _drawLine(
    Canvas canvas,
    RenderedAssLine line,
    Offset position,
    double opacity,
    Size canvasSize,
  ) {
    final style = line.style;
    
    // Generate cache key
    final cacheKey = AssCacheKey.generate(
      text: line.text,
      fontFamily: style.fontName,
      fontSize: style.fontSize,
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      color: style.primaryColor,
      outlineColor: style.outlineColor,
      outlineWidth: style.outlineWidth,
      shadowColor: style.shadowColor,
      shadowDepth: style.shadowDepth,
      devicePixelRatio: devicePixelRatio,
      bold: style.bold,
      italic: style.italic,
    );

    // Try to get cached image
    var cachedImage = cache.get(cacheKey);
    
    if (cachedImage == null) {
      // Build picture and rasterize (synchronous, but should be pre-cached)
      _buildAndCacheImage(cacheKey, line, style);
      cachedImage = cache.get(cacheKey);
    }

    if (cachedImage == null) {
      // Fallback to direct rendering if cache miss
      _drawLineFallback(canvas, line, position, opacity);
      return;
    }

    // Draw cached image with transformations
    canvas.save();
    
    // Apply opacity
    if (opacity < 1.0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }

    // Calculate text offset based on alignment
    final textOffset = _calculateTextOffset(
      position,
      Size(cachedImage.width.toDouble() / devicePixelRatio, cachedImage.height.toDouble() / devicePixelRatio),
      style.alignmentFlutter,
    );

    // Draw image
    final paint = Paint()..isAntiAlias = true;
    canvas.drawImage(
      cachedImage,
      textOffset,
      paint,
    );

    // Draw karaoke effect if needed
    if (line.karaokeProgress < 1.0) {
      _drawKaraokeOptimized(canvas, line, textOffset, style, opacity);
    }

    canvas.restore();
  }

  void _buildAndCacheImage(String cacheKey, RenderedAssLine line, AssStyle style) {
    // Build text style
    final textStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      color: style.primaryColor,
      fontFamily: style.fontName,
      letterSpacing: style.spacing,
    );

    // Build picture
    AssPictureBuilder.buildPicture(
      text: line.text,
      textStyle: textStyle,
      outlineColor: style.outlineColor,
      outlineWidth: style.outlineWidth,
      shadowColor: style.shadowColor,
      shadowDepth: style.shadowDepth,
      devicePixelRatio: devicePixelRatio,
    ).then((picture) {
      // Calculate size
      final textPainter = TextPainter(
        text: TextSpan(text: line.text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      
      final padding = (style.outlineWidth + style.shadowDepth) * 2;
      final width = (textPainter.size.width + padding) * devicePixelRatio;
      final height = (textPainter.size.height + padding) * devicePixelRatio;

      // Rasterize to image
      AssPictureBuilder.rasterize(picture, width, height).then((image) {
        // Cache image
        cache.put(cacheKey, image, picture);
      });
    });
  }

  void _drawKaraokeOptimized(
    Canvas canvas,
    RenderedAssLine line,
    Offset baseOffset,
    AssStyle style,
    double opacity,
  ) {
    if (line.karaokeProgress <= 0) {
      return;
    }

    // Generate karaoke highlight cache key
    final karaokeKey = AssCacheKey.generateKaraoke(
      text: line.text,
      fontFamily: style.fontName,
      fontSize: style.fontSize,
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      highlightColor: style.secondaryColor,
      outlineColor: style.outlineColor,
      outlineWidth: style.outlineWidth,
      devicePixelRatio: devicePixelRatio,
      bold: style.bold,
      italic: style.italic,
    );

    final highlightImage = cache.get(karaokeKey);
    
    if (highlightImage == null) {
      // Build karaoke highlight image
      final textStyle = TextStyle(
        fontSize: style.fontSize,
        fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
        color: style.secondaryColor,
        fontFamily: style.fontName,
      );

      AssPictureBuilder.buildPicture(
        text: line.text,
        textStyle: textStyle,
        outlineColor: style.outlineColor,
        outlineWidth: style.outlineWidth,
        shadowColor: Colors.transparent,
        shadowDepth: 0,
        devicePixelRatio: devicePixelRatio,
      ).then((picture) {
        final textPainter = TextPainter(
          text: TextSpan(text: line.text, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        
        final padding = style.outlineWidth * 2;
        final width = (textPainter.size.width + padding) * devicePixelRatio;
        final height = (textPainter.size.height + padding) * devicePixelRatio;

        AssPictureBuilder.rasterize(picture, width, height).then((image) {
          cache.put(karaokeKey, image, picture);
        });
      });
      return;
    }

    // Draw highlighted portion with clip
    final textPainter = TextPainter(
      text: TextSpan(text: line.text),
      textDirection: TextDirection.ltr,
    )..layout();
    
    final textWidth = textPainter.size.width;
    final highlightWidth = textWidth * line.karaokeProgress;

    final paint = Paint()..isAntiAlias = true;
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(
        baseOffset.dx,
        baseOffset.dy,
        highlightWidth,
        textPainter.size.height,
      ))
      ..drawImage(highlightImage, baseOffset, paint)
      ..restore();
  }

  void _drawLineFallback(Canvas canvas, RenderedAssLine line, Offset position, double opacity) {
    // Fallback rendering when cache is not available
    final style = line.style;
    final textStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      color: style.primaryColor.withOpacity(opacity),
      fontFamily: style.fontName,
      letterSpacing: style.spacing,
      shadows: [
        if (style.shadowDepth > 0)
          Shadow(
            color: style.shadowColor.withOpacity(opacity),
            blurRadius: style.shadowDepth,
            offset: Offset(style.shadowDepth, style.shadowDepth),
          ),
      ],
    );

    final textPainter = TextPainter(
      text: TextSpan(text: line.text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final textOffset = _calculateTextOffset(
      position,
      textPainter.size,
      style.alignmentFlutter,
    );

    // Draw outline
    if (style.outlineWidth > 0) {
      // Draw outline in multiple directions
      for (var dx = -style.outlineWidth; dx <= style.outlineWidth; dx += style.outlineWidth / 2) {
        for (var dy = -style.outlineWidth; dy <= style.outlineWidth; dy += style.outlineWidth / 2) {
          if (dx == 0 && dy == 0) {
            continue;
          }
          textPainter.paint(canvas, textOffset + Offset(dx, dy));
        }
      }
    }

    // Draw main text
    textPainter.paint(canvas, textOffset);
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
  bool shouldRepaint(covariant AssOptimizedPainter oldDelegate) {
    // Only repaint if lines changed or cache changed
    if (oldDelegate.lines.length != lines.length) {
      return true;
    }
    for (var i = 0; i < lines.length; i++) {
      if (oldDelegate.lines[i].text != lines[i].text ||
          oldDelegate.lines[i].position != lines[i].position ||
          oldDelegate.lines[i].karaokeProgress != lines[i].karaokeProgress ||
          oldDelegate.lines[i].fadeIn != lines[i].fadeIn ||
          oldDelegate.lines[i].fadeOut != lines[i].fadeOut) {
        return true;
      }
    }
    return oldDelegate.devicePixelRatio != devicePixelRatio;
  }
}


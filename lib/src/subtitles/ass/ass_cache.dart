import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// LRU cache entry for subtitle images
class _CacheEntry {
  _CacheEntry({
    required this.image,
    required this.size,
    required this.picture,
    required this.timestamp,
  });

  final ui.Image image;
  final int size; // bytes (width * height * 4 for RGBA)
  final ui.Picture picture;
  final DateTime timestamp;
}

/// LRU cache for ASS subtitle images with memory management
class AssImageCache {
  AssImageCache({
    this.maxBytes = 32 * 1024 * 1024, // 32MB default
  });

  final int maxBytes;
  int _currentBytes = 0;
  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap<String, _CacheEntry>();

  /// Get cached image by key
  ui.Image? get(String key) {
    final entry = _cache.remove(key);
    if (entry == null) {
      return null;
    }
    
    // Move to end (most recently used)
    _cache[key] = entry;
    return entry.image;
  }

  /// Get cached picture by key
  ui.Picture? getPicture(String key) {
    final entry = _cache[key];
    return entry?.picture;
  }

  /// Put image into cache
  void put(String key, ui.Image image, ui.Picture picture) {
    final size = (image.width * image.height * 4).toInt(); // RGBA
    
    if (size > maxBytes) {
      // Too big to cache
      image.dispose();
      return;
    }

    // Evict oldest entries if needed
    while (_currentBytes + size > maxBytes && _cache.isNotEmpty) {
      final oldestKey = _cache.keys.first;
      final oldest = _cache.remove(oldestKey)!;
      _currentBytes -= oldest.size;
      oldest.image.dispose();
    }

    // Remove existing entry if present
    final existing = _cache.remove(key);
    if (existing != null) {
      _currentBytes -= existing.size;
      existing.image.dispose();
    }

    _cache[key] = _CacheEntry(
      image: image,
      size: size,
      picture: picture,
      timestamp: DateTime.now(),
    );
    _currentBytes += size;
  }

  /// Clear all cached entries
  void clear() {
    for (final entry in _cache.values) {
      entry.image.dispose();
    }
    _cache.clear();
    _currentBytes = 0;
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() => {
        'size': _cache.length,
        'bytes': _currentBytes,
        'maxBytes': maxBytes,
        'usagePercent': (_currentBytes / maxBytes * 100).toStringAsFixed(1),
      };

  /// Dispose cache
  void dispose() {
    clear();
  }
}

/// Cache key generator for ASS subtitle lines
class AssCacheKey {
  /// Private constructor to prevent instantiation
  AssCacheKey._();

  /// Generate cache key for text rendering
  static String generate({
    required String text,
    required String fontFamily,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    required Color outlineColor,
    required double outlineWidth,
    required Color shadowColor,
    required double shadowDepth,
    required double devicePixelRatio,
    bool bold = false,
    bool italic = false,
  }) =>
      '${text.hashCode}_'
          '${fontFamily}_'
          '${fontSize.toStringAsFixed(1)}_'
          '${fontWeight.index}_'
          '${color.value}_'
          '${outlineColor.value}_'
          '${outlineWidth.toStringAsFixed(1)}_'
          '${shadowColor.value}_'
          '${shadowDepth.toStringAsFixed(1)}_'
          '${devicePixelRatio.toStringAsFixed(2)}_'
          '${bold}_'
          '${italic}';

  /// Generate cache key for karaoke highlight
  static String generateKaraoke({
    required String text,
    required String fontFamily,
    required double fontSize,
    required FontWeight fontWeight,
    required Color highlightColor,
    required Color outlineColor,
    required double outlineWidth,
    required double devicePixelRatio,
    bool bold = false,
    bool italic = false,
  }) =>
      'karaoke_${generate(
        text: text,
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: highlightColor,
        outlineColor: outlineColor,
        outlineWidth: outlineWidth,
        shadowColor: Colors.transparent,
        shadowDepth: 0,
        devicePixelRatio: devicePixelRatio,
        bold: bold,
        italic: italic,
      )}';
}

/// Picture builder for ASS subtitle text
class AssPictureBuilder {
  /// Private constructor to prevent instantiation
  AssPictureBuilder._();

  /// Build picture for text with outline and shadow
  static Future<ui.Picture> buildPicture({
    required String text,
    required TextStyle textStyle,
    required Color outlineColor,
    required double outlineWidth,
    required Color shadowColor,
    required double shadowDepth,
    required double devicePixelRatio,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final padding = (outlineWidth + shadowDepth) * 2;
    final baseOffset = Offset(padding / 2, padding / 2);

    // Draw shadow
    if (shadowDepth > 0) {
      canvas
        ..save()
        ..translate(baseOffset.dx + shadowDepth, baseOffset.dy + shadowDepth);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Draw outline (multiple passes for better coverage)
    if (outlineWidth > 0) {
      // Draw outline in multiple directions
      final offsets = [
        Offset(-outlineWidth, 0),
        Offset(outlineWidth, 0),
        Offset(0, -outlineWidth),
        Offset(0, outlineWidth),
        Offset(-outlineWidth, -outlineWidth),
        Offset(outlineWidth, outlineWidth),
        Offset(-outlineWidth, outlineWidth),
        Offset(outlineWidth, -outlineWidth),
      ];

      for (final offset in offsets) {
        canvas
          ..save()
          ..translate(baseOffset.dx + offset.dx, baseOffset.dy + offset.dy);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }

    // Draw main text
    canvas
      ..save()
      ..translate(baseOffset.dx, baseOffset.dy);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    return recorder.endRecording();
  }

  /// Rasterize picture to image at specific size
  static Future<ui.Image> rasterize(
    ui.Picture picture,
    double width,
    double height,
  ) =>
      picture.toImage(width.toInt(), height.toInt());
}


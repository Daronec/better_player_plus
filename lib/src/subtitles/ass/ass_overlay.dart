import 'package:better_player_plus/src/subtitles/ass/ass_cache.dart';
import 'package:better_player_plus/src/subtitles/ass/ass_models.dart';
import 'package:better_player_plus/src/subtitles/ass/ass_optimized_painter.dart';
import 'package:better_player_plus/src/subtitles/ass/ass_painter.dart';
import 'package:flutter/material.dart';

/// Overlay widget for displaying ASS subtitles with hardware acceleration
class AssOverlay extends StatefulWidget {
  const AssOverlay({
    super.key,
    required this.lines,
    required this.videoSize,
    this.useOptimizedPainter = true,
    this.cache,
  });

  final List<RenderedAssLine> lines;
  final Size videoSize;
  final bool useOptimizedPainter;
  final AssImageCache? cache;

  @override
  State<AssOverlay> createState() => _AssOverlayState();
}

class _AssOverlayState extends State<AssOverlay> {
  late AssImageCache _cache;
  double _devicePixelRatio = 1;

  @override
  void initState() {
    super.initState();
    _cache = widget.cache ?? AssImageCache();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
  }

  @override
  void didUpdateWidget(AssOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cache != null && widget.cache != oldWidget.cache) {
      _cache = widget.cache!;
    }
  }

  @override
  void dispose() {
    if (widget.cache == null) {
      _cache.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: widget.useOptimizedPainter
              ? AssOptimizedPainter(
                  lines: widget.lines,
                  videoSize: widget.videoSize,
                  cache: _cache,
                  devicePixelRatio: _devicePixelRatio,
                )
              : AssPainter(
                  lines: widget.lines,
                  videoSize: widget.videoSize,
                ),
          size: Size.infinite,
        ),
      ),
    );
  }
}


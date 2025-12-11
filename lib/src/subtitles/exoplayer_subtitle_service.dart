import 'dart:async';

import 'package:flutter/services.dart';

/// Канал общается с Android ExoPlayerSubtitlePlugin
const _channel = MethodChannel("com.media.video.music.player/subtitles");

/// Канал для вызова методов BetterPlayer напрямую
const _betterPlayerChannel = MethodChannel("better_player_channel");

/// Поток событий субтитров
const _eventChannel = EventChannel("com.media.video.music.player/subtitles_events");

class ExoPlayerSubtitleService {
  ExoPlayerSubtitleService._internal();

  static final ExoPlayerSubtitleService instance = ExoPlayerSubtitleService._internal();

  StreamController<String>? _cueStreamController;
  Stream<String>? _subtitleCuesStream;
  StreamSubscription<dynamic>? _eventSubscription;
  bool _listening = false;

  Stream<String> get subtitleCues {
    if (_subtitleCuesStream == null) {
      _cueStreamController = StreamController<String>.broadcast();
      _subtitleCuesStream = _cueStreamController!.stream;
    }
    return _subtitleCuesStream!;
  }

  Future<List<Map<String, dynamic>>> getEmbeddedSubtitles() async {
    try {
      final result = await _channel.invokeMethod("getEmbeddedSubtitles");
      return (result as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<bool> selectSubtitle(int group, int track) async {
    try {
      return await _channel.invokeMethod("selectSubtitle", {
        "group": group,
        "track": track,
      }) as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disableSubtitles() async {
    try {
      return await _channel.invokeMethod("disableSubtitles") as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> addExternalSubtitle({
    required String url,
    String? language,
    String? label,
    String? mimeType = "text/vtt",
    int? textureId,
  }) async {
    try {
      // Try BetterPlayer channel first (requires textureId)
      if (textureId != null) {
        await _betterPlayerChannel.invokeMethod("addExternalSubtitle", {
          "textureId": textureId,
          "url": url,
          "language": language,
          "label": label,
          "mimeType": mimeType,
        });
      } else {
        // Fallback: try ExoPlayerSubtitlePlugin channel (may not work without textureId)
        await _channel.invokeMethod("addExternalSubtitle", {
          "url": url,
          "language": language,
          "label": label,
          "mimeType": mimeType,
        });
      }
    } catch (e) {
      // Ignore errors if method not available
    }
  }

  /// Запуск прослушки cue событий
  void startCueListener() {
    if (_listening) {
      return;
    }
    _listening = true;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map && event["event"] == "subtitleCue") {
          final text = event["text"] as String? ?? "";
          _cueStreamController?.add(text);
        }
      },
      onError: (error) {
        // Ignore errors
      },
    );
  }

  void stopCueListener() {
    _listening = false;
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  void dispose() {
    stopCueListener();
    _cueStreamController?.close();
    _cueStreamController = null;
    _subtitleCuesStream = null;
  }
}


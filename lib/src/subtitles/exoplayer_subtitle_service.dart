import 'dart:async';

import 'package:flutter/services.dart';

/// Канал для вызова методов BetterPlayer напрямую
const _betterPlayerChannel = MethodChannel("better_player_channel");

/// Поток событий субтитров через BetterPlayer
const _eventChannel = EventChannel("better_player_channel/videoEvents");

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

  Future<List<Map<String, dynamic>>> getEmbeddedSubtitles({int? textureId}) async {
    try {
      final result = await _betterPlayerChannel.invokeMethod(
        "getSubtitleTracks",
        {"textureId": textureId},
      );
      if (result == null) {
        return [];
      }
      return (result as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<bool> selectSubtitle(int group, int track, {int? textureId}) async {
    try {
      return await _betterPlayerChannel.invokeMethod(
        "setSubtitleTrack",
        {
          "textureId": textureId,
          "groupIndex": group,
          "trackIndex": track,
        },
      ) as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disableSubtitles({int? textureId}) async {
    try {
      return await _betterPlayerChannel.invokeMethod(
        "disableSubtitles",
        {"textureId": textureId},
      ) as bool? ?? false;
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
        // Fallback: try without textureId (may not work)
        await _betterPlayerChannel.invokeMethod("addExternalSubtitle", {
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


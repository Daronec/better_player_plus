import 'dart:ui' show PlatformDispatcher;

/// Automatic subtitle track selector with smart logic
class BetterPlayerSubtitleAutoSelector {
  /// Private constructor to prevent instantiation
  BetterPlayerSubtitleAutoSelector._();

  /// Select the best subtitle track automatically
  /// 
  /// Priority order:
  /// 1. Saved track (if exists)
  /// 2. Forced tracks
  /// 3. Default tracks
  /// 4. Device language tracks
  /// 5. Russian tracks
  /// 6. English tracks
  /// 7. ASS format
  /// 8. SRT format
  /// 9. VTT format
  /// 10. First available track
  static Map<String, dynamic>? selectAutoTrack(
    List<Map<String, dynamic>> tracks,
    String? savedTrackId,
  ) {
    if (tracks.isEmpty) {
      return null;
    }

    // 1. Saved track overrides everything
    if (savedTrackId != null) {
      try {
        final savedTrack = tracks.firstWhere(
          (t) => t['id'] == savedTrackId,
          orElse: () => <String, dynamic>{},
        );
        if (savedTrack.isNotEmpty) {
          return savedTrack;
        }
      } catch (e) {
        // Track not found, continue with auto selection
      }
    }

    // 2. Forced tracks
    final forced = tracks.where((t) => t['isForced'] == true).toList();
    if (forced.isNotEmpty) {
      return forced.first;
    }

    // 3. Default tracks
    final defaults = tracks.where((t) => t['isDefault'] == true).toList();
    if (defaults.isNotEmpty) {
      return defaults.first;
    }

    // 4. Device language
    try {
      final deviceLang = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      final byDeviceLang = tracks.where(
        (t) {
          final lang = (t['language'] as String? ?? '').toLowerCase();
          return lang.startsWith(deviceLang) || lang == deviceLang;
        },
      ).toList();
      if (byDeviceLang.isNotEmpty) {
        return byDeviceLang.first;
      }
    } catch (e) {
      // Ignore locale errors
    }

    // 5. Russian priority
    const ruCodes = ['ru', 'rus', 'russian'];
    final ruTracks = tracks.where((t) {
      final lang = (t['language'] as String? ?? '').toLowerCase();
      return ruCodes.any((code) => lang.startsWith(code) || lang == code);
    }).toList();
    if (ruTracks.isNotEmpty) {
      return ruTracks.first;
    }

    // 6. English fallback
    const enCodes = ['en', 'eng', 'english'];
    final enTracks = tracks.where((t) {
      final lang = (t['language'] as String? ?? '').toLowerCase();
      return enCodes.any((code) => lang.startsWith(code) || lang == code);
    }).toList();
    if (enTracks.isNotEmpty) {
      return enTracks.first;
    }

    // 7-9. Format priorities
    // ASS format
    final ass = tracks.where((t) {
      final mime = (t['mimeType'] as String? ?? '').toLowerCase();
      return mime.contains('ass') || mime.contains('ssa');
    }).toList();
    if (ass.isNotEmpty) {
      return ass.first;
    }

    // SRT format
    final srt = tracks.where((t) {
      final mime = (t['mimeType'] as String? ?? '').toLowerCase();
      return mime.contains('srt') || mime.contains('subrip');
    }).toList();
    if (srt.isNotEmpty) {
      return srt.first;
    }

    // VTT format
    final vtt = tracks.where((t) {
      final mime = (t['mimeType'] as String? ?? '').toLowerCase();
      return mime.contains('vtt') || mime.contains('webvtt');
    }).toList();
    if (vtt.isNotEmpty) {
      return vtt.first;
    }

    // 10. Final fallback - first available track
    return tracks.first;
  }
}


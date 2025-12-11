import 'dart:convert';

import 'package:better_player_plus/src/subtitles/better_player_subtitle_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage for subtitle preferences using SharedPreferences
class BetterPlayerSubtitlePreferences {
  /// Private constructor to prevent instantiation
  BetterPlayerSubtitlePreferences._();

  static const String _styleKey = 'bp_subtitle_style';
  static const String _selectedTrackKey = 'bp_subtitle_selected_track';

  /// Save subtitle overlay style to preferences
  static Future<void> saveStyle(BetterPlayerSubtitleOverlayStyle style) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_styleKey, jsonEncode({
        'fontSize': style.fontSize,
        'color': style.color.value,
        'outlineColor': style.shadowColor.value,
        'outlineWidth': style.outlineWidth,
        'backgroundColor': style.backgroundColor?.value,
        'fontWeight': _encodeFontWeight(style.fontWeight),
        'alignment': _encodeAlignment(style.alignment),
        'shadowsEnabled': style.shadowsEnabled,
        'shadowBlurRadius': style.shadowBlurRadius,
        'bottomPadding': style.bottomPadding,
        'horizontalPadding': style.horizontalPadding,
        'padding': style.padding,
        'borderRadius': style.borderRadius,
      }));
    } catch (e) {
      // Ignore errors if SharedPreferences not available
    }
  }

  /// Load subtitle overlay style from preferences
  static Future<BetterPlayerSubtitleOverlayStyle?> loadStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_styleKey);
      if (json == null) {
        return null;
      }

      final map = jsonDecode(json) as Map<String, dynamic>;
      return BetterPlayerSubtitleOverlayStyle(
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 20.0,
        color: Color(map['color'] as int? ?? Colors.white.value),
        shadowColor: Color(map['outlineColor'] as int? ?? Colors.black.value),
        outlineWidth: (map['outlineWidth'] as num?)?.toDouble() ?? 4.0,
        backgroundColor: map['backgroundColor'] != null
            ? Color(map['backgroundColor'] as int)
            : null,
        fontWeight: _decodeFontWeight(map['fontWeight'] as int?),
        alignment: _decodeAlignment(map['alignment'] as String?),
        shadowsEnabled: map['shadowsEnabled'] as bool? ?? true,
        shadowBlurRadius: (map['shadowBlurRadius'] as num?)?.toDouble() ?? 4.0,
        bottomPadding: (map['bottomPadding'] as num?)?.toDouble() ?? 40.0,
        horizontalPadding: (map['horizontalPadding'] as num?)?.toDouble() ?? 16.0,
        padding: (map['padding'] as num?)?.toDouble() ?? 8.0,
        borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 4.0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Save selected subtitle track ID
  static Future<void> saveSelectedTrack(String? id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null) {
        await prefs.remove(_selectedTrackKey);
      } else {
        await prefs.setString(_selectedTrackKey, id);
      }
    } catch (e) {
      // Ignore errors if SharedPreferences not available
    }
  }

  /// Load selected subtitle track ID
  static Future<String?> loadSelectedTrack() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedTrackKey);
    } catch (e) {
      return null;
    }
  }

  static String _encodeAlignment(Alignment alignment) {
    if (alignment == Alignment.center) {
      return 'center';
    }
    if (alignment == Alignment.topCenter) {
      return 'top';
    }
    return 'bottom';
  }

  static Alignment _decodeAlignment(String? value) {
    if (value == null) {
      return Alignment.bottomCenter;
    }
    switch (value) {
      case 'center':
        return Alignment.center;
      case 'top':
        return Alignment.topCenter;
      default:
        return Alignment.bottomCenter;
    }
  }

  static int _encodeFontWeight(FontWeight weight) => weight.index;

  static FontWeight _decodeFontWeight(int? index) {
    if (index == null || index < 0 || index >= FontWeight.values.length) {
      return FontWeight.w500;
    }
    return FontWeight.values[index];
  }
}


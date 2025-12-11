import 'package:better_player_plus/src/core/better_player_utils.dart';
import 'package:better_player_plus/src/subtitles/ass/ass_models.dart';
import 'package:flutter/material.dart';

/// Parser for ASS/SSA subtitle files
class AssParser {
  /// Private constructor to prevent instantiation
  AssParser._();

  /// Parse ASS file content into styles and events
  static AssParseResult parse(String content) {
    final lines = content.split('\n');
    final styles = <String, AssStyle>{};
    final events = <AssEvent>[];

    String currentSection = '';
    bool inStylesSection = false;
    bool inEventsSection = false;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith(';') || line.startsWith('!')) {
        continue;
      }

      // Section headers
      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line.substring(1, line.length - 1).toLowerCase();
        inStylesSection = currentSection.contains('style');
        inEventsSection = currentSection.contains('event');
        continue;
      }

      if (inStylesSection && line.toLowerCase().startsWith('format:')) {
        // Skip format line
        continue;
      }

      if (inStylesSection && line.toLowerCase().startsWith('style:')) {
        final style = _parseStyle(line);
        if (style != null) {
          styles[style.name] = style;
        }
      }

      if (inEventsSection && line.toLowerCase().startsWith('dialogue:')) {
        final event = _parseDialogue(line);
        if (event != null) {
          events.add(event);
        }
      }
    }

    return AssParseResult(styles: styles, events: events);
  }

  /// Parse ASS style line
  static AssStyle? _parseStyle(String line) {
    try {
      // Format: Style: Name,Fontname,Fontsize,PrimaryColour,SecondaryColour,OutlineColour,BackColour,Bold,Italic,Underline,StrikeOut,ScaleX,ScaleY,Spacing,Angle,BorderStyle,Outline,Shadow,Alignment,MarginL,MarginR,MarginV,Encoding
      final parts = line.substring(6).split(',');
      if (parts.length < 23) {
        return null;
      }

      return AssStyle(
        name: parts[0].trim(),
        fontName: parts[1].trim(),
        fontSize: double.tryParse(parts[2].trim()) ?? 20.0,
        primaryColor: _parseAssColor(parts[3].trim()),
        secondaryColor: _parseAssColor(parts[4].trim()),
        outlineColor: _parseAssColor(parts[5].trim()),
        shadowColor: _parseAssColor(parts[6].trim()),
        backColor: _parseAssColor(parts[7].trim()),
        bold: parts[8].trim() == '1' || parts[8].trim() == '-1',
        italic: parts[9].trim() == '1' || parts[9].trim() == '-1',
        underline: parts[10].trim() == '1' || parts[10].trim() == '-1',
        strikeOut: parts[11].trim() == '1' || parts[11].trim() == '-1',
        scaleX: double.tryParse(parts[12].trim()) ?? 100.0,
        scaleY: double.tryParse(parts[13].trim()) ?? 100.0,
        spacing: double.tryParse(parts[14].trim()) ?? 0.0,
        angle: double.tryParse(parts[15].trim()) ?? 0.0,
        borderStyle: int.tryParse(parts[16].trim()) ?? 1,
        outlineWidth: double.tryParse(parts[17].trim()) ?? 2.0,
        shadowDepth: double.tryParse(parts[18].trim()) ?? 2.0,
        alignment: int.tryParse(parts[19].trim()) ?? 2,
        marginL: int.tryParse(parts[20].trim()) ?? 10,
        marginR: int.tryParse(parts[21].trim()) ?? 10,
        marginV: int.tryParse(parts[22].trim()) ?? 10,
        encoding: int.tryParse(parts.length > 23 ? parts[23].trim() : '1') ?? 1,
      );
    } catch (e) {
      BetterPlayerUtils.log('Failed to parse ASS style: $e');
      return null;
    }
  }

  /// Parse ASS dialogue line
  static AssEvent? _parseDialogue(String line) {
    try {
      // Format: Dialogue: Layer,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text
      final dialogueStart = line.indexOf(':');
      if (dialogueStart == -1) {
        return null;
      }

      var content = line.substring(dialogueStart + 1);
      final firstComma = content.indexOf(',');
      if (firstComma == -1) {
        return null;
      }

      final layer = int.tryParse(content.substring(0, firstComma).trim()) ?? 0;
      content = content.substring(firstComma + 1);

      // Parse time
      final timeMatch = RegExp(r'(\d+):(\d+):(\d+)\.(\d+)').firstMatch(content);
      if (timeMatch == null) {
        return null;
      }

      final start = Duration(
        hours: int.parse(timeMatch.group(1)!),
        minutes: int.parse(timeMatch.group(2)!),
        seconds: int.parse(timeMatch.group(3)!),
        milliseconds: int.parse(timeMatch.group(4)!) * 10,
      );

      content = content.substring(timeMatch.end);
      if (!content.startsWith(',')) {
        return null;
      }
      content = content.substring(1);

      final endTimeMatch = RegExp(r'(\d+):(\d+):(\d+)\.(\d+)').firstMatch(content);
      if (endTimeMatch == null) {
        return null;
      }

      final end = Duration(
        hours: int.parse(endTimeMatch.group(1)!),
        minutes: int.parse(endTimeMatch.group(2)!),
        seconds: int.parse(endTimeMatch.group(3)!),
        milliseconds: int.parse(endTimeMatch.group(4)!) * 10,
      );

      content = content.substring(endTimeMatch.end);
      if (!content.startsWith(',')) {
        return null;
      }
      content = content.substring(1);

      // Parse remaining fields
      final parts = content.split(',');
      if (parts.length < 9) {
        return null;
      }

      final style = parts[0].trim();
      final name = parts[1].trim();
      final marginL = int.tryParse(parts[2].trim()) ?? 0;
      final marginR = int.tryParse(parts[3].trim()) ?? 0;
      final marginV = int.tryParse(parts[4].trim()) ?? 0;
      final effect = parts[5].trim();
      final text = parts.sublist(6).join(',').trim();

      // Parse override tags from text
      final tags = _parseOverrideTags(text);
      final cleanText = _stripTags(text);

      return AssEvent(
        layer: layer,
        start: start,
        end: end,
        style: style,
        name: name,
        marginL: marginL,
        marginR: marginR,
        marginV: marginV,
        effect: effect,
        text: cleanText,
        tags: tags,
      );
    } catch (e) {
      BetterPlayerUtils.log('Failed to parse ASS dialogue: $e');
      return null;
    }
  }

  /// Parse override tags from text ({\b1\i1\pos(123,200)\c&HAA00FF&})
  static List<AssTag> _parseOverrideTags(String text) {
    final tags = <AssTag>[];
    final tagRegex = RegExp(r'\{([^}]*)\}');
    final matches = tagRegex.allMatches(text);

    for (final match in matches) {
      final tagString = match.group(1)!;
      final parsedTags = _parseTagString(tagString);
      tags.addAll(parsedTags);
    }

    return tags;
  }

  /// Parse individual tag string
  static List<AssTag> _parseTagString(String tagString) {
    final tags = <AssTag>[];
    
    // Match tags like \b1, \i1, \fs50, \pos(200,300), \c&HBBGGRR&
    final tagPattern = RegExp(r'\\([a-zA-Z]+)(?:\(([^)]+)\)|([^\\]+))?');
    final matches = tagPattern.allMatches(tagString);

    for (final match in matches) {
      final type = match.group(1)!;
      final params = match.group(2) ?? match.group(3) ?? '';

      switch (type.toLowerCase()) {
        case 'b':
          tags.add(AssTag(type: 'b', value: params == '1' || params == '-1'));
        case 'i':
          tags.add(AssTag(type: 'i', value: params == '1' || params == '-1'));
        case 'u':
          tags.add(AssTag(type: 'u', value: params == '1' || params == '-1'));
        case 's':
          tags.add(AssTag(type: 's', value: params == '1' || params == '-1'));
        case 'fs':
          tags.add(AssTag(type: 'fs', value: double.tryParse(params) ?? 20.0));
        case 'c':
        case '1c':
          tags.add(AssTag(type: 'c', value: _parseAssColor(params)));
        case '3c':
          tags.add(AssTag(type: '3c', value: _parseAssColor(params)));
        case '4c':
          tags.add(AssTag(type: '4c', value: _parseAssColor(params)));
        case 'alpha':
        case '1a':
          tags.add(AssTag(type: 'alpha', value: _parseAssAlpha(params)));
        case 'pos':
          final posParts = params.split(',');
          if (posParts.length >= 2) {
            tags.add(AssTag(
              type: 'pos',
              values: [
                double.tryParse(posParts[0].trim()) ?? 0.0,
                double.tryParse(posParts[1].trim()) ?? 0.0,
              ],
            ));
          }
        case 'move':
          final moveParts = params.split(',');
          if (moveParts.length >= 4) {
            tags.add(AssTag(
              type: 'move',
              values: moveParts.map((p) => double.tryParse(p.trim()) ?? 0.0).toList(),
            ));
          }
        case 'k':
        case 'kf':
        case 'ko':
          tags.add(AssTag(type: 'k', value: int.tryParse(params) ?? 0));
        case 'fade':
        case 'fad':
          final fadeParts = params.split(',');
          if (fadeParts.length >= 2) {
            tags.add(AssTag(
              type: 'fade',
              values: fadeParts.map((p) => int.tryParse(p.trim()) ?? 0).toList(),
            ));
          }
      }
    }

    return tags;
  }

  /// Strip ASS tags from text
  static String _stripTags(String text) {
    // Remove override tags
    var result = text.replaceAll(RegExp(r'\{[^}]*\}'), '');
    // Remove line breaks markers
    result = result.replaceAll(RegExp(r'\\n'), '\n');
    result = result.replaceAll(RegExp(r'\\N'), '\n');
    return result.trim();
  }

  /// Parse ASS color format (&HBBGGRR& or &HAABBGGRR&)
  static Color _parseAssColor(String colorStr) {
    try {
      if (colorStr.isEmpty) {
        return Colors.white;
      }
      
      // Remove &H and &
      final processedColor = colorStr.replaceAll(RegExp('[&H]'), '').toUpperCase();
      if (processedColor.isEmpty) {
        return Colors.white;
      }

      int value;
      if (processedColor.length == 6) {
        // &HBBGGRR& format
        value = int.parse(processedColor, radix: 16);
        final b = (value & 0xFF0000) >> 16;
        final g = (value & 0x00FF00) >> 8;
        final r = value & 0x0000FF;
        return Color.fromRGBO(r, g, b, 1);
      } else if (processedColor.length == 8) {
        // &HAABBGGRR& format
        value = int.parse(processedColor, radix: 16);
        final a = (value & 0xFF000000) >> 24;
        final b = (value & 0x00FF0000) >> 16;
        final g = (value & 0x0000FF00) >> 8;
        final r = value & 0x000000FF;
        return Color.fromRGBO(r, g, b, 1 - (a / 255));
      }
    } catch (e) {
      BetterPlayerUtils.log('Failed to parse ASS color: $colorStr');
    }
    return Colors.white;
  }

  /// Parse ASS alpha value
  static double _parseAssAlpha(String alphaStr) {
    try {
      final processedAlpha = alphaStr.replaceAll(RegExp('[&H]'), '').toUpperCase();
      if (processedAlpha.isEmpty) {
        return 1;
      }
      final value = int.parse(processedAlpha, radix: 16);
      return 1 - (value / 255);
    } catch (e) {
      return 1;
    }
  }
}

/// Result of ASS parsing
class AssParseResult {
  const AssParseResult({
    required this.styles,
    required this.events,
  });

  final Map<String, AssStyle> styles;
  final List<AssEvent> events;
}


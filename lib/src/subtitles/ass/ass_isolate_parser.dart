import 'package:better_player_plus/src/subtitles/ass/ass_models.dart';
import 'package:better_player_plus/src/subtitles/ass/ass_parser.dart';
import 'package:flutter/foundation.dart';

/// Isolate-based ASS parser for heavy parsing operations
class AssIsolateParser {
  /// Private constructor to prevent instantiation
  AssIsolateParser._();

  /// Parse ASS file in isolate using compute
  static Future<AssParseResult> parseInIsolate(String assContent) =>
      compute(_parseAss, assContent);

  /// Parse ASS content (runs in isolate)
  static AssParseResult _parseAss(String content) => AssParser.parse(content);

  /// Parse ASS file using compute (simpler API)
  static Future<AssParseResult> parseAsync(String assContent) =>
      compute(_parseAss, assContent);
}

/// Serializable representation of AssEvent for isolate communication
class SerializableAssEvent {
  SerializableAssEvent({
    required this.layer,
    required this.startMs,
    required this.endMs,
    required this.style,
    required this.name,
    required this.marginL,
    required this.marginR,
    required this.marginV,
    required this.effect,
    required this.text,
    required this.tags,
  });

  final int layer;
  final int startMs;
  final int endMs;
  final String style;
  final String name;
  final int marginL;
  final int marginR;
  final int marginV;
  final String effect;
  final String text;
  final List<Map<String, dynamic>> tags;

  /// Convert to AssEvent
  AssEvent toAssEvent() => AssEvent(
      layer: layer,
      start: Duration(milliseconds: startMs),
      end: Duration(milliseconds: endMs),
      style: style,
      name: name,
      marginL: marginL,
      marginR: marginR,
      marginV: marginV,
      effect: effect,
      text: text,
      tags: tags.map((t) => AssTag(
        type: t['type'] as String?,
        value: t['value'],
        values: t['values'] as List<dynamic>?,
      )).toList(),
    );

  /// Convert from AssEvent
  static SerializableAssEvent fromAssEvent(AssEvent event) => SerializableAssEvent(
      layer: event.layer,
      startMs: event.start.inMilliseconds,
      endMs: event.end.inMilliseconds,
      style: event.style,
      name: event.name,
      marginL: event.marginL,
      marginR: event.marginR,
      marginV: event.marginV,
      effect: event.effect,
      text: event.text,
      tags: event.tags.map((t) => {
        'type': t.type,
        'value': t.value,
        'values': t.values,
      }).toList(),
    );
}


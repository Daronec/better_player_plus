import 'package:better_player_plus/src/core/better_player_controller.dart';
import 'package:better_player_plus/src/subtitles/better_player_subtitle_overlay.dart';
import 'package:better_player_plus/src/subtitles/better_player_subtitle_preferences.dart';
import 'package:flutter/material.dart';

/// Menu widget for customizing subtitle style
class BetterPlayerSubtitleStyleMenu extends StatefulWidget {
  const BetterPlayerSubtitleStyleMenu({super.key, required this.controller});

  final BetterPlayerController controller;

  @override
  State<BetterPlayerSubtitleStyleMenu> createState() => _BetterPlayerSubtitleStyleMenuState();
}

class _BetterPlayerSubtitleStyleMenuState extends State<BetterPlayerSubtitleStyleMenu> {
  late BetterPlayerSubtitleOverlayStyle _currentStyle;

  @override
  void initState() {
    super.initState();
    _currentStyle = widget.controller.subtitleOverlayStyle;
    // Load saved style from preferences
    _loadSavedStyle();
  }

  Future<void> _loadSavedStyle() async {
    try {
      final savedStyle = await BetterPlayerSubtitlePreferences.loadStyle();
      if (savedStyle != null && mounted) {
        setState(() {
          _currentStyle = savedStyle;
        });
        widget.controller.updateSubtitleOverlayStyle(savedStyle);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  void _updateStyle(BetterPlayerSubtitleOverlayStyle newStyle) {
    setState(() {
      _currentStyle = newStyle;
    });
    widget.controller.updateSubtitleOverlayStyle(newStyle);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(context).pop(),
    child: ColoredBox(
      color: Colors.black54,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {}, // Prevent tap from closing
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFontSizeSlider(),
                        const SizedBox(height: 24),
                        _buildTextColorSelector(),
                        const SizedBox(height: 24),
                        _buildBackgroundColorSelector(),
                        const SizedBox(height: 24),
                        _buildOutlineColorSelector(),
                        const SizedBox(height: 24),
                        _buildOutlineWidthSlider(),
                        const SizedBox(height: 24),
                        _buildPositionSelector(),
                        const SizedBox(height: 24),
                        _buildFontWeightSelector(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white24)),
    ),
    child: Row(
      children: [
        const Text(
          'Subtitle Style',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );

  Widget _buildFontSizeSlider() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Font Size', style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('${_currentStyle.fontSize.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
      Slider(
        value: _currentStyle.fontSize,
        min: 12,
        max: 40,
        divisions: 28,
        activeColor: Colors.white,
        inactiveColor: Colors.white30,
        onChanged: (value) {
          _updateStyle(_currentStyle.copyWith(fontSize: value));
        },
      ),
    ],
  );

  Widget _buildTextColorSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Text Color', style: TextStyle(color: Colors.white, fontSize: 16)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildColorOption(Colors.white, _currentStyle.color == Colors.white),
          _buildColorOption(Colors.yellow, _currentStyle.color == Colors.yellow),
          _buildColorOption(Colors.cyan, _currentStyle.color == Colors.cyan),
          _buildColorOption(Colors.green, _currentStyle.color == Colors.green),
          _buildColorOption(Colors.red, _currentStyle.color == Colors.red),
          _buildColorOption(Colors.blue, _currentStyle.color == Colors.blue),
        ],
      ),
    ],
  );

  Widget _buildBackgroundColorSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Background', style: TextStyle(color: Colors.white, fontSize: 16)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildBackgroundColorOption(
            Colors.transparent,
            _currentStyle.backgroundColor == Colors.transparent || _currentStyle.backgroundColor == null,
            'None',
          ),
          _buildBackgroundColorOption(Colors.black54, _currentStyle.backgroundColor == Colors.black54, 'Black'),
          _buildBackgroundColorOption(Colors.black87, _currentStyle.backgroundColor == Colors.black87, 'Dark'),
        ],
      ),
    ],
  );

  Widget _buildOutlineColorSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Outline Color', style: TextStyle(color: Colors.white, fontSize: 16)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildOutlineColorOption(Colors.black, _currentStyle.shadowColor == Colors.black),
          _buildOutlineColorOption(Colors.white, _currentStyle.shadowColor == Colors.white),
          _buildOutlineColorOption(Colors.blue, _currentStyle.shadowColor == Colors.blue),
          _buildOutlineColorOption(Colors.red, _currentStyle.shadowColor == Colors.red),
        ],
      ),
    ],
  );

  Widget _buildOutlineWidthSlider() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Outline Width', style: TextStyle(color: Colors.white, fontSize: 16)),
          Text('${_currentStyle.outlineWidth.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
      Slider(
        value: _currentStyle.outlineWidth,
        max: 8,
        divisions: 16,
        inactiveColor: Colors.white30,
        onChanged: (value) {
          _updateStyle(_currentStyle.copyWith(outlineWidth: value, shadowsEnabled: value > 0));
        },
      ),
    ],
  );

  Widget _buildPositionSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Position', style: TextStyle(color: Colors.white, fontSize: 16)),
      const SizedBox(height: 8),
      Row(
        children: [
          _buildPositionOption('Bottom', Alignment.bottomCenter, _currentStyle.alignment == Alignment.bottomCenter),
          const SizedBox(width: 12),
          _buildPositionOption('Middle', Alignment.center, _currentStyle.alignment == Alignment.center),
          const SizedBox(width: 12),
          _buildPositionOption('Top', Alignment.topCenter, _currentStyle.alignment == Alignment.topCenter),
        ],
      ),
    ],
  );

  Widget _buildFontWeightSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Font Weight', style: TextStyle(color: Colors.white, fontSize: 16)),
      const SizedBox(height: 8),
      Row(
        children: [
          _buildFontWeightOption('Normal', FontWeight.normal, _currentStyle.fontWeight == FontWeight.normal),
          const SizedBox(width: 12),
          _buildFontWeightOption('Medium', FontWeight.w500, _currentStyle.fontWeight == FontWeight.w500),
          const SizedBox(width: 12),
          _buildFontWeightOption('Bold', FontWeight.bold, _currentStyle.fontWeight == FontWeight.bold),
        ],
      ),
    ],
  );

  Widget _buildColorOption(Color color, bool isSelected) => GestureDetector(
    onTap: () => _updateStyle(_currentStyle.copyWith(color: color)),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
      ),
    ),
  );

  Widget _buildBackgroundColorOption(Color color, bool isSelected, String label) => GestureDetector(
    onTap: () => _updateStyle(_currentStyle.copyWith(backgroundColor: color)),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == Colors.transparent ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );

  Widget _buildOutlineColorOption(Color color, bool isSelected) => GestureDetector(
    onTap: () => _updateStyle(_currentStyle.copyWith(shadowColor: color)),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
      ),
    ),
  );

  Widget _buildPositionOption(String label, Alignment alignment, bool isSelected) => Expanded(
    child: GestureDetector(
      onTap: () => _updateStyle(_currentStyle.copyWith(alignment: alignment)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.white : Colors.white30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    ),
  );

  Widget _buildFontWeightOption(String label, FontWeight weight, bool isSelected) => Expanded(
    child: GestureDetector(
      onTap: () => _updateStyle(_currentStyle.copyWith(fontWeight: weight)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.white : Colors.white30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    ),
  );
}

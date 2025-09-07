import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:characters/characters.dart';

class SegmentedCodeController {
  _SegmentedCodeInputState? _state;

  void _attach(_SegmentedCodeInputState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void clear() {
    _state?._clearAll();
  }

  void setValue(String value) {
    _state?._setAll(value);
  }

  void focusFirst() {
    _state?._focusFirst();
  }
}

class SegmentedCodeInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final EdgeInsetsGeometry margin;

  /// Allowed characters for each segment. Defaults to A-H J-N P-Z 2-9
  final String allowedPattern;

  /// Optional external controller to programmatically clear/set/focus
  final SegmentedCodeController? controller;

  const SegmentedCodeInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.margin = const EdgeInsets.symmetric(horizontal: 2),
    this.allowedPattern = r"[A-HJ-NP-Za-hj-np-z2-9]",
    this.controller,
  });

  @override
  State<SegmentedCodeInput> createState() => _SegmentedCodeInputState();
}

class _SegmentedCodeInputState extends State<SegmentedCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _notify() {
    final String value = _controllers.map((c) => c.text).join().toUpperCase();
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      widget.onCompleted?.call(value);
    }
  }

  void _handleInput(int index, String newValue) {
    final String filtered = newValue.toUpperCase();
    final RegExp allowed = RegExp(widget.allowedPattern);
    if (filtered.isEmpty) {
      _controllers[index].text = '';
      // Backspace on empty -> move to previous and clear it
      if (index > 0) {
        _controllers[index - 1].text = '';
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].selection = TextSelection.fromPosition(
          TextPosition(offset: 0),
        );
      }
      _notify();
      return;
    }

    // Allow only first matching char
    final String char = filtered.characters.first;
    if (allowed.hasMatch(char)) {
      _controllers[index].text = char;
      // Move to next
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
      _notify();
    } else {
      // Revert invalid input
      _controllers[index].text = '';
      _notify();
    }
  }

  void _clearAll() {
    for (final c in _controllers) {
      c.text = '';
    }
    _notify();
    _focusFirst();
  }

  void _setAll(String value) {
    final String up = value.toUpperCase();
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].text = i < up.length ? up[i] : '';
    }
    _notify();
  }

  void _focusFirst() {
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color fill = Theme.of(context).colorScheme.background;
    final Color border =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.25);
    final TextStyle style = Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w700) ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

    return LayoutBuilder(
      builder: (context, constraints) {
        final EdgeInsets resolvedMargin = widget.margin is EdgeInsets
            ? widget.margin as EdgeInsets
            : const EdgeInsets.symmetric(horizontal: 2);
        final double totalMargin = resolvedMargin.horizontal * widget.length;
        final double available = (constraints.maxWidth - totalMargin)
            .clamp(120.0, constraints.maxWidth);
        final double cellWidth = available / widget.length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (i) {
            return Container(
              width: cellWidth,
              height: 56,
              margin: widget.margin,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      _controllers[i].text.isEmpty &&
                      i > 0) {
                    // Backspace on empty field - move to previous and clear it
                    _controllers[i - 1].text = '';
                    _focusNodes[i - 1].requestFocus();
                    _controllers[i - 1].selection = TextSelection.fromPosition(
                      TextPosition(offset: 0),
                    );
                    _notify();
                  }
                },
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: style,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(widget.allowedPattern)),
                    UpperCaseTextFormatter(),
                  ],
                  textInputAction: i == widget.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onChanged: (v) => _handleInput(i, v),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

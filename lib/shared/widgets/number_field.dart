import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.integer = false,
    this.min,
    this.max,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String? label;
  final bool integer;
  final double? min;
  final double? max;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final formatted = _format(widget.value);
    if (_controller.text != formatted && !_controller.selection.isValid) {
      _controller.text = formatted;
    }
  }

  String _format(double v) {
    if (widget.integer) return v.toInt().toString();
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    var cleaned = raw.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (cleaned.isEmpty || cleaned == '.') cleaned = '0';
    var parsed = widget.integer ? int.tryParse(cleaned)?.toDouble() : double.tryParse(cleaned);
    parsed ??= 0;
    if (widget.min != null && parsed < widget.min!) parsed = widget.min!;
    if (widget.max != null && parsed > widget.max!) parsed = widget.max!;
    widget.onChanged(parsed);
    _controller.text = cleaned;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label!,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
          ),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(widget.integer ? r'[0-9]' : r'[0-9.]'))],
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: _onChanged,
        ),
      ],
    );
  }
}

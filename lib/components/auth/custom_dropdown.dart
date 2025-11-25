import 'package:flutter/material.dart';
import '../../colors.dart';

class CustomDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) getLabel;
  final ValueChanged<T?> onChanged;
  final Color? backgroundColor;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.getLabel,
    required this.onChanged,
    this.backgroundColor,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final brightness = Theme.of(context).brightness;
    final optionBackgroundColor = AppColors.getGrey50Color(brightness);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _closeDropdown();
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Full screen tap area to close dropdown
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeDropdown,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Dropdown menu
              Positioned(
                width: renderBox.size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, 0),
                  child: GestureDetector(
                    onTap:
                        () {}, // Prevent closing when tapping inside dropdown
                    child: Container(
                      decoration: BoxDecoration(
                        color: optionBackgroundColor,
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 300),
                      margin: EdgeInsets.zero,
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: widget.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isSelected = widget.value == item;
                          final isLast = index == widget.items.length - 1;
                          return InkWell(
                            onTap: () {
                              widget.onChanged(item);
                              _closeDropdown();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: optionBackgroundColor,
                                border: isLast
                                    ? null
                                    : Border(
                                        bottom: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.getLabel(item),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surfaceColor =
        widget.backgroundColor ?? AppColors.getSurfaceColor(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value != null
                          ? widget.getLabel(widget.value as T)
                          : 'Select...',
                      style: TextStyle(
                        color: widget.value != null
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

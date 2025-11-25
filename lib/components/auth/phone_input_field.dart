import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../colors.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onValidationChanged;
  final bool enabled;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onValidationChanged,
    this.enabled = true,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    // Check if phone number already exists when widget is initialized
    _checkPhoneNumber();
    // Listen to controller changes
    widget.controller.addListener(_checkPhoneNumber);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkPhoneNumber);
    super.dispose();
  }

  void _checkPhoneNumber() {
    final text = widget.controller.text;
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    final hasNumber = digitsOnly.isNotEmpty;
    
    if (_isPhoneValid != hasNumber) {
      setState(() {
        _isPhoneValid = hasNumber;
      });
      widget.onValidationChanged?.call(hasNumber);
    }
  }

  String _formatPhoneNumber(String value) {
    // Remove all non-digits
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 10 digits (Canada phone number)
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    // Format as XXX XXX XXXX
    if (digitsOnly.isEmpty) {
      return '';
    } else if (digitsOnly.length <= 3) {
      return digitsOnly;
    } else if (digitsOnly.length <= 6) {
      return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3)}';
    } else {
      return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}';
    }
  }

  void _onPhoneChanged(String value) {
    String formatted = _formatPhoneNumber(value);
    if (widget.controller.text != formatted) {
      widget.controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    // Check phone number (will update check icon)
    _checkPhoneNumber();
    
    widget.onChanged?.call(formatted);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surfaceColor = AppColors.getSurfaceColor(brightness);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Country selector (Canada)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Canada flag emoji or icon
                const Text(
                  '🇨🇦',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                const Text(
                  '+1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ),
          // Phone number input
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              onChanged: _onPhoneChanged,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(
                color: widget.enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: '+1 123 456 789',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                suffixIcon: _isPhoneValid
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.check_circle,
                          color: Color(0xFF28A745),
                          size: 24,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


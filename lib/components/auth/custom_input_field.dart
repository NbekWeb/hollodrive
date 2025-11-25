import 'package:flutter/material.dart';
import '../../colors.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const CustomInputField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();
  bool _hasBeenTouched = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surfaceColor = AppColors.getSurfaceColor(brightness);

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
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.validator != null
              ? TextFormField(
                  key: _fieldKey,
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  enabled: widget.enabled,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (value) {
                    widget.onChanged?.call(value);
                    if (!_hasBeenTouched) {
                      setState(() {
                        _hasBeenTouched = true;
                      });
                    }
                    // Trigger validation only after touched
                    if (_hasBeenTouched) {
                      _fieldKey.currentState?.validate();
                    }
                  },
                  onTap: () {
                    if (!_hasBeenTouched) {
                      setState(() {
                        _hasBeenTouched = true;
                      });
                    }
                  },
                  validator: widget.validator,
                  style: TextStyle(
                    color: widget.enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: widget.suffixIcon,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                )
              : TextField(
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  enabled: widget.enabled,
                  onChanged: widget.onChanged,
                  style: TextStyle(
                    color: widget.enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: widget.suffixIcon,
                  ),
                ),
        ),
        if (widget.validator != null)
          _ErrorTextWidget(
            validator: widget.validator!,
            controller: widget.controller,
            fieldKey: _fieldKey,
            hasBeenTouched: _hasBeenTouched,
          ),
      ],
    );
  }
}

class _ErrorTextWidget extends StatefulWidget {
  final String? Function(String?) validator;
  final TextEditingController? controller;
  final GlobalKey<FormFieldState>? fieldKey;
  final bool hasBeenTouched;

  const _ErrorTextWidget({
    required this.validator,
    this.controller,
    this.fieldKey,
    this.hasBeenTouched = false,
  });

  @override
  State<_ErrorTextWidget> createState() => _ErrorTextWidgetState();
}

class _ErrorTextWidgetState extends State<_ErrorTextWidget> {
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_validate);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_validate);
    super.dispose();
  }

  void _validate() {
    final error = widget.validator(widget.controller?.text);
    if (_errorText != error) {
      setState(() {
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check form field state if available
    final fieldState = widget.fieldKey?.currentState;
    
    // Show error if field has been touched OR if form field has error (form submitted)
    final shouldShowError = widget.hasBeenTouched || (fieldState?.hasError == true);
    
    if (!shouldShowError) {
      return const SizedBox.shrink();
    }

    if (fieldState != null && fieldState.hasError) {
      final formError = fieldState.errorText;
      if (formError != null && formError.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 8, left: 16),
          child: Text(
            formError,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        );
      }
    }

    // Fallback to validator-based error
    if (_errorText == null || _errorText!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 16),
      child: Text(
        _errorText!,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
    );
  }
}

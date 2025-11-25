import 'package:flutter/material.dart';
import '../../colors.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

class CustomToast {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    // Agar toast allaqachon ko'rsatilgan bo'lsa, uni yopamiz
    if (_isVisible) {
      hide();
    }

    _isVisible = true;
    final overlay = Overlay.of(context);
    final brightness = Theme.of(context).brightness;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onTap: onTap,
        onDismiss: hide,
        brightness: brightness,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  static void hide() {
    if (_overlayEntry != null && _isVisible) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }

  // Qulay metodlar
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: ToastType.success, duration: duration ?? const Duration(seconds: 3));
  }

  static void showError(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: ToastType.error, duration: duration ?? const Duration(seconds: 4));
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: ToastType.info, duration: duration ?? const Duration(seconds: 3));
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: ToastType.warning, duration: duration ?? const Duration(seconds: 3));
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  final Brightness brightness;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    this.onTap,
    required this.onDismiss,
    required this.brightness,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Tepadan boshlanadi
      end: Offset.zero, // O'rniga keladi
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    // Animatsiyani boshlash
    _controller.forward();

    // Avtomatik yopilish
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case ToastType.success:
        return AppColors.getSuccessColor(widget.brightness);
      case ToastType.error:
        return AppColors.getErrorColor(widget.brightness);
      case ToastType.warning:
        return AppColors.getSecondaryColor(widget.brightness);
      case ToastType.info:
        return AppColors.getSurfaceColor(widget.brightness);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaTop = MediaQuery.of(context).padding.top;

    return Positioned(
      top: safeAreaTop + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap ?? _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


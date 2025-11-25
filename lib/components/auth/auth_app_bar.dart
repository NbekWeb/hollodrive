import 'package:flutter/material.dart';

class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? actionText;
  final VoidCallback? onActionPressed;
  final VoidCallback? onBackPressed;

  const AuthAppBar({
    super.key,
    this.actionText,
    this.onActionPressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      actions: actionText != null
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: TextButton(
                    onPressed: onActionPressed,
                    child: Text(
                      actionText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


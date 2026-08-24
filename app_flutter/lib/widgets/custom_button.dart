import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ButtonVariant { primary, outline }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isDisabled;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == ButtonVariant.outline) {
      return OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDisabled ? AppTheme.buttonDisabled : AppTheme.primaryGreen,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(
          label,
          style: AppTheme.subtitleStyle.copyWith(
            color: isDisabled ? AppTheme.textGray : AppTheme.primaryGreen,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? AppTheme.buttonDisabled : AppTheme.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text(
        label,
        style: AppTheme.subtitleStyle.copyWith(
          color: AppTheme.backgroundLight,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CardStyle { normal, emptySlot }

class CustomCard extends StatelessWidget {
  final Widget? child;
  final CardStyle style;
  final EdgeInsetsGeometry padding;

  const CustomCard({
    super.key,
    this.child,
    this.style = CardStyle.normal,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    if (style == CardStyle.emptySlot) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: padding,
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.buttonDisabled,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add_box_outlined,
            color: AppTheme.buttonDisabled,
            size: 32,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomHeader extends StatelessWidget {
  final String? title;
  final Widget? child;

  const CustomHeader({
    super.key,
    this.title,
    this.child,
  }) : assert(title != null || child != null, 'Either title or child must be provided.');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: child ??
          Text(
            title!,
            style: AppTheme.titleStyle,
          ),
    );
  }
}

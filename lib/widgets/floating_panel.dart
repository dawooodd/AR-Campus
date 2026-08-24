import 'package:flutter/material.dart';

enum PanelPosition { top, bottom }

class FloatingPanel extends StatelessWidget {
  final PanelPosition position;
  final Widget child;
  final double margin;

  const FloatingPanel({
    super.key,
    this.position = PanelPosition.top,
    required this.child,
    this.margin = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position == PanelPosition.top ? margin : null,
      bottom: position == PanelPosition.bottom ? margin : null,
      left: margin,
      right: margin,
      child: SafeArea(
        child: child,
      ),
    );
  }
}

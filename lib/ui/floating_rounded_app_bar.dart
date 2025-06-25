// FloatingRoundedAppBar: A reusable floating, rounded app bar widget for DevLoggerX.
//
// Use this widget in place of AppBar for a modern, floating look in overlay and settings screens.

import 'package:flutter/material.dart';

/// A floating, rounded app bar that appears elevated and visually detached from the top edge.
///
/// Use this in place of a standard AppBar for a modern, floating look.
class FloatingRoundedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final Color? backgroundColor;
  final EdgeInsetsGeometry margin;

  const FloatingRoundedAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.height = 56,
    this.backgroundColor,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 0),
  });

  @override
  Size get preferredSize => Size.fromHeight(height + margin.vertical);

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? Colors.grey[900];
    return SafeArea(
      child: Container(
        margin: margin,

        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(24),
          color: color,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // Removed SafeArea to eliminate app bar spacing at the top
              child: Row(
                children: [
                  if (leading != null) leading!,
                  if (title != null)
                    Expanded(
                      child: DefaultTextStyle(
                        style: Theme.of(context).textTheme.headlineMedium!,
                        child: title!,
                      ),
                    ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class TechSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;

  const TechSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 36.0,
    this.height = 20.0,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isEnabled = onChanged != null;

    final effectiveActiveBg =
        activeColor ?? (isDark ? Colors.white : Colors.black);
    final effectiveInactiveBg = inactiveColor ??
        (isDark ? const Color(0xFF141414) : const Color(0xFFE8E8E8));
    final effectiveBorderColor = value
        ? effectiveActiveBg
        : (isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC));

    final effectiveThumbColor = thumbColor ??
        (value
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)));

    const innerPadding = 2.0;
    final thumbSize = height - (innerPadding * 2);

    return Semantics(
      toggled: value,
      enabled: isEnabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: width,
            height: height,
            padding: const EdgeInsets.all(innerPadding),
            decoration: BoxDecoration(
              color: value ? effectiveActiveBg : effectiveInactiveBg,
              borderRadius: BorderRadius.circular(3.0),
              border: Border.all(
                color: effectiveBorderColor,
                width: 0.9,
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: effectiveThumbColor,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

class ReIcon extends StatelessWidget {
  final String path;
  final double size;
  final Color? color;

  const ReIcon(
    this.path, {
    super.key,
    this.size = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color ?? Colors.white;
    return SvgPicture.string(
      reiconSvg(path, size: size.toInt()),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}

class TerminalActionBtn extends StatefulWidget {
  final Widget? icon;
  final String? label;
  final VoidCallback? onTap;
  final Color defaultColor;
  final Color hoverColor;
  final Color? defaultBorderColor;
  final Color? hoverBorderColor;
  final EdgeInsets padding;
  final bool hasBorder;

  const TerminalActionBtn({
    super.key,
    this.icon,
    this.label,
    this.onTap,
    this.defaultColor = const Color(0xFFCCCCCC),
    this.hoverColor = const Color(0xFF00FF66),
    this.defaultBorderColor,
    this.hoverBorderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.hasBorder = true,
  });

  @override
  State<TerminalActionBtn> createState() => _TerminalActionBtnState();
}

class _TerminalActionBtnState extends State<TerminalActionBtn> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = _isHovered ? widget.hoverColor : widget.defaultColor;
    final activeBorderColor = widget.hasBorder
        ? (_isHovered
            ? (widget.hoverBorderColor ?? widget.hoverColor)
            : (widget.defaultBorderColor ?? const Color(0xFF282828)))
        : Colors.transparent;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: widget.onTap != null
            ? () => setState(() => _isPressed = false)
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _isPressed
                  ? widget.hoverColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.zero,
              border: widget.hasBorder
                  ? Border.all(color: activeBorderColor, width: 1.0)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null)
                  IconTheme(
                    data: IconThemeData(color: activeColor, size: 18),
                    child: widget.icon!,
                  ),
                if (widget.icon != null && widget.label != null)
                  const SizedBox(width: 6),
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

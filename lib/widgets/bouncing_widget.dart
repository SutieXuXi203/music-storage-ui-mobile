import 'package:flutter/material.dart';

class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final Duration reverseDuration;
  final HitTestBehavior behavior;

  const BouncingWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.86,
    this.duration = const Duration(milliseconds: 80),
    this.reverseDuration = const Duration(milliseconds: 140),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class BouncingIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  const BouncingIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconSize,
    this.color,
    this.tooltip,
    this.padding = const EdgeInsets.all(8.0),
    this.constraints,
  });

  @override
  State<BouncingIconButton> createState() => _BouncingIconButtonState();
}

class _BouncingIconButtonState extends State<BouncingIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.82,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel:
          widget.onPressed != null ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: widget.padding,
          child: IconTheme(
            data: IconThemeData(
              size: widget.iconSize ?? 24.0,
              color: widget.color ?? IconTheme.of(context).color,
            ),
            child: widget.icon,
          ),
        ),
      ),
    );

    if (widget.constraints != null) {
      result = ConstrainedBox(constraints: widget.constraints!, child: result);
    }
    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }
    return result;
  }
}

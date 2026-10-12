import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.scaleFactor = 0.95,
    this.duration = const Duration(milliseconds: 70),
    this.reverseDuration = const Duration(milliseconds: 110),
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
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) {
        if (!reduceMotion) _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        if (!reduceMotion) _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        if (!reduceMotion) _controller.reverse();
      },
      child: reduceMotion
          ? widget.child
          : ScaleTransition(
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
  final double scaleFactor;

  const BouncingIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconSize,
    this.color,
    this.tooltip,
    this.padding = const EdgeInsets.all(8.0),
    this.constraints,
    this.scaleFactor = 0.92,
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
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 110),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onPressed != null
          ? (_) {
              if (!reduceMotion) _controller.forward();
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              if (!reduceMotion) _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () {
        if (!reduceMotion && widget.onPressed != null) _controller.reverse();
      },
      child: reduceMotion
          ? Padding(
              padding: widget.padding,
              child: IconTheme(
                data: IconThemeData(
                  size: widget.iconSize ?? 24.0,
                  color: widget.color ?? IconTheme.of(context).color,
                ),
                child: widget.icon,
              ),
            )
          : ScaleTransition(
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';

class AppCoverImage extends StatefulWidget {
  final String? url;
  final String? fallbackUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final BoxFit fit;
  final IconData placeholderIcon;
  final double iconSize;

  const AppCoverImage({
    super.key,
    required this.url,
    this.fallbackUrl,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusSm,
    this.shape = BoxShape.rectangle,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.music_note,
    this.iconSize = 18,
  });

  @override
  State<AppCoverImage> createState() => _AppCoverImageState();
}

class _AppCoverImageState extends State<AppCoverImage> {
  bool _useFallback = false;

  @override
  void didUpdateWidget(covariant AppCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _useFallback = false;
    }
  }

  void _triggerFallback() {
    if (!_useFallback &&
        widget.fallbackUrl != null &&
        widget.fallbackUrl!.trim().isNotEmpty &&
        widget.fallbackUrl!.trim() != widget.url?.trim()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _useFallback = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUrl = (_useFallback ? widget.fallbackUrl : widget.url)?.trim();
    final hasValidUrl = activeUrl != null && activeUrl.isNotEmpty;

    if (!hasValidUrl) {
      return _buildContainer(context, _buildPlaceholder(context));
    }

    Widget imageWidget;
    if (kIsWeb) {
      // Trên Web dùng Image.network thuần của trình duyệt để tối ưu tương thích CORS và tránh lỗi ResizeImage
      imageWidget = Image.network(
        activeUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: Alignment.center,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(context);
        },
        errorBuilder: (context, error, stackTrace) {
          _triggerFallback();
          return _buildPlaceholder(context);
        },
      );
    } else {
      // Trên Mobile/Desktop dùng CachedNetworkImage có bộ nhớ đệm offline
      final memWidth = widget.width != null
          ? (widget.width! * 2.5).toInt().clamp(80, 800)
          : (widget.height != null
              ? (widget.height! * 2.5).toInt().clamp(80, 800)
              : 320);

      imageWidget = CachedNetworkImage(
        imageUrl: activeUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: Alignment.center,
        memCacheWidth: memWidth,
        fadeInDuration: const Duration(milliseconds: 140),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, _) => _buildPlaceholder(context),
        errorWidget: (context, _, __) {
          _triggerFallback();
          return _buildPlaceholder(context);
        },
      );
    }

    return _buildContainer(context, imageWidget);
  }

  Widget _buildContainer(BuildContext context, Widget child) {
    if (widget.shape == BoxShape.circle) {
      return ClipOval(child: child);
    }
    if (widget.borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: child,
      );
    }
    return child;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppTheme.getSurfaceSubtle(context),
      child: Center(
        child: Icon(
          widget.placeholderIcon,
          size: widget.iconSize,
          color: AppTheme.getTextMuted(context),
        ),
      ),
    );
  }
}

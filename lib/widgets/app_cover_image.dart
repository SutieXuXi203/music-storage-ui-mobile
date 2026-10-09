import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';

class AppCoverImage extends StatelessWidget {
  final String? url;
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
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusSm,
    this.shape = BoxShape.rectangle,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.music_note,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final validUrl = url != null && url!.trim().isNotEmpty;
    final memWidth = width != null
        ? (width! * 2.5).toInt().clamp(80, 800)
        : (height != null ? (height! * 2.5).toInt().clamp(80, 800) : 320);

    Widget imageWidget;
    if (!validUrl) {
      imageWidget = _buildPlaceholder(context);
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: url!.trim(),
        width: width,
        height: height,
        fit: fit,
        alignment: Alignment.center,
        memCacheWidth: memWidth,
        fadeInDuration: const Duration(milliseconds: 140),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, _) => _buildPlaceholder(context),
        errorWidget: (context, _, __) => _buildPlaceholder(context),
      );
    }

    if (shape == BoxShape.circle) {
      return ClipOval(child: imageWidget);
    }
    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppTheme.getSurfaceSubtle(context),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: iconSize,
          color: AppTheme.getTextMuted(context),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';

/// A memory-efficient image widget that automatically downsamples network images
/// to avoid high heap memory usage and resolves Google Play Pre-launch warnings.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? fallbackAsset;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackAsset,
  });

  /// Factory constructor optimized for thumbnails (cart items, order items, list avatars).
  /// Downsamples to max 150-200px width/height.
  factory AppNetworkImage.thumbnail({
    Key? key,
    required String imageUrl,
    double size = 70,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? errorWidget,
    String? fallbackAsset,
  }) {
    return AppNetworkImage(
      key: key,
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: fit,
      cacheWidth: (size * 2).toInt().clamp(100, 250),
      cacheHeight: (size * 2).toInt().clamp(100, 250),
      borderRadius: borderRadius,
      errorWidget: errorWidget,
      fallbackAsset: fallbackAsset,
    );
  }

  /// Factory constructor optimized for product catalog grid cards.
  /// Downsamples to max 450-500px in memory.
  factory AppNetworkImage.card({
    Key? key,
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? errorWidget,
  }) {
    return AppNetworkImage(
      key: key,
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: 450,
      borderRadius: borderRadius,
      errorWidget: errorWidget,
    );
  }

  /// Factory constructor optimized for full-width carousel banners.
  /// Caps decoded memory bitmap to 1080px width.
  factory AppNetworkImage.banner({
    Key? key,
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? errorWidget,
  }) {
    return AppNetworkImage(
      key: key,
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: 1080,
      borderRadius: borderRadius,
      errorWidget: errorWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty || cleanUrl == 'null' || (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://'))) {
      return _buildFallback(context);
    }

    if (kIsWeb) {
      Widget webImage = Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: const Color(0xFFF1F5F9),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1E60D5),
                    ),
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );

      if (borderRadius != null) {
        webImage = ClipRRect(
          borderRadius: borderRadius!,
          child: webImage,
        );
      }

      return webImage;
    }

    // Determine smart target decode bounds to enforce bitmap downsampling
    int? targetMemCacheWidth = cacheWidth;
    int? targetMemCacheHeight = cacheHeight;

    if (targetMemCacheWidth == null && targetMemCacheHeight == null) {
      if (width != null && width! > 0 && width!.isFinite) {
        targetMemCacheWidth = (width! * 2).toInt().clamp(80, 1200);
      } else if (height != null && height! > 0 && height!.isFinite) {
        targetMemCacheHeight = (height! * 2).toInt().clamp(80, 1200);
      } else {
        // Unbounded width & height: cap at 800 to prevent raw 4000x3000 decoding
        targetMemCacheWidth = 800;
      }
    }

    Widget image = CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: targetMemCacheWidth,
      memCacheHeight: targetMemCacheHeight,
      maxWidthDiskCache: 1200,
      maxHeightDiskCache: 1200,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1E60D5),
                ),
              ),
            ),
          ),
      errorWidget: (context, url, error) => _buildFallback(context),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildFallback(BuildContext context) {
    if (errorWidget != null) {
      return SizedBox(
        width: width,
        height: height,
        child: errorWidget!,
      );
    }

    if (fallbackAsset != null && fallbackAsset!.isNotEmpty) {
      return Image.asset(
        fallbackAsset!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth ?? 120,
        cacheHeight: cacheHeight ?? 120,
      );
    }

    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surface,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}

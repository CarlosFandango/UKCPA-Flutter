import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Unified image loading utility with consistent caching and error handling
class ImageLoader {
  ImageLoader._();

  /// Load image with automatic caching and error handling
  static Widget load({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    Color? placeholderColor,
    Widget? placeholder,
    Widget? errorWidget,
    ImagePosition? imagePosition,
    Duration? cacheExpiration,
    bool enableMemoryCache = true,
    BorderRadius? borderRadius,
  }) {
    // Handle null or empty URLs
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildFallbackWidget(
        width: width,
        height: height,
        color: placeholderColor,
        borderRadius: borderRadius,
      );
    }

    // Calculate alignment from imagePosition
    final calculatedAlignment = imagePosition != null
        ? Alignment(
            (imagePosition.X / 50) - 1, // Convert 0-100 to -1 to 1
            (imagePosition.Y / 50) - 1,
          )
        : alignment;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: calculatedAlignment,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      
      // Placeholder while loading
      placeholder: (context, url) => placeholder ?? _buildPlaceholderWidget(
        width: width,
        height: height,
        color: placeholderColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      
      // Error widget for failed loads
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(
        width: width,
        height: height,
        error: error,
        borderRadius: borderRadius,
        theme: Theme.of(context),
      ),
      
      // Cache configuration
      cacheManager: UKCPAImageCacheManager.instance,
      
      // Additional options
      useOldImageOnUrlChange: true,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Load image for course cards with optimized settings
  static Widget forCourseCard({
    required String? imageUrl,
    double width = 300,
    double height = 200,
    ImagePosition? imagePosition,
    BorderRadius? borderRadius,
  }) {
    return load(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      imagePosition: imagePosition,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      cacheExpiration: const Duration(hours: 24),
    );
  }

  /// Load image for avatars with circular clipping
  static Widget forAvatar({
    required String? imageUrl,
    double size = 48,
    Color? backgroundColor,
  }) {
    return ClipOval(
      child: load(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderColor: backgroundColor,
        cacheExpiration: const Duration(days: 7),
      ),
    );
  }

  /// Load image for thumbnails with aggressive caching
  static Widget forThumbnail({
    required String? imageUrl,
    double width = 120,
    double height = 90,
    BorderRadius? borderRadius,
  }) {
    return load(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      cacheExpiration: const Duration(days: 30),
    );
  }

  /// Load image for hero sections with special handling
  static Widget forHero({
    required String? imageUrl,
    double? width,
    double height = 300,
    ImagePosition? imagePosition,
    Widget? overlay,
  }) {
    final imageWidget = load(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      imagePosition: imagePosition,
      cacheExpiration: const Duration(hours: 12),
    );

    if (overlay != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          overlay,
        ],
      );
    }

    return imageWidget;
  }

  /// Build placeholder widget while loading
  static Widget _buildPlaceholderWidget({
    double? width,
    double? height,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    Widget placeholder = Container(
      width: width,
      height: height,
      color: color,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );

    if (borderRadius != null) {
      placeholder = ClipRRect(
        borderRadius: borderRadius,
        child: placeholder,
      );
    }

    return placeholder;
  }

  /// Build error widget for failed loads
  static Widget _buildErrorWidget({
    double? width,
    double? height,
    Object? error,
    BorderRadius? borderRadius,
    required ThemeData theme,
  }) {
    Widget errorWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: (height != null && height < 100) ? 24 : 48,
            color: theme.colorScheme.onErrorContainer.withOpacity(0.5),
          ),
          if (height == null || height > 60) ...[
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    return errorWidget;
  }

  /// Build fallback widget for null/empty URLs
  static Widget _buildFallbackWidget({
    double? width,
    double? height,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_outlined,
        size: (height != null && height < 100) ? 24 : 48,
        color: Colors.grey[400],
      ),
    );
  }

  /// Preload image for better UX
  static Future<void> preloadImage(String imageUrl, BuildContext context) async {
    try {
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    } catch (e) {
      debugPrint('Failed to preload image: $imageUrl, error: $e');
    }
  }

  /// Clear image cache
  static Future<void> clearCache() async {
    await UKCPAImageCacheManager.instance.emptyCache();
  }

  /// Get cache size
  static Future<String> getCacheSize() async {
    // This would require implementing cache size calculation
    return 'Cache size calculation not implemented';
  }
}

/// Custom cache manager for UKCPA images
class UKCPAImageCacheManager extends CacheManager with ImageCacheManager {
  static const String _key = 'ukcpa_image_cache';
  static const int _maxCacheObjects = 200;
  static const Duration _maxCacheAge = Duration(days: 30);

  static final UKCPAImageCacheManager _instance = UKCPAImageCacheManager._internal();
  static UKCPAImageCacheManager get instance => _instance;

  UKCPAImageCacheManager._internal()
      : super(
          Config(
            _key,
            stalePeriod: _maxCacheAge,
            maxNrOfCacheObjects: _maxCacheObjects,
            repo: JsonCacheInfoRepository(databaseName: _key),
            fileService: HttpFileService(),
          ),
        );
}

/// Image position data class
class ImagePosition {
  final double X;
  final double Y;

  const ImagePosition({
    required this.X,
    required this.Y,
  });

  factory ImagePosition.fromJson(Map<String, dynamic> json) {
    return ImagePosition(
      X: (json['X'] ?? 0).toDouble(),
      Y: (json['Y'] ?? 0).toDouble(),
    );
  }
}

/// Extension methods for easier usage
extension ImageLoaderExtensions on String? {
  /// Quick load with default settings
  Widget loadImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return ImageLoader.load(
      imageUrl: this,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  /// Load as course card image
  Widget loadAsCourseCard({
    double width = 300,
    double height = 200,
    ImagePosition? imagePosition,
  }) {
    return ImageLoader.forCourseCard(
      imageUrl: this,
      width: width,
      height: height,
      imagePosition: imagePosition,
    );
  }

  /// Load as avatar
  Widget loadAsAvatar({
    double size = 48,
    Color? backgroundColor,
  }) {
    return ImageLoader.forAvatar(
      imageUrl: this,
      size: size,
      backgroundColor: backgroundColor,
    );
  }
}
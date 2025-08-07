import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

/// Unified image loading utility with consistent caching and error handling
class ImageLoader {
  ImageLoader._();

  /// Track if we've detected network issues (for Android emulator)
  static bool _networkIssuesDetected = false;
  
  /// Check if we should use network images or fallback to local assets
  static bool get shouldUseNetworkImages {
    // If we've already detected network issues, use fallbacks
    if (_networkIssuesDetected) return false;
    
    // In debug mode on Android emulator, check for common DNS issues
    if (kDebugMode && !kIsWeb && Platform.isAndroid) {
      // Android emulator often has DNS resolution issues
      // We'll detect this dynamically during first network errors
      return true; // Start optimistic, fallback on errors
    }
    
    return true;
  }
  
  /// Mark that network issues have been detected
  static void markNetworkIssues() {
    _networkIssuesDetected = true;
    debugPrint('🚨 Network issues detected - switching to asset fallbacks');
  }

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
    Duration timeout = const Duration(seconds: 15),
    String fallbackAsset = 'assets/images/course_placeholder.png',
  }) {
    // Handle null or empty URLs
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildFallbackWidget(
        width: width,
        height: height,
        color: placeholderColor,
        borderRadius: borderRadius,
        fallbackAsset: fallbackAsset,
      );
    }

    // If network issues detected, use asset fallback immediately
    if (!shouldUseNetworkImages) {
      return _buildAssetFallback(
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        borderRadius: borderRadius,
        fallbackAsset: fallbackAsset,
      );
    }

    // Calculate alignment from imagePosition
    final calculatedAlignment = imagePosition != null
        ? Alignment(
            (imagePosition.X / 50) - 1, // Convert 0-100 to -1 to 1
            (imagePosition.Y / 50) - 1,
          )
        : alignment;

    // Create timeout-aware image widget
    Widget imageWidget = TimeoutImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: calculatedAlignment,
      timeout: timeout,
      placeholder: placeholder ?? _buildPlaceholderWidget(
        width: width,
        height: height,
        color: placeholderColor,
        borderRadius: borderRadius,
        fallbackAsset: fallbackAsset,
      ),
      errorWidget: errorWidget,
      borderRadius: borderRadius,
      fallbackAsset: fallbackAsset,
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

  /// Build asset fallback for network issues
  static Widget _buildAssetFallback({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    BorderRadius? borderRadius,
    required String fallbackAsset,
  }) {
    Widget image = Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        // If asset also fails, show icon fallback
        return _buildIconFallback(
          width: width,
          height: height,
          borderRadius: borderRadius,
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius,
        child: image,
      );
    }

    return image;
  }

  /// Build placeholder widget while loading
  static Widget _buildPlaceholderWidget({
    double? width,
    double? height,
    Color? color,
    BorderRadius? borderRadius,
    String? fallbackAsset,
  }) {
    Widget placeholder = Container(
      width: width,
      height: height,
      color: color ?? Colors.grey[100],
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

  /// Build icon fallback widget for null/empty URLs or asset failures
  static Widget _buildIconFallback({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_outlined,
        size: (height != null && height < 100) ? 24 : 48,
        color: Colors.grey[400],
      ),
    );
  }

  /// Build fallback widget for null/empty URLs
  static Widget _buildFallbackWidget({
    double? width,
    double? height,
    Color? color,
    BorderRadius? borderRadius,
    String? fallbackAsset,
  }) {
    // Try asset fallback first if provided and network issues detected
    if (fallbackAsset != null && !shouldUseNetworkImages) {
      return _buildAssetFallback(
        width: width,
        height: height,
        borderRadius: borderRadius,
        fallbackAsset: fallbackAsset,
      );
    }
    
    // Default to icon fallback
    return _buildIconFallback(
      width: width,
      height: height,
      borderRadius: borderRadius,
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

/// Custom cache manager for UKCPA images with enhanced timeout handling
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
            fileService: HttpFileService(
              httpClient: _createHttpClient(),
            ),
          ),
        );
  
  static http.Client _createHttpClient() {
    // Create HTTP client with proper redirect handling
    return http.Client();
  }
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

/// Custom image widget with timeout handling for better UX
class TimeoutImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Duration timeout;
  final Widget placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final String fallbackAsset;

  const TimeoutImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.timeout = const Duration(seconds: 15),
    required this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.fallbackAsset = 'assets/images/course_placeholder.png',
  });

  @override
  State<TimeoutImageWidget> createState() => _TimeoutImageWidgetState();
}

class _TimeoutImageWidgetState extends State<TimeoutImageWidget> {
  bool _hasTimedOut = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    debugPrint('Starting to load image: ${widget.imageUrl}');
    
    // Start timeout timer
    Future.delayed(widget.timeout, () {
      if (mounted && !_hasError) {
        setState(() {
          _hasTimedOut = true;
        });
        debugPrint('Image loading timed out after ${widget.timeout.inSeconds}s: ${widget.imageUrl}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasTimedOut) {
      return widget.errorWidget ?? _buildTimeoutErrorWidget(context);
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      memCacheWidth: widget.width != null && widget.width!.isFinite ? widget.width!.toInt() : null,
      memCacheHeight: widget.height != null && widget.height!.isFinite ? widget.height!.toInt() : null,
      
      // HTTP headers for better compatibility
      httpHeaders: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
      },
      
      // Placeholder while loading
      placeholder: (context, url) => widget.placeholder,
      
      // Error widget for failed loads
      errorWidget: (context, url, error) {
        // Schedule setState for next frame to avoid build-time setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _hasError = true);
          }
        });
        
        debugPrint('Image loading failed: $url, Error: $error');
        
        // Check if this is a DNS resolution error (common in Android emulator)
        final errorString = error.toString().toLowerCase();
        if (errorString.contains('host lookup') || 
            errorString.contains('no address associated') ||
            errorString.contains('network unreachable')) {
          ImageLoader.markNetworkIssues();
          return _buildAssetFallbackWidget(context);
        }
        
        return widget.errorWidget ?? _buildNetworkErrorWidget(context, error);
      },
      
      // Cache configuration
      cacheManager: UKCPAImageCacheManager.instance,
      
      // Additional options
      useOldImageOnUrlChange: true,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  Widget _buildAssetFallbackWidget(BuildContext context) {
    // For now, use icon fallback directly since we don't have asset files
    // In production, this would load an actual asset file
    return _buildIconFallbackWidget(context);
  }

  Widget _buildIconFallbackWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: widget.borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: (widget.height != null && widget.height! < 100) ? 24 : 48,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          if (widget.height == null || widget.height! > 80) ...[
            const SizedBox(height: 8),
            Text(
              'Course Image',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeoutErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _retryImage,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.1),
          borderRadius: widget.borderRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              size: (widget.height != null && widget.height! < 100) ? 24 : 48,
              color: theme.colorScheme.onErrorContainer.withOpacity(0.5),
            ),
            if (widget.height == null || widget.height! > 60) ...[
              const SizedBox(height: 8),
              Text(
                'Connection timeout',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to retry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer.withOpacity(0.5),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkErrorWidget(BuildContext context, Object error) {
    final theme = Theme.of(context);
    
    // Determine error type for better user messaging
    String errorMessage = 'Image unavailable';
    IconData errorIcon = Icons.broken_image_outlined;
    
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('timeout') || errorString.contains('connection')) {
      errorMessage = 'Connection timeout';
      errorIcon = Icons.wifi_off_outlined;
    } else if (errorString.contains('404') || errorString.contains('not found')) {
      errorMessage = 'Image not found';
      errorIcon = Icons.image_not_supported_outlined;
    } else if (errorString.contains('403') || errorString.contains('forbidden')) {
      errorMessage = 'Access denied';
      errorIcon = Icons.lock_outline;
    }

    return InkWell(
      onTap: _retryImage,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.1),
          borderRadius: widget.borderRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorIcon,
              size: (widget.height != null && widget.height! < 100) ? 24 : 48,
              color: theme.colorScheme.onErrorContainer.withOpacity(0.5),
            ),
            if (widget.height == null || widget.height! > 60) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to retry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer.withOpacity(0.5),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _retryImage() {
    // Clear cache and retry
    UKCPAImageCacheManager.instance.removeFile(widget.imageUrl);
    setState(() {
      _hasError = false;
      _hasTimedOut = false;
    });
    debugPrint('Cleared cache and retrying image: ${widget.imageUrl}');
  }
}
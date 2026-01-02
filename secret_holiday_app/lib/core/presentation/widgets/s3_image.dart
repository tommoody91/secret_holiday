import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/photo_url_service.dart';
import '../../utils/logger.dart';

/// A wrapper around CachedNetworkImage that handles S3 presigned URL refreshing.
/// 
/// Use this widget when displaying images stored in S3. It will:
/// 1. Handle both S3 keys and legacy full URLs
/// 2. Fetch fresh presigned URLs from the backend when needed
/// 3. Automatically retry on 403 (expired URL) errors
/// 
/// Usage:
/// ```dart
/// S3Image(
///   s3Key: 'trips/123/photos/abc.jpg',  // or a full URL for backwards compatibility
///   fit: BoxFit.cover,
///   placeholder: (context, url) => CircularProgressIndicator(),
///   errorWidget: (context, url, error) => Icon(Icons.error),
/// )
/// ```
class S3Image extends StatefulWidget {
  /// The S3 key or full URL of the image.
  /// Can be either:
  /// - An S3 key like 'trips/123/photos/abc.jpg'
  /// - A full URL for backwards compatibility (will be used as-is)
  final String? s3Key;
  
  /// How to inscribe the image into the space allocated.
  final BoxFit? fit;
  
  /// Widget to display while the image is loading.
  final PlaceholderWidgetBuilder? placeholder;
  
  /// Widget to display when the image fails to load.
  final LoadingErrorWidgetBuilder? errorWidget;
  
  /// Optional width constraint.
  final double? width;
  
  /// Optional height constraint.
  final double? height;
  
  /// The color to blend with the image.
  final Color? color;
  
  /// The blend mode to use when blending color with the image.
  final BlendMode? colorBlendMode;
  
  /// Additional headers to pass to the image request.
  final Map<String, String>? httpHeaders;
  
  /// Memory cache settings - set to false to always refresh from network.
  final bool useOldImageOnUrlChange;
  
  /// Fade in duration for the image.
  final Duration fadeInDuration;
  
  /// Whether to show a retry button on error.
  final bool showRetryOnError;
  
  const S3Image({
    super.key,
    required this.s3Key,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.httpHeaders,
    this.useOldImageOnUrlChange = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.showRetryOnError = true,
  });

  @override
  State<S3Image> createState() => _S3ImageState();
}

class _S3ImageState extends State<S3Image> {
  String? _presignedUrl;
  bool _isLoading = true;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;
  
  @override
  void initState() {
    super.initState();
    _fetchUrl();
  }
  
  @override
  void didUpdateWidget(S3Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.s3Key != widget.s3Key) {
      _retryCount = 0;
      _hasError = false;
      _fetchUrl();
    }
  }
  
  Future<void> _fetchUrl() async {
    if (widget.s3Key == null || widget.s3Key!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final url = await PhotoUrlService.getUrl(s3Key: widget.s3Key!);
      
      if (mounted) {
        setState(() {
          _presignedUrl = url;
          _isLoading = false;
          _hasError = url == null;
        });
      }
    } catch (e) {
      AppLogger.error('S3Image: Failed to fetch URL for ${widget.s3Key}', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }
  
  void _handleImageError(Object error) {
    AppLogger.error('S3Image: Image load error for ${widget.s3Key}', error);
    
    // Check if it's a 403 error (expired URL)
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        AppLogger.info('S3Image: Retrying with fresh URL (attempt $_retryCount)');
        
        // Force refresh the URL and retry
        PhotoUrlService.handleExpiredUrl(widget.s3Key!).then((newUrl) {
          if (mounted && newUrl != null) {
            setState(() {
              _presignedUrl = newUrl;
            });
          }
        });
        return;
      }
    }
    
    setState(() {
      _hasError = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder(context);
    }
    
    if (_hasError || _presignedUrl == null) {
      return _buildError(context);
    }
    
    return CachedNetworkImage(
      imageUrl: _presignedUrl!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      httpHeaders: widget.httpHeaders,
      useOldImageOnUrlChange: widget.useOldImageOnUrlChange,
      fadeInDuration: widget.fadeInDuration,
      placeholder: widget.placeholder ?? _defaultPlaceholder,
      errorWidget: (context, url, error) {
        _handleImageError(error);
        return widget.errorWidget?.call(context, url, error) ?? 
               _buildError(context);
      },
    );
  }
  
  Widget _buildPlaceholder(BuildContext context) {
    if (widget.placeholder != null) {
      return widget.placeholder!(context, widget.s3Key ?? '');
    }
    return _defaultPlaceholder(context, widget.s3Key ?? '');
  }
  
  Widget _defaultPlaceholder(BuildContext context, String url) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
  
  Widget _buildError(BuildContext context) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!(context, widget.s3Key ?? '', 'Failed to load image');
    }
    
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: Center(
        child: widget.showRetryOnError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      _retryCount = 0;
                      _fetchUrl();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ],
              )
            : Icon(Icons.broken_image, color: Colors.grey[400]),
      ),
    );
  }
}

/// A circular avatar that loads images from S3.
/// 
/// Similar to CircleAvatar but handles S3 presigned URLs.
class S3Avatar extends StatelessWidget {
  final String? s3Key;
  final double radius;
  final Widget? child;
  final Color? backgroundColor;
  
  const S3Avatar({
    super.key,
    required this.s3Key,
    this.radius = 20,
    this.child,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    if (s3Key == null || s3Key!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: child ?? Icon(Icons.person, size: radius),
      );
    }
    
    return ClipOval(
      child: S3Image(
        s3Key: s3Key,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        showRetryOnError: false,
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey[200],
          child: const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey[200],
          child: child ?? Icon(Icons.person, size: radius),
        ),
      ),
    );
  }
}

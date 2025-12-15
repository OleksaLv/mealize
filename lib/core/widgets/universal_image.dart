import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UniversalImage extends StatelessWidget {
  final String? photoUrl; 
  
  final String? photoPath; 
  
  final String fallbackAssetPath;
  
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const UniversalImage({
    super.key,
    this.photoUrl,
    this.photoPath,
    required this.fallbackAssetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (photoPath != null && File(photoPath!).existsSync()) {
      imageWidget = Image.file(
        File(photoPath!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading local image: $error');
          return _buildFallbackImage();
        },
      );
    } 
    else if (photoUrl != null && photoUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: photoUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) {
          debugPrint('Error loading network image: $error');
          return _buildFallbackImage();
        },
      );
    } 
    else {
      imageWidget = _buildFallbackImage();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: imageWidget,
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      fallbackAssetPath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
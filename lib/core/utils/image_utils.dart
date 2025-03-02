import 'package:flutter/material.dart';

class ImageUtils {
  ImageUtils._(); // Private constructor

  /// Safely loads images that could be from network, file, or placeholders
  static Widget loadImage({
    required String url,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? errorWidget,
  }) {
    Widget errorPlaceholder = errorWidget ?? 
      Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    
    // Check if the URL starts with 'http' or 'https' for network images
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => errorPlaceholder,
      );
    } 
    
    // Check for file-based URLs (with dev mode placeholders)
    else if (url.startsWith('file:/') || url.startsWith('/data/')) {
      try {
        return Image.network(
          'https://via.placeholder.com/800x600?text=Local+File', // Use placeholder for file URLs
          fit: fit,
          width: width,
          height: height,
        );
      } catch (e) {
        debugPrint('Error loading file image: $e');
        return errorPlaceholder;
      }
    }
    
    // Fallback to a placeholder
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: Text('No Image')),
    );
  }
}

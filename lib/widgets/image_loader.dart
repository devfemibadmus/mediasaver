import 'package:flutter/material.dart';

class CustomImageLoader extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;

  const CustomImageLoader({
    super.key,
    required this.imageUrl,
    this.height = 150,
    this.width = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      height: height,
      width: width,
      child: Image.network(
        imageUrl,
        key: ValueKey(imageUrl),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          } else {
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        (progress.expectedTotalBytes ?? 1)
                    : null,
                strokeWidth: 2.0, // Make the loader smaller
              ),
            );
          }
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.red,
            child: const Center(child: Text('Error')),
          );
        },
      ),
    );
  }
}

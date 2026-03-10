import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 게시물/썸네일 이미지 표시. data: URL 또는 http URL 지원. 에러 시 기본 이미지.
class PostImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PostImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder(width: width, height: height);
    }

    if (imageUrl!.startsWith('data:')) {
      try {
        final base64 = imageUrl!.split(',').last;
        final bytes = base64Decode(base64);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _placeholder(width: width, height: height),
        );
      } catch (_) {
        return _placeholder(width: width, height: height);
      }
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => SizedBox(
        width: width,
        height: height,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => _placeholder(width: width, height: height),
    );
  }

  static Widget _placeholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF2F3F5),
      child: Icon(Icons.image_not_supported_outlined, size: width != null ? width * 0.4 : 48, color: Colors.grey),
    );
  }
}

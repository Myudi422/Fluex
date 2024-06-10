import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CoverWidget extends StatelessWidget {
  final String coverImageUrl;
  final String? bannerImageUrl;

  CoverWidget({required this.coverImageUrl, this.bannerImageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.30,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(bannerImageUrl ?? coverImageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5), // Adjust the gradient opacity
            BlendMode.darken, // Adjust the gradient blend mode
          ),
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black
                        .withOpacity(0.8), // Adjust the gradient opacity
                  ],
                ),
              ),
            ),
          ),
          // Your content can be added on top of the gradient overlay if needed
        ],
      ),
    );
  }
}

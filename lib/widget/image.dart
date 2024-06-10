// image_widget.dart
import 'package:flutter/material.dart';

class ResponsiveImageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate the desired height of the image (adjust this as needed)
    double imageHeight = screenHeight * 0.;

    return Opacity(
      opacity: 0.5, // Adjust the opacity as needed (0.0 to 1.0)
      child: Container(
        height: imageHeight,
        width: double.infinity,
        child: CustomPaint(
          painter: ImageMaskPainter(), // Custom painter for masking
          child: Image.network(
            'https://i.pinimg.com/564x/0d/3b/8c/0d3b8cb2e49044838b4019c6a40a73cb.jpg', // Replace with the actual URL or path to your image
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class ImageMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    final paint = Paint()
      ..color = Colors.white // Set the color of the masking brush
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

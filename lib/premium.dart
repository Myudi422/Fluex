import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

class PremiumWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      // Wrap with Center widget to horizontally center the content
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.brown[900]!,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align children to the top
          children: [
            // Shimmer effect container
            Container(
              width: 100, // Adjust width as needed
              height: 50, // Adjust height as needed
              child: Stack(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.brown[900]!,
                    highlightColor: Colors.brown[700]!,
                    child: Container(
                      width: 100,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.crown,
                            color: Colors.yellow,
                            size: 14.0,
                          ),
                          SizedBox(width: 5.0),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
                width:
                    10.0), // Adjust spacing between the shimmer effect and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harga Mulai Dari Rp. 12.000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                  Text(
                    'Tanpa Iklan Yuk Beli ;)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

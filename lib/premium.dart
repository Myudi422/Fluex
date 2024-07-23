import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flue/color.dart';
import 'widget/beli.dart';

class PremiumWidget extends StatelessWidget {
  final String telegramId;

  PremiumWidget({required this.telegramId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            builder: (context) => SubscriptionPage(
              telegramId: telegramId,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: ColorManager.currentPrimaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: ColorManager.currentPrimaryColor,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 50,
                child: Stack(
                  children: [
                    Shimmer.fromColors(
                      baseColor: ColorManager.currentPrimaryColor,
                      highlightColor:
                          ColorManager.currentPrimaryColor.withOpacity(0.4),
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
              SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        'Harga Mulai Rp. 10.000',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Tanpa Iklan Yuk Beli ;)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

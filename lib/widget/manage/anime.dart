import 'package:flutter/material.dart';
import 'anime/riwayat.dart';
import 'anime/genre.dart';
import 'anime/trending.dart'; // Import widget Trending
import 'package:flue/color.dart';

class AnimeContent extends StatelessWidget {
  final String telegramId;

  AnimeContent({required this.telegramId});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder(
          // Check if there is anime history for the specified telegram_id
          future: Riwayat(telegramId: telegramId).fetchLatestAnime(),
          builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(); // Return an empty container while checking.
            } else if (snapshot.hasError ||
                !(snapshot.data?['animeHistory'] is List &&
                    (snapshot.data?['animeHistory'] as List).isNotEmpty)) {
              // No anime history found, don't include Riwayat widget
              return Container();
            } else {
              // Include Riwayat widget as there is anime history available
              return Container(
                decoration: BoxDecoration(
                  color: ColorManager.currentAccentColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Riwayat(telegramId: telegramId),
                ),
              );
            }
          },
        ),
        Container(
          color: ColorManager.currentPrimaryColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 8.0, right: 8.0),
                  width: screenWidth,
                  child: GenreList(telegramId: telegramId),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: ColorManager.currentAccentColor,
          child: RecommendedWidget(telegramId: telegramId),
        ),
      ],
    );
  }
}

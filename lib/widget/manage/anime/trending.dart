import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flue/widget/anime-detail.dart';
import 'package:flue/color.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecommendedWidget extends StatefulWidget {
  final String telegramId;

  RecommendedWidget({required this.telegramId});

  @override
  _RecommendedWidgetState createState() => _RecommendedWidgetState();
}

class _RecommendedWidgetState extends State<RecommendedWidget> {
  List<dynamic> animeList = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      color: ColorManager.currentAccentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'Rekomendasi Anime',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.currentPrimaryColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  FontAwesomeIcons.fire,
                  color: ColorManager.currentPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          _buildRecommendedList(),
        ],
      ),
    );
  }

  Widget _buildRecommendedList() {
    return Container(
      height: 240.0, // Adjusted height for better visibility
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: animeList.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildAnimeCard(
            animeList[index]['judul'],
            animeList[index]['image'],
            animeList[index]['anime_id']
                .toString(), // Replace 'anime_id' with the actual key in your API response
          );
        },
      ),
    );
  }

  Widget _buildAnimeCard(String title, String imageUrl, String animeId) {
    return GestureDetector(
      onTap: () {
        int parsedAnimeId =
            int.tryParse(animeId) ?? 0; // Default to 0 if parsing fails
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailPage(
              animeId: parsedAnimeId,
              telegramId: widget.telegramId,
            ),
          ),
        );
      },
      child: Container(
        width: 160.0,
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(12.0), // Adjust the radius as needed
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black54, Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8.0,
                left: 8.0,
                right: 8.0,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> fetchRecommendedAnime() async {
    final response = await http.get(
        Uri.parse('https://ccgnimex.my.id/v2/android/api_rekomendasi.php'));

    if (response.statusCode == 200) {
      print(response.body);
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recommended anime');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAndCacheData();
  }

  Future<void> fetchAndCacheData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String cachedData = prefs.getString('cached_anime_data') ?? "";

      // Check if cached data is still valid (you may need to add a timestamp)
      if (cachedData.isNotEmpty) {
        animeList = json.decode(cachedData);
        setState(() {});
      }

      animeList = await fetchRecommendedAnime();
      prefs.setString('cached_anime_data', json.encode(animeList));

      setState(() {});
    } catch (error) {
      print('Error: $error');
    }

    Future.delayed(Duration(minutes: 10), () {
      fetchAndCacheData();
    });
  }
}

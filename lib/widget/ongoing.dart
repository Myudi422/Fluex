import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'anime-detail.dart';
import 'manage.dart';
import 'package:flue/color.dart';
import 'slider.dart';


class AnimeData {
  final int animeId;
  final String title;
  final String image;
  final int latestEpisode;

  AnimeData({
    required this.animeId,
    required this.title,
    required this.image,
    required this.latestEpisode,
  });
}

class OngoingAnimeWidget extends StatefulWidget {
    final String firstName;
  final String profilePicture;
  final String telegramId;

  OngoingAnimeWidget({required this.firstName,
    required this.profilePicture,
    required this.telegramId,});

  @override
  _OngoingAnimeWidgetState createState() => _OngoingAnimeWidgetState();
}

class _OngoingAnimeWidgetState extends State<OngoingAnimeWidget> {
  List<AnimeData> ongoingAnimeList = [];
  ScrollController _scrollController = ScrollController();
  bool isLoading = true; // Set initial loading state to true

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchOngoingAnimeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Handle reaching the end of the list if needed
    }
  }

  Future<void> saveDataToLocalCache(List<AnimeData> animeList) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (AnimeData anime in animeList) {
      prefs.setString(anime.title, anime.image);
    }
  }

  Future<void> fetchDataFromLocalCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<AnimeData> cachedData = [];
    prefs.getKeys().forEach((key) {
      cachedData.add(
        AnimeData(animeId: 0, title: key, image: prefs.getString(key)!, latestEpisode: 0),
      );
    });
    setState(() {
      ongoingAnimeList.addAll(cachedData);
    });
  }

  Future<void> fetchOngoingAnimeData() async {
    try {
      final response = await http.get(
        Uri.parse('https://ccgnimex.my.id/v2/android/api_ongoing.php'),
      );

      if (response.statusCode == 200) {
        List<dynamic> ongoingAnimeData =
            json.decode(response.body)['ongoing_anime_data'];

        List<AnimeData> animeList = ongoingAnimeData
            .map((data) => AnimeData(
                  animeId: data['anime_id'],
                  title: data['judul'],
                  image: data['gambar'],
                  latestEpisode: data['latest_episode'], // Adjust the key accordingly
                ))
            .toList();

        await saveDataToLocalCache(animeList);

        setState(() {
          ongoingAnimeList.addAll(animeList);
          isLoading = false; // Set loading state to false after data is fetched
        });
      } else {
        throw Exception('Failed to load ongoing anime data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false; // Set loading state to false on error
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return isLoading
      ? _buildLoadingIndicator()
      : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
             colors: [
  ColorManager.currentBackgroundColor.withOpacity(0), // 0% transparency at the top
  ColorManager.currentBackgroundColor.withOpacity(1), // 100% transparency at the bottom
],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180.0,
                width: double.infinity,
                child: ListView.builder(
                  key: Key('ongoing_anime_list'),
                  controller: _scrollController,
                  padding: EdgeInsets.only(left: 14.0, right: 0.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: ongoingAnimeList.length,
                  itemBuilder: (context, index) {
                    AnimeData anime = ongoingAnimeList[index];
                    return buildAnimeItem(anime);
                  },
                ),
              ),
              SizedBox(
                height: 10, // Tambahkan jarak di atas CarouselSlider
              ),
              SliderWidget(telegramId: widget.telegramId,
              firstName: widget.firstName,
              profilePicture: widget.profilePicture,),
              ManageWidget(telegramId: widget.telegramId),
            ],
          ),
        );
}


  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

Widget buildAnimeItem(AnimeData anime) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeDetailPage(
            animeId: anime.animeId,
            telegramId: widget.telegramId,
          ),
        ),
      );
    },
    child: Container(
      margin: EdgeInsets.only(right: 8.0),
      width: 130.0,
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: anime.image,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  color: Colors.grey,
                  width: 130.0,
                  height: 180.0,
                ),
              ),
              errorWidget: (context, url, error) => Icon(Icons.error),
              fit: BoxFit.cover,
              width: 130.0,
              height: 180.0,
            ),
          ),
          Container(
            width: 130.0,
            height: 180.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black, Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          Positioned(
            top: 8.0,
            left: 8.0,
            child: Container(
              padding: EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Eps: ${anime.latestEpisode}',
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8.0,
            left: 8.0,
            right: 8.0,
            child: Container(
              padding: EdgeInsets.all(4.0),
              child: Text(
                _truncateText(anime.title),
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  String _truncateText(String text) {
    const int maxTextLength = 20; // Adjust the maximum length as needed
    return text.length > maxTextLength ? '${text.substring(0, maxTextLength)}...' : text;
  }
}

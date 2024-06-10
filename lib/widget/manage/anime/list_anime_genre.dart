import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flue/widget/anime-detail.dart';

class AnimeListPage extends StatelessWidget {
  final String selectedGenre;
  final String telegramId;

  AnimeListPage({required this.selectedGenre, required this.telegramId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$selectedGenre'),
      ),
      body: FutureBuilder(
        // Fetch anime data from API
        future: fetchAnimeData(selectedGenre),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            // Display anime data in a grid
            List animeList = snapshot.data as List;
            double itemWidth = MediaQuery.of(context).size.width / 2; // Adjust item width based on your design
            int crossAxisCount = (MediaQuery.of(context).size.width / itemWidth).round();
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount < 2 ? 2 : crossAxisCount,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: animeList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Navigate to AnimeDetailPage with animeId and telegramId
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimeDetailPage(
                          animeId: int.parse(animeList[index]['anime_id']),
                          telegramId: telegramId,
                        ),
                      ),
                    );
                  },
                  child: _buildAnimeItem(animeList[index]),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildAnimeItem(Map<String, dynamic> anime) {
    return Card(
      elevation: 4.0,
      child: Stack(
        children: [
          // Shimmer loading effect
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey,
            ),
          ),

          // Cached Network Image
          CachedNetworkImage(
            imageUrl: anime['image'], // Assuming 'image_url' is the key for the image URL
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black, Colors.transparent],
              ),
            ),
          ),

          // Title
          Positioned(
            bottom: 8.0,
            left: 8.0,
            right: 8.0,
            child: Text(
              anime['judul'], // Assuming 'title' is the key for the anime title
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Future<List> fetchAnimeData(String genre) async {
    // Replace the URL with your actual API endpoint
    final String apiUrl = 'https://ccgnimex.my.id/v2/android/api_genre.php?genre=$genre';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load anime data');
    }
  }
}

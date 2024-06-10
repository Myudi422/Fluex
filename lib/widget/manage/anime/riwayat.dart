import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flue/widget/anime-detail.dart';
import 'dart:convert';
import 'package:flue/color.dart';

class Riwayat extends StatelessWidget {
  final String telegramId;

  Riwayat({required this.telegramId});

  Future<Map<String, dynamic>> fetchLatestAnime() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://ccgnimex.my.id/v2/android/api_riwayat.php?telegram_id=$telegramId&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('animeHistory') &&
            data['animeHistory'] is List &&
            (data['animeHistory'] as List).isNotEmpty) {
          return data;
        } else {
          // No anime history found for the specified telegram_id
          return {'animeHistory': []};
        }
      } else {
        throw Exception('Failed to load latest anime');
      }
    } catch (error) {
      print('Error: $error');
      throw Exception('Failed to load latest anime');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchLatestAnime(),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Use the LoadingState widget with a larger CircularProgressIndicator
          return LoadingState();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final List<dynamic> animeHistory =
              snapshot.data!['animeHistory'] as List<dynamic>;

          if (animeHistory.isNotEmpty) {
            final latestAnime = animeHistory[0];
            final judulAnime = latestAnime['judul'];
            final imageAnime = latestAnime['image'];
            final animeId = int.parse(latestAnime['anime_id'].toString());

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimeDetailPage(
                      animeId: animeId,
                      telegramId: telegramId,
                    ),
                  ),
                );
              },
              child: AnimeHistoryCard(
                judulAnime: judulAnime,
                imageAnime: imageAnime,
              ),
            );
          } else {
            return Container();
          }
        } else {
          return Text('Unknown error');
        }
      },
    );
  }
}

// Loading state widget with a larger CircularProgressIndicator
class LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Center(
        child: SizedBox(
          width: 50.0,
          height: 50.0,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

// Widget for displaying anime history card
class AnimeHistoryCard extends StatelessWidget {
  final String judulAnime;
  final String imageAnime;

  AnimeHistoryCard({required this.judulAnime, required this.imageAnime});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          child: Image.network(
            imageAnime,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terakhir Ditonton',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.currentPrimaryColor,
                ),
              ),
              SizedBox(height: 2.0),
              Text(
                judulAnime,
                style: TextStyle(
                  fontSize: 18.0,
                  color: ColorManager.currentHomeColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.0),
        Icon(
          Icons.play_circle_fill,
          size: 40.0,
          color: ColorManager.currentPrimaryColor,
        ),
      ],
    );
  }
}

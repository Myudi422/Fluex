import 'package:flutter/material.dart';

class AnimeInfoWidget extends StatelessWidget {
  final Map<String, dynamic> animeData;
  final int episodeNumber;

  AnimeInfoWidget({
    required this.animeData,
    required this.episodeNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 14.0), // Tambahkan padding sebelah kiri
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${animeData['title']['romaji']}',
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: 8.0,
          ), // Tambahkan jarak antara judul dan teks episode
          Row(
            children: [
              Text(
                'Episode ${episodeNumber}',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.0),
              Container(
                width: 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.0),
              Text(
                '${animeData['duration']} menit',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.0),
              Container(
                width: 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.0),
              Text(
                '${animeData['status']}',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

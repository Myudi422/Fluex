import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flue/widget/anime-detail.dart';
import 'package:flue/color.dart';

class AnimeListPage extends StatefulWidget {
  final String selectedGenre;
  final String telegramId;

  AnimeListPage({required this.selectedGenre, required this.telegramId});

  @override
  _AnimeListPageState createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage> {
  List animeList = [];
  String _sortOption = 'latest'; // Default sort option

  @override
  void initState() {
    super.initState();
    fetchAnimeData(widget.selectedGenre).then((data) {
      setState(() {
        animeList = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Ensure compatibility with iconTheme
        backgroundColor: Colors.black, // Set app bar background color to black
        iconTheme:
            IconThemeData(color: Colors.white), // Set back icon color to white
        title: Text(
          '${widget.selectedGenre}',
          style:
              TextStyle(color: Colors.white), // Set app bar text color to white
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
                right: 16.0), // Adjust the padding as needed
            child: DropdownButton<String>(
              value: _sortOption,
              icon: Icon(Icons.sort,
                  color: Colors.white), // Set icon color to white
              dropdownColor:
                  Colors.black, // Set dropdown background color to black
              onChanged: (String? newValue) {
                setState(() {
                  _sortOption = newValue!;
                  sortAnimeList();
                });
              },
              items: <String>['latest', 'A-Z', 'Z-A', 'oldest']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                        color: Colors
                            .white), // Set dropdown item text color to white
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorManager.currentBackgroundColor,
              ColorManager.currentPrimaryColor
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: animeList.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: animeList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeDetailPage(
                            animeId: int.parse(animeList[index]['anime_id']),
                            telegramId: widget.telegramId,
                          ),
                        ),
                      );
                    },
                    child: _buildAnimeItem(animeList[index]),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildAnimeItem(Map<String, dynamic> anime) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        height: 150.0, // Adjust height based on your design
        child: Row(
          children: [
            // Cached Network Image
            CachedNetworkImage(
              imageUrl: anime['image'],
              fit: BoxFit.cover,
              width: 100.0, // Adjust width based on your design
              height: double.infinity,
            ),
            // Title and description
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black
                      .withOpacity(0.4), // Transparent black background
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime['judul'],
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.0),
                    Expanded(
                      child: Text(
                        anime['sinopsis'],
                        style: TextStyle(fontSize: 14.0, color: Colors.white),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List> fetchAnimeData(String genre) async {
    final String apiUrl =
        'https://ccgnimex.my.id/v2/android/api_genre.php?genre=$genre';
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load anime data');
    }
  }

  void sortAnimeList() {
    switch (_sortOption) {
      case 'latest':
        animeList.sort((a, b) => b['id'].compareTo(a['id']));
        break;
      case 'A-Z':
        animeList.sort((a, b) => a['judul'].compareTo(b['judul']));
        break;
      case 'Z-A':
        animeList.sort((a, b) => b['judul'].compareTo(a['judul']));
        break;
      case 'oldest':
        animeList.sort((a, b) => a['id'].compareTo(b['id']));
        break;
    }
  }
}

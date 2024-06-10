import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'list_anime_genre.dart';
import 'package:flue/color.dart';

class GenreList extends StatefulWidget {
  final String telegramId;

  GenreList({required this.telegramId});

  @override
  _GenreListState createState() => _GenreListState();
}

class _GenreListState extends State<GenreList> {
  List<String> genres = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGenres();
  }

  Future<void> fetchGenres() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Cek apakah data genre sudah disimpan lokal
    if (prefs.containsKey('genres')) {
      final List<String> storedGenres =
          List<String>.from(jsonDecode(prefs.getString('genres')!));
      setState(() {
        genres = storedGenres;
        isLoading = false;
      });
    } else {
      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': '''
            query {
              GenreCollection
            }
          '''
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> genreList = data['data']['GenreCollection'];

        // Filter genre "Hentai"
        final filteredGenres = genreList.cast<String>().where((genre) => genre != "Hentai").toList();

        setState(() {
          genres = filteredGenres;
          isLoading = false;
        });

        // Simpan data genre ke lokal storage
        prefs.setString('genres', jsonEncode(genres));
      } else {
        throw Exception('Failed to load genres');
      }
    }
  } catch (e) {
    print('Error: $e');
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.currentPrimaryColor,
      ),
      child: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : genres.isEmpty
              ? Center(
                  child: Text('No genres available'),
                )
              : Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: genres
                        .map((genre) => _buildGenreItem(genre))
                        .toList(),
                  ),
                ),
              ),
    );
  }

  Widget _buildGenreItem(String genre) {
    return GestureDetector(
      onTap: () {
        // Navigate to the list of anime for the selected genre
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeListPage(selectedGenre: genre, telegramId: widget.telegramId),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 8.0),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: ColorManager.currentAccentColor),
        ),
        child: Text(
          genre,
          style: TextStyle(fontSize: 14.0, color: ColorManager.currentHomeColor),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../anime-detail.dart';
import 'dart:convert';

class InfoWidget extends StatelessWidget {
  final int animeId;
  final String telegramId;
  final Map<String, dynamic> animeData;

  InfoWidget(
      {required this.animeData,
      required this.animeId,
      required this.telegramId});

  Future<String> fetchSynopsis(int animeId) async {
    final Uri apiUrl = Uri.parse(
        'https://ccgnimex.my.id/v2/android/detail_anime.php?anime_id=$animeId');

    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['sinopsis'] ?? 'No synopsis available';
    } else {
      throw Exception('Failed to load synopsis for anime ID: $animeId');
    }
  }

  Future<Map<String, dynamic>> fetchRecommendations(int animeId) async {
    final Uri apiUrl = Uri.parse(
        'https://ccgnimex.my.id/v2/android/cekv2.php?anime_id=$animeId');

    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recommendations for anime ID: $animeId');
    }
  }

  Widget _buildSynopsis() {
    return FutureBuilder<String>(
      future: fetchSynopsis(animeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text(
            'Failed to load synopsis',
            style: TextStyle(color: Colors.red),
          );
        } else {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              snapshot.data ?? 'No synopsis available',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 8.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '${animeData['title']['romaji']}',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildGenresSection(),
          ),
          SizedBox(height: 8.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildCharacterSection(),
          ),
          SizedBox(height: 16.0),
          if (_hasPrequelOrSequel()) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  if (_hasPrequel())
                    Expanded(child: _buildRelationButton('Prequel', context)),
                  if (_hasSequel()) SizedBox(width: 8.0),
                  if (_hasSequel())
                    Expanded(child: _buildRelationButton('Sequel', context)),
                ],
              ),
            ),
            SizedBox(height: 8.0),
          ],
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Synopsis',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8.0),
          _buildSynopsis(),
          SizedBox(height: 8.0),
          if (animeData['recommendations']['edges'].isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildRecommendationSection(),
            ),
            SizedBox(height: 20.0),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          _buildIconWithText(
              FontAwesomeIcons.fire, 'Popularity: ${animeData['popularity']}'),
          SizedBox(width: 8.0),
          _buildIconWithText(
              FontAwesomeIcons.star, 'Score: ${animeData['averageScore']}'),
        ],
      ),
    );
  }

  Widget _buildGenresSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: _buildGenres(),
    );
  }

  Widget _buildCharacterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _buildCharacterWidgets(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCharacterWidgets() {
    List<dynamic> characters = animeData['characters']['edges'];
    return characters.map<Widget>((character) {
      final String role = character['role'];
      final String characterName = character['node']['name']['full'];
      final String image = character['node']['image']['large'];

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32.0,
                  backgroundImage: CachedNetworkImageProvider(image),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              characterName,
              style: TextStyle(fontSize: 12.0, color: Colors.white),
            ),
            SizedBox(height: 4.0),
            Text(
              '$role',
              style: TextStyle(fontSize: 10.0, color: Colors.white70),
            ),
            SizedBox(height: 16.0),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRecommendationSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchRecommendations(animeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text(
            'Failed to load recommendations',
            style: TextStyle(color: Colors.red),
          );
        } else {
          Map<String, dynamic> availabilityStatus =
              snapshot.data!['availability_status'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Rekomendasi Terkait',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availabilityStatus.keys.map<Widget>((animeId) {
                    Map<String, dynamic> recommendationData =
                        availabilityStatus[animeId];
                    String title = recommendationData['judul'] ?? '';
                    String posterUrl = recommendationData['image'] ?? '';
                    String status = recommendationData['status'] ?? '';

                    if (posterUrl.isNotEmpty &&
                        title.isNotEmpty &&
                        status.isNotEmpty) {
                      return _buildRecommendationItem(
                          title, posterUrl, status, context, animeId);
                    } else {
                      return SizedBox
                          .shrink(); // Ignore if any of the required fields are empty
                    }
                  }).toList(),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildRecommendationItem(String title, String posterUrl,
      String availabilityStatus, BuildContext context, String animeId) {
    Color statusColor =
        availabilityStatus == 'tersedia' ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailPage(
                animeId: int.parse(animeId), telegramId: telegramId),
          ),
        );
      },
      child: Container(
        width: 120.0,
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 4.0,
            ),
          ],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: posterUrl,
                width: 120.0,
                height: 150.0,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  padding: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    availabilityStatus,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87.withOpacity(0.6),
                        Colors.transparent
                      ],
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotAvailablePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Anime Belum Tersedia'),
          content: Text('Anime belum tersedia, silahkan request ke admin.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the popup
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getAvailabilityLabel(String availabilityStatus) {
    switch (availabilityStatus) {
      case 'tersedia':
        return 'Tersedia';
      case 'tidak ada':
        return 'Belum ada';
      default:
        return 'Error';
    }
  }

  Widget _getAvailabilityIcon(String availabilityStatus) {
    switch (availabilityStatus) {
      case 'tersedia':
        return Icon(
          FontAwesomeIcons.checkCircle,
          color: Colors.white, // Warna bisa disesuaikan
          size: 10.0,
        );
      case 'tidak ada':
        return Icon(
          FontAwesomeIcons.timesCircle,
          color: Colors.white, // Warna bisa disesuaikan
          size: 10.0,
        );
      default:
        return Icon(
          FontAwesomeIcons.exclamationCircle,
          color: Colors.white, // Warna bisa disesuaikan
          size: 10.0,
        );
    }
  }

  Widget _buildIconWithText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        SizedBox(width: 8.0),
        Text(
          text,
          style: TextStyle(fontSize: 12.0, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRelationButton(String relationType, BuildContext context) {
    IconData icon;
    if (relationType == 'Prequel') {
      icon = FontAwesomeIcons.arrowLeft;
    } else if (relationType == 'Sequel') {
      icon = FontAwesomeIcons.arrowRight;
    } else {
      icon = Icons.star;
    }

    return ElevatedButton.icon(
      onPressed: () async {
        final bool relatedAnimeExists =
            await checkRelatedAnimeExists(relationType);

        if (relatedAnimeExists) {
          navigateToAnimeDetail(context, relationType);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Belum Tersedia, silahkan hub admin di chatroom untuk ditambahkan!'),
            ),
          );
        }
      },
      icon: Icon(icon),
      label: Text(relationType),
    );
  }

  Future<bool> checkRelatedAnimeExists(String relationType) async {
    final bool isPrequel = relationType == 'Prequel';
    final bool isSequel = relationType == 'Sequel';

    final response = await http.get(
      Uri.parse(
          'https://ccgnimex.my.id/v2/android/cek_relation.php?anime_id=$animeId'),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final relatedAnimeId = isPrequel
          ? responseData['relation']['prequel']
          : responseData['relation']['sequel'];
      return relatedAnimeId != null;
    } else {
      throw Exception('Failed to check related anime existence');
    }
  }

  Future<void> navigateToAnimeDetail(
      BuildContext context, String relationType) async {
    final bool isPrequel = relationType == 'Prequel';
    final bool isSequel = relationType == 'Sequel';
    final response = await http.get(
      Uri.parse(
          'https://ccgnimex.my.id/v2/android/cek_relation.php?anime_id=$animeId'),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final relatedAnimeId = isPrequel
          ? responseData['relation']['prequel']
          : responseData['relation']['sequel'];
      if (relatedAnimeId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailPage(
              animeId: relatedAnimeId,
              telegramId: telegramId ?? '',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Belum Tersedia, silahkan hub admin di chatroom untuk ditambahkan!'),
          ),
        );
      }
    } else {
      throw Exception('Failed to fetch related anime');
    }
  }

  bool _hasPrequelOrSequel() {
    return _hasPrequel() || _hasSequel();
  }

  bool _hasPrequel() {
    return animeData['relations']['edges']
        .any((relation) => relation['relationType'] == 'PREQUEL');
  }

  bool _hasSequel() {
    return animeData['relations']['edges']
        .any((relation) => relation['relationType'] == 'SEQUEL');
  }

  Widget _buildGenres() {
    List<Widget> genreWidgets = animeData['genres'].map<Widget>((genre) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          margin: EdgeInsets.only(right: 4.0, bottom: 8.0),
          child: Text(
            genre,
            style: TextStyle(fontSize: 10.0, color: Colors.white70),
          ),
        ),
      );
    }).toList();

    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      children: genreWidgets,
    );
  }
}

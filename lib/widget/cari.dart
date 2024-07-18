import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'anime-detail.dart';

class CariPage extends StatefulWidget {
  final String telegramId;

  CariPage({required this.telegramId});

  @override
  _CariPageState createState() => _CariPageState();
}

class _CariPageState extends State<CariPage> {
  TextEditingController _controller = TextEditingController();
  List _searchResults = [];
  bool _isLoading = false;

  Future<void> _cariData(String keyword) async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(Uri.parse(
        'https://ccgnimex.my.id/v2/android/api_search.php?keyword=$keyword'));

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);

      setState(() {
        _searchResults = jsonResponse;
      });
    } else {
      throw Exception('Gagal mengambil data dari API');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? floatingActionButton; // Declare as nullable

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Anime Search', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Masukkan judul pencarian...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _cariData(_controller.text);
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey[850],
                ),
                child: Text('Cari', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 16),
              _isLoading
                  ? _buildShimmerLoading()
                  : _searchResults.isNotEmpty
                      ? Expanded(
                          child: GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _calculateCrossAxisCount(context),
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              return _buildAnimeCard(_searchResults[index]);
                            },
                          ),
                        )
                      : SizedBox.shrink(),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> animeData) {
    return GestureDetector(
      onTap: () async {
        _navigateToAnimeDetail(animeData);
      },
      child: Card(
        color: Colors.grey[900],
        elevation: 4.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: animeData['image'],
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _truncateTitle(animeData['judul']),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _calculateCrossAxisCount(context),
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return _buildAnimeCard({
            'image': '',
            'judul': '',
            'animeId': '',
          });
        },
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / 200).floor();
    return crossAxisCount > 0 ? crossAxisCount : 1;
  }

  String _truncateTitle(String title) {
    const int maxTitleLength = 20;
    return title.length > maxTitleLength
        ? '${title.substring(0, maxTitleLength)}...'
        : title;
  }

  void _navigateToAnimeDetail(Map<String, dynamic> animeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimeDetailPage(
          telegramId: widget.telegramId,
          animeId: int.parse(animeData['anime_id'].toString()),
        ),
      ),
    );
  }
}

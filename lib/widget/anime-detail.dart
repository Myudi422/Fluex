import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_detail.dart';
import 'anime-detail/cover.dart';
import 'anime-detail/manage_detail.dart';
import 'package:flue/color.dart';

class AnimeDetailPage extends StatefulWidget {
  final int animeId;
  final String telegramId;

  AnimeDetailPage({required this.animeId, required this.telegramId});

  @override
  _AnimeDetailPageState createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  late Future<Map<String, dynamic>> animeDetails;
  late Future<String?> translation;

  bool isLoaded = false;
  double verticalOffset = 0.0;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    animeDetails = ApiService.fetchAnimeDetails(widget.animeId);

    // Check favorite status when the page initializes
    checkFavoriteStatus(); // Check favorite status on initial widget creation

    Future.microtask(() async {
      setState(() {
        isLoaded = true;
      });
    });
  }

  void checkFavoriteStatus() async {
    var response = await http.post(
      Uri.parse('https://ccgnimex.my.id/v2/android/fav_cek.php'),
      body: {
        'animeId': widget.animeId.toString(),
        'telegramId': widget.telegramId,
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        // Update isFavorite based on response body
        isFavorite = response.body == 'Anime already in favorites';
      });
    } else {
      print('Failed to check favorite status');
    }
  }

void _handleStarIconTap() async {
  var response = await http.post(
    Uri.parse('https://ccgnimex.my.id/v2/android/fav.php'),
    body: {
      'animeId': widget.animeId.toString(),
      'telegramId': widget.telegramId,
      'action': isFavorite ? 'remove' : 'add', // Add or remove based on current state
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      // Update isFavorite based on server response
      isFavorite = response.body == 'Anime added to favorites successfully';
    });

    // Show Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Anime Sudah ditambahkan ke Favorit' : 'Anime Dihapus dari Daftar Favorit Anda!',
        ),
      ),
    );
  } else {
    print('Failed to update favorite status');
  }
}


 Future<void> addToFavorites() async {
  var response = await http.post(
    Uri.parse('https://ccgnimex.my.id/v2/android/fav.php'),
    body: {
      'animeId': widget.animeId.toString(),
      'telegramId': widget.telegramId,
      'action': 'add',
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      // Set isFavorite based on server response
      isFavorite = response.body == 'Anime added to favorites successfully';
    });
  } else {
    print('Failed to add to favorites');
  }
}

Future<void> removeFromFavorites() async {
  var response = await http.post(
    Uri.parse('https://ccgnimex.my.id/v2/android/fav.php'),
    body: {
      'animeId': widget.animeId.toString(),
      'telegramId': widget.telegramId,
      'action': 'remove',
    },
  );

  if (response.statusCode == 200) {
    setState(() {
      // Set isFavorite based on server response
      isFavorite = response.body == 'Anime removed from favorites successfully';
    });
  } else {
    print('Failed to remove from favorites');
  }
}

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      verticalOffset += details.primaryDelta!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.currentBackgroundColor,
      body: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        child: FutureBuilder<Map<String, dynamic>>(
          future: animeDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                !isLoaded) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              Map<String, dynamic> animeData = snapshot.data!;

              SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ));

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.height * 0.10,
                    floating: false,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        color: ColorManager.currentBackgroundColor,
                        child: CoverWidget(
                          coverImageUrl: animeData['coverImage']['large'],
                          bannerImageUrl: animeData['bannerImage'],
                        ),
                      ),
                    ),
                    actions: [
                      Row(
                        children: [
                          _buildTextWithBorderRadius(animeData['status']),
                          SizedBox(width: 8.0),
                          _buildTextWithBorderRadius(animeData['format']),
                          SizedBox(width: 8.0),
                          CupertinoButton(
                            onPressed: _handleStarIconTap,
                            child: Icon(
                              CupertinoIcons.star,
                              color: isFavorite ? Colors.yellow : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                    iconTheme: IconThemeData(color: Colors.white),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.all(0.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          ManageDetailWidget(
                            animeData: animeData,
                            animeId: widget.animeId,
                            telegramId: widget.telegramId,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildTextWithBorderRadius(String text) {
    return Container(
      padding: EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.white,
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.0,
          color: Colors.white,
        ),
      ),
    );
  }
}

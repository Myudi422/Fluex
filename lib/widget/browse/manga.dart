import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flue/widget/browse/komik-detail.dart';
import 'package:flue/admob/unity.dart';

class MangaPage extends StatefulWidget {
  final String telegramId;
  MangaPage({required this.telegramId});

  @override
  _MangaPageState createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  final String baseUrl = 'https://ccgnimex.my.id/v2/android/komik/api_home.php';
  int currentPage = 1;
  bool isLoading = false;
  List<Map<String, dynamic>> comics = [];
  String searchKeyword = "";
  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  String userAccess = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(_scrollListener);
    _fetchUserAccess();
    UnityAdManager.initialize(); // Inisialisasi Unity Ads
    UnityAdManager.loadInterstitialAd(); // Memuat iklan interstisial saat widget diinisialisasi
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchData() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      _loadDataAndUpdateComics();
    }
  }


    Future<void> _fetchUserAccess() async {
    final apiUrl = "https://ccgnimex.my.id/v2/android/cek_akses.php?telegram_id=${widget.telegramId}";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        userAccess = data['akses']; // Mendapatkan status akses pengguna
      });
    }
  }

  Future<void> _loadDataAndUpdateComics() async {
  try {
    String apiUrl = '$baseUrl?page=$currentPage&telegram_id=${widget.telegramId}';
    if (searchKeyword.isNotEmpty) {
      apiUrl = '$baseUrl?search=$searchKeyword&page=$currentPage&telegram_id=${widget.telegramId}';
    }

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<Map<String, dynamic>> newComics = List<Map<String, dynamic>>.from(data);

      setState(() {
        comics.addAll(newComics);
        isLoading = false;
        currentPage++;
      });

      // Load interstitial ad when new data is loaded
      if (userAccess != 'Premium') {
        UnityAdManager.loadInterstitialAd();
        UnityAdManager.showInterstitialAd(
          onComplete: (placementId) => print('Load Complete $placementId'),
          onFailed: (String placementId, dynamic error, String message) {
            // Handle interstitial ad failure
          },
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print('Error fetching data: $e');
    setState(() {
      isLoading = false;
    });
  }
}

  void _scrollListener() {
    if (!isLoading && _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _fetchData();
    }
  }

  void _navigateToMangaDetail(String mangaUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailPage(
          mangaUrl: mangaUrl,
          telegramId: widget.telegramId,
        ),
      ),
    );
  }

  void _performSearch() {
    setState(() {
      searchKeyword = _searchController.text;
      comics.clear();
      currentPage = 1;
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 70.0, left: 8.0, right: 8.0),
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: comics.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _navigateToMangaDetail(comics[index]['url']);
                        },
                        child: Card(
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8.0),
                                    topRight: Radius.circular(8.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      comics[index]['chapter'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.start,
                                    ),
                                    if (comics[index]['title_eps'] != null && comics[index]['title_eps'] != '')
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                        child: Row(
                                          children: [
                                            Transform.scale(
                                              scale: 0.7,
                                              child: Icon(
                                                Icons.history,
                                                color: Colors.white,
                                                size: 15.0,
                                              ),
                                            ),
                                            SizedBox(width: 4.0),
                                            Text(
                                              comics[index]['title_eps'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: comics[index]['image'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comics[index]['title'],
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari Manga',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _performSearch,
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'view_wallpaper.dart';
import 'package:flue/admob/unity.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class WallpaperPage extends StatefulWidget {
  final String telegramId;

  WallpaperPage({required this.telegramId});

  
  @override
  _WallpaperPageState createState() => _WallpaperPageState();
}

class _WallpaperPageState extends State<WallpaperPage> {
  List<Map<String, dynamic>> wallpapers = [];
  List<Map<String, dynamic>> filteredWallpapers = [];
  int currentPage = 1;
  bool isLoadingMore = false;
  late ScrollController _scrollController;
  TextEditingController searchController = TextEditingController();
  String userAccess = ''; // Status akses pengguna

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchWallpapers();
    searchController.addListener(_onSearchChanged);
    _fetchUserAccess(); // Panggil fungsi untuk memeriksa akses pengguna
  }

  Future<void> _fetchWallpapers() async {
    if (isLoadingMore) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    final apiUrl = "https://ccgnimex.my.id/v2/android/wallpaper/api.php?page=$currentPage";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        data.forEach((wallpaperData) {
          final Map<String, dynamic> wallpaper = {
            'arturl_md': wallpaperData['arturl_md'],
            'arturl_ori': wallpaperData['arturl_ori'],
            'animename': wallpaperData['animename'],
          };
          wallpapers.add(wallpaper);
        });
        currentPage++;
        isLoadingMore = false;
      });

      // Load interstitial ad after fetching new wallpapers
      UnityAdManager.loadInterstitialAd();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _fetchWallpapers();
    }
  }

  void _onSearchChanged() {
    setState(() {
      filteredWallpapers = wallpapers
          .where((wallpaper) => wallpaper['animename']
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    });
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

  Widget _buildWallpaperItem(int index) {
    final wallpaper = filteredWallpapers.length == 0
        ? wallpapers[index]
        : filteredWallpapers[index];
    final imageUrl = wallpaper['arturl_md'];

    return GestureDetector(
      onTap: () {
        _showInterstitialAd(wallpaper);
      },
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }

  void _showInterstitialAd(Map<String, dynamic> wallpaper) {
    if (userAccess != 'Premium') { // Hanya menampilkan iklan jika pengguna memiliki akses Free
      UnityAdManager.showInterstitialAd(
        onComplete: (String placementId) {
          _navigateToViewWallpaper(wallpaper);
        },
        onFailed: (String placementId, dynamic error, String message) {
          // Handle the error here if needed
          print('Interstitial ad failed to load: $error, $message');
          // Navigate to the wallpaper view page regardless of the error
          _navigateToViewWallpaper(wallpaper);
        },
      );
    } else {
      _navigateToViewWallpaper(wallpaper); // Jika pengguna memiliki akses Premium, langsung tampilkan wallpaper tanpa iklan
    }
  }

  void _navigateToViewWallpaper(Map<String, dynamic> wallpaper) {
    // Reset interstitial ad status
    UnityAdManager.loadInterstitialAd();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewWallpaperPage(imageUrl: wallpaper['arturl_ori']),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari Berdasarkan Nama Anime',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StaggeredGridView.countBuilder(
              controller: _scrollController,
              crossAxisCount: 4,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              itemCount: filteredWallpapers.length == 0
                  ? wallpapers.length
                  : filteredWallpapers.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildWallpaperItem(index);
              },
              staggeredTileBuilder: (int index) {
                return StaggeredTile.count(2, index.isEven ? 3 : 2);
              },
            ),
          ),
        ],
      ),
    );
  }
}

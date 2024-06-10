import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import './widget/anime-detail.dart';
import './widget/anime-detail/streaming/core/convertdurasi.dart';
import 'package:flue/color.dart';

class HistoryPage extends StatefulWidget {
  final String telegramId;

  HistoryPage({required this.telegramId});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  ScrollController _scrollController = ScrollController();
  Map<String, List<dynamic>> groupedAnimeHistory = {};
  bool isLoading = true;
  int currentPage = 1;
  bool isEndOfList = false;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    Future.delayed(Duration(seconds: 1), () {
      fetchAnimeHistory();
    });
  }

  void _scrollListener() {
    if (!isEndOfList &&
        _scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      currentPage++;
      fetchAnimeHistory();
    }
  }

  Future<void> fetchAnimeHistory() async {
    if (widget.telegramId == null || widget.telegramId.isEmpty) {
      print('ID Telegram kosong atau tidak valid');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://ccgnimex.my.id/v2/android/api_riwayat.php?telegram_id=${widget.telegramId}&page=$currentPage',
        ),
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse.containsKey('animeHistory')) {
          List<dynamic> newAnimeList = decodedResponse['animeHistory'];
          if (newAnimeList.isNotEmpty) {
            groupedAnimeHistory.addAll(groupAnimeByDate(newAnimeList));
          } else {
            print('No more anime history available');
            isEndOfList = true;
          }
          setState(() {
            isLoading = false;
          });
        } else {
          print('Kunci riwayat anime tidak ditemukan dalam respons');
          setState(() {
            isLoading = false;
            isError = true;
          });
        }
      } else {
        print('Gagal mengambil riwayat anime. Kode status: ${response.statusCode}');
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (error) {
      print('Error mengambil riwayat anime: $error');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Map<String, List<dynamic>> groupAnimeByDate(List<dynamic> animeList) {
    Map<String, List<dynamic>> groupedMap = {};

    for (var anime in animeList) {
      final lastWatchedDate = DateTime.parse(anime['last_watched']);
      final formattedDate = _getFormattedDate(lastWatchedDate);

      if (!groupedMap.containsKey(formattedDate)) {
        groupedMap[formattedDate] = [];
      }

      groupedMap[formattedDate]!.add(anime);
    }

    return groupedMap;
  }

  String _getFormattedDate(DateTime lastWatchedDate) {
    final currentDate = DateTime.now();
    final difference = currentDate.difference(lastWatchedDate);

    if (difference.inDays == 0) {
      return 'Hari Ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${lastWatchedDate.day} ${_getMonthName(lastWatchedDate.month)} ${lastWatchedDate.year}';
    }
  }

  String _getMonthName(int month) {
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return monthNames[month];
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  int _calculateItemCount() {
    return isEndOfList ? groupedAnimeHistory.length : groupedAnimeHistory.length + 1;
  }

  Widget _buildLoadingIndicator() {
if (isError) {
return Center(
child: Text('Riwayat Sudah Habis.',
style: TextStyle(color: ColorManager.currentHomeColor),
),
);
} else {
return Center(
child: CircularProgressIndicator(
valueColor: AlwaysStoppedAnimation<Color>(ColorManager.currentPrimaryColor),
),
);
}
}

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3.0,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 150.0,
                      height: 150.0,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: double.infinity,
                            height: 16.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 100.0,
                            height: 16.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 80.0,
                            height: 16.0,
                            color: Colors.white,
                          ),
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
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorManager.currentPrimaryColor, ColorManager.currentAccentColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0), // Adjust the radius as needed
          topRight: Radius.circular(10.0), // Adjust the radius as needed
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
            child: isLoading
                ? _buildShimmerList()
                : groupedAnimeHistory.isEmpty
                    ? Text('Tidak ditemukan riwayat anime.')
                    : NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (!isEndOfList &&
                              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                            currentPage++;
                            fetchAnimeHistory();
                          }
                          return true;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _calculateItemCount(),
                          itemBuilder: (context, index) {
                            if (index == _calculateItemCount() - 1) {
                              return _buildLoadingIndicator();
                            }
                            final date = groupedAnimeHistory.keys.elementAt(index);
                            final animeList = groupedAnimeHistory[date];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
  padding: const EdgeInsets.all(8.0),
  child: Text(
    date,
    style: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: ColorManager.currentHomeColor,
    ),
  ),
),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: animeList!.length,
                                  itemBuilder: (context, index) {
                                    final anime = animeList[index];
                                    return AnimeHistoryItem(anime: anime, telegramId: widget.telegramId);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

class AnimeHistoryItem extends StatelessWidget {
  final dynamic anime;
  final String telegramId;

  AnimeHistoryItem({required this.anime, required this.telegramId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(
                animeId: int.parse(anime['anime_id'].toString()), // Convert anime_id to int
                telegramId: telegramId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  anime['image'],
                  fit: BoxFit.cover,
                  width: 100.0,
                  height: 120.0,
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime['judul'],
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Episode: ${anime['episode_number']}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Waktu: ${convertDuration(anime['video_time'].toString())}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

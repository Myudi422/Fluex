import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flue/color.dart';
import 'package:flue/widget/browse/komik-detail.dart';

class MangaHistoryPage extends StatefulWidget {
  final String telegramId;

  MangaHistoryPage({required this.telegramId});

  @override
  _MangaHistoryPageState createState() => _MangaHistoryPageState();
}

class _MangaHistoryPageState extends State<MangaHistoryPage> {
  ScrollController _scrollController = ScrollController();
  Map<String, List<dynamic>> groupedMangaHistory = {};
  bool isLoading = true;
  int currentPage = 1;
  bool isEndOfList = false;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    Future.delayed(Duration(seconds: 1), () {
      fetchMangaHistory();
    });
  }

  void _scrollListener() {
    if (!isEndOfList &&
        _scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      currentPage++;
      fetchMangaHistory();
    }
  }

  Future<void> fetchMangaHistory() async {
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
          'https://ccgnimex.my.id/v2/android/api_riwayat_manga.php?telegram_id=${widget.telegramId}&page=$currentPage',
        ),
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse.containsKey('mangaHistory')) {
          List<dynamic> newMangaList = decodedResponse['mangaHistory'];
          if (newMangaList.isNotEmpty) {
            groupedMangaHistory.addAll(groupMangaByDate(newMangaList));
          } else {
            print('No more manga history available');
            isEndOfList = true;
          }
          setState(() {
            isLoading = false;
          });
        } else {
          print('Kunci riwayat manga tidak ditemukan dalam respons');
          setState(() {
            isLoading = false;
            isError = true;
          });
        }
      } else {
        print('Gagal mengambil riwayat manga. Kode status: ${response.statusCode}');
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (error) {
      print('Error mengambil riwayat manga: $error');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Map<String, List<dynamic>> groupMangaByDate(List<dynamic> mangaList) {
    Map<String, List<dynamic>> groupedMap = {};

    for (var manga in mangaList) {
      final lastWatchedDate = DateTime.parse(manga['last_watched']);
      final formattedDate = _getFormattedDate(lastWatchedDate);

      if (!groupedMap.containsKey(formattedDate)) {
        groupedMap[formattedDate] = [];
      }

      groupedMap[formattedDate]!.add(manga);
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
    return isEndOfList ? groupedMangaHistory.length : groupedMangaHistory.length + 1;
  }

  Widget _buildLoadingIndicator() {
    if (isError) {
      return Center(
        child: Text(
          'Riwayat Sudah Habis.',
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
                : groupedMangaHistory.isEmpty
                    ? Text('Tidak ditemukan riwayat manga.')
                    : NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (!isEndOfList &&
                              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                            currentPage++;
                            fetchMangaHistory();
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
                            final date = groupedMangaHistory.keys.elementAt(index);
                            final mangaList = groupedMangaHistory[date];

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
                                  itemCount: mangaList!.length,
                                  itemBuilder: (context, index) {
                                    final manga = mangaList[index];
                                    return MangaHistoryItem(manga: manga);
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
class MangaHistoryItem extends StatelessWidget {
  final dynamic manga;

  MangaHistoryItem({required this.manga});

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
      builder: (context) => MangaDetailPage(
        mangaUrl: manga['home_url'],  // Pastikan ini sesuai dengan properti yang diperlukan oleh MangaDetailPage
        telegramId: manga['telegram_id'], // Pastikan ini sesuai dengan properti yang diperlukan oleh MangaDetailPage
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
                child: CachedNetworkImage(
                  imageUrl: manga['image'],
                  fit: BoxFit.cover,
                  width: 100.0,
                  height: 120.0,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga['title'],
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Episode: ${manga['title_eps']}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Last Watched: ${manga['last_watched']}',
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

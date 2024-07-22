import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import './widget/anime-detail.dart';
import 'package:flue/color.dart';

class JadwalPage extends StatefulWidget {
  final String telegramId;

  JadwalPage({required this.telegramId});

  @override
  _JadwalPageState createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  Map<String, List<Map<String, dynamic>>> jadwal = {};
  int currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    for (int i = 0; i < 7; i++) {
      final day = _getDayName(i);
      await fetchData(day);
    }
  }

  Future<void> fetchData(String day) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://ccgnimex.my.id/v2/android/api_jadwalv2.php?hari=$day'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          jadwal[day.toUpperCase()] = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  String _getDayName(int index) {
    final List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return days[index % 7]; // Use modulo operator to cycle through days
  }

  int _getTodayIndex() {
    return DateTime.now().weekday % 7;
  }

  IconData _getIconForEpisodeStatus(int epsTerakhir, int latestEpisode) {
    return epsTerakhir == latestEpisode ? Icons.check : Icons.pending;
  }

  Color _getIconColorForEpisodeStatus(int epsTerakhir, int latestEpisode) {
    return epsTerakhir == latestEpisode ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = _getTodayIndex();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jadwal Anime',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ColorManager.currentBackgroundColor,
        iconTheme:
            IconThemeData(color: Colors.white), // Set the icon color to white
      ),
      drawer: Drawer(
        child: Container(
          color: ColorManager.currentBackgroundColor,
          child: ListView.builder(
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = _getDayName(index);
              return ListTile(
                title: Text(
                  day,
                  style: TextStyle(
                    fontWeight: index == todayIndex
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: index == todayIndex ? Colors.blue : Colors.white,
                  ),
                ),
                onTap: () {
                  setState(() {
                    currentIndex = index;
                    _pageController.jumpToPage(index);
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = _getDayName(index);
          final animeList = jadwal[day.toUpperCase()] ?? [];

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorManager.currentBackgroundColor.withOpacity(0.8),
                  ColorManager.currentBackgroundColor
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
                      final item = animeList[index];
                      final jam = item['jam'];
                      final judul = item['judul'];
                      final image = item['image'];
                      final animeId = item['anime_id'];
                      final epsTerakhir = item['eps_terakhir'];
                      final latestEpisode = item['latest_airing_episode'];
                      final eps_anilist = item['eps_anilist'];

                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          onTap: () {
                            final telegramId = widget.telegramId;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnimeDetailPage(
                                  animeId: int.parse(animeId),
                                  telegramId: telegramId,
                                ),
                              ),
                            );
                          },
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: image,
                              width: 70,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$jam',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$judul',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconForEpisodeStatus(
                                    epsTerakhir, latestEpisode),
                                color: _getIconColorForEpisodeStatus(
                                    epsTerakhir, latestEpisode),
                              ),
                              SizedBox(width: 8),
                              Text(
                                latestEpisode == 0
                                    ? 'Eps: $epsTerakhir/Tamat($eps_anilist)'
                                    : 'Eps: $epsTerakhir/$latestEpisode',
                                style: TextStyle(
                                  color: _getIconColorForEpisodeStatus(
                                      epsTerakhir, latestEpisode),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

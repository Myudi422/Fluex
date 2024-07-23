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
  late String selectedDay; // Use late initialization for selectedDay
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    final currentDayIndex = DateTime.now().weekday - 1;
    selectedDay = _getDayName(currentDayIndex);
    fetchData(selectedDay); // Initial fetch for the current day
  }

  Future<void> fetchData(String day) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://ccgnimex.my.id/v2/android/api_jadwalv2.php?hari=$day'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Check if the received day matches the current selected day
        if (day == selectedDay) {
          setState(() {
            jadwal[day.toUpperCase()] = List<Map<String, dynamic>>.from(data);
          });
        }
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

  IconData _getIconForEpisodeStatus(int epsTerakhir, int latestEpisode) {
    return epsTerakhir == latestEpisode ? Icons.check : Icons.pending;
  }

  Color _getIconColorForEpisodeStatus(int epsTerakhir, int latestEpisode) {
    return epsTerakhir == latestEpisode ? Colors.green : Colors.red;
  }

  void _changeSelectedDay(String newDay) {
    setState(() {
      selectedDay = newDay;
    });
    // Fetch data if it's not already fetched for the new selected day
    if (jadwal[newDay.toUpperCase()] == null) {
      fetchData(newDay);
    }
  }

  Future<void> _hapusJadwal(String animeId) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi"),
          content: Text("Apakah Anda yakin ingin menghapus jadwal ini?"),
          actions: <Widget>[
            TextButton(
              child: Text("Batal"),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false when canceled
              },
            ),
            TextButton(
              child: Text("Hapus"),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true when confirmed
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final response = await http.post(
          Uri.parse('https://ccgnimex.my.id/v2/android/jadwal_admin.php'),
          body: {
            'telegram_id': widget.telegramId,
            'anime_id': animeId,
          },
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['success']) {
            // Jika penghapusan berhasil, hapus item dari jadwal
            setState(() {
              jadwal[selectedDay.toUpperCase]
                  ?.removeWhere((item) => item['anime_id'] == animeId);
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(jsonResponse['message']),
              backgroundColor: Colors.green,
            ));
            // Refresh data setelah item dihapus
            refreshData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(jsonResponse['message']),
              backgroundColor: Colors.red,
            ));
          }
        } else {
          throw Exception('Failed to delete item');
        }
      } catch (e) {
        print('Error deleting item: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void refreshData() {
    fetchData(selectedDay); // Refresh data for the currently selected day
  }

  @override
  Widget build(BuildContext context) {
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
                    fontWeight: day == selectedDay
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: day == selectedDay
                        ? ColorManager.currentPrimaryColor
                        : Colors.white,
                  ),
                ),
                onTap: () {
                  _changeSelectedDay(day);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorManager.currentBackgroundColor,
              ColorManager.currentPrimaryColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: jadwal[selectedDay.toUpperCase()] == null ||
                jadwal[selectedDay.toUpperCase()]!.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: jadwal[selectedDay.toUpperCase()]!.length,
                itemBuilder: (context, index) {
                  final item = jadwal[selectedDay.toUpperCase()]![index];
                  final jam = item['jam'];
                  final judul = item['judul'];
                  final image = item['image'];
                  final animeId = item['anime_id'];
                  final epsTerakhir = item['eps_terakhir'];
                  final latestEpisode = item['latest_airing_episode'];
                  final eps_anilist = item['eps_anilist'];

                  return Dismissible(
                    key: Key(animeId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      color: Colors.red,
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _hapusJadwal(animeId);
                    },
                    child: Card(
                      color: ColorManager.currentBackgroundColor,
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
                            placeholder: (context, url) =>
                                Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$jam',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              '$judul',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white),
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
                    ),
                  );
                },
              ),
      ),
    );
  }
}

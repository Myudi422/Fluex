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
  String selectedDay = '';

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
        Uri.parse('https://ccgnimex.my.id/v2/android/api_jadwalv2.php?hari=$day'),
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
    final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Anime'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: ColorManager.currentPrimaryColor,
              child: Text(
                'Pilih Hari',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                  final hari = _getDayName(index);
                  return ListTile(
                    title: Text(hari),
                    selected: hari == selectedDay,
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      _changeSelectedDay(hari); // Change the selected day
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: jadwal[selectedDay.toUpperCase()] == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorManager.currentPrimaryColor, ColorManager.currentAccentColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView.builder(
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
          maxLines: 2, // Maksimum 1 baris untuk judul
          overflow: TextOverflow.ellipsis, // Tampilkan elipsis jika teks melebihi satu baris
        ),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIconForEpisodeStatus(epsTerakhir, latestEpisode),
          color: _getIconColorForEpisodeStatus(epsTerakhir, latestEpisode),
        ),
        SizedBox(width: 8), // Add spacing between icon and eps_terakhir
        Text(
          latestEpisode == 0
              ? 'Eps: $epsTerakhir/Tamat($eps_anilist)'
              : 'Eps: $epsTerakhir/$latestEpisode',
          style: TextStyle(
            color: _getIconColorForEpisodeStatus(epsTerakhir, latestEpisode),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
);
                },
              ),
            ),
    );
  }
}

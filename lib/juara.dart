import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>>? leaderboardData;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('https://ccgnimex.my.id/v2/android/leaderboard/api.php'));

    if (response.statusCode == 200) {
      List<dynamic> decodedData = json.decode(response.body);

      // Sorting data based on 'total_points' in descending order
      decodedData.sort((a, b) => (b['total_points'] ?? 0).compareTo(a['total_points'] ?? 0));

      setState(() {
        leaderboardData = List<Map<String, dynamic>>.from(decodedData);
      });
    } else {
      throw Exception('Failed to load leaderboard data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
      ),
      body: (leaderboardData != null && leaderboardData!.isNotEmpty)
          ? ListView.builder(
              itemCount: leaderboardData!.length,
              itemBuilder: (context, index) {
                final data = leaderboardData![index];
                final rank = index + 1;
                return LeaderboardItem(data: data, rank: rank);
              },
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class LeaderboardItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final int rank;

  LeaderboardItem({required this.data, required this.rank});

  @override
  Widget build(BuildContext context) {
    Widget trophyIcon;
    switch (rank) {
      case 1:
        trophyIcon = Icon(Icons.emoji_events, color: Colors.amber); // Piala Emas
        break;
      case 2:
        trophyIcon = Icon(Icons.emoji_events, color: Colors.grey); // Piala Perak
        break;
      case 3:
        trophyIcon = Icon(Icons.emoji_events, color: Colors.brown); // Piala Perunggu
        break;
      default:
        trophyIcon = Text('$rank', style: TextStyle(fontSize: 18)); // Nomor urut biasa
    }

    Color backgroundColor = rank % 2 == 0 ? Colors.grey[200]! : Colors.white; // Ganti warna latar setiap item

    return Container(
      color: backgroundColor,
      child: ListTile(
        leading: trophyIcon,
        title: Text(data['first_name'] ?? 'No Name'),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Points: ${data['total_points'] ?? '0'}'),
              ],
            ),
            CircleAvatar(
              backgroundImage: NetworkImage(data['profile_picture'] ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}

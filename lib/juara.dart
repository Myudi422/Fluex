import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flue/color.dart'; // Import ColorManager

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
    final response = await http.get(
        Uri.parse('https://ccgnimex.my.id/v2/android/leaderboard/api.php'));

    if (response.statusCode == 200) {
      List<dynamic> decodedData = json.decode(response.body);

      // Sorting data based on 'total_points' in descending order
      decodedData.sort(
          (a, b) => (b['total_points'] ?? 0).compareTo(a['total_points'] ?? 0));

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
        title: Text(
          'Leaderboard',
          style: TextStyle(color: ColorManager.currentHomeColor),
        ),
        backgroundColor: ColorManager.currentBackgroundColor,
        iconTheme: IconThemeData(color: ColorManager.currentHomeColor),
      ),
      backgroundColor: ColorManager.currentBackgroundColor,
      body: (leaderboardData != null && leaderboardData!.isNotEmpty)
          ? ListView.builder(
              itemCount: leaderboardData!.length,
              itemBuilder: (context, index) {
                final data = leaderboardData![index];
                final rank = index + 1;
                return LeaderboardItem(data: data, rank: rank);
              },
            )
          : Center(
              child: CircularProgressIndicator(
                color: ColorManager.currentHomeColor,
              ),
            ),
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
        trophyIcon =
            Icon(Icons.emoji_events, color: Colors.amber); // Piala Emas
        break;
      case 2:
        trophyIcon =
            Icon(Icons.emoji_events, color: Colors.grey); // Piala Perak
        break;
      case 3:
        trophyIcon =
            Icon(Icons.emoji_events, color: Colors.brown); // Piala Perunggu
        break;
      default:
        trophyIcon = Text('$rank',
            style: TextStyle(
                fontSize: 18,
                color: ColorManager.currentHomeColor)); // Nomor urut biasa
    }

    Color backgroundColor = rank % 2 == 0
        ? ColorManager.currentAccentColor.withOpacity(0.1)
        : ColorManager.currentBackgroundColor;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: trophyIcon,
        title: Text(
          data['first_name'] ?? 'No Name',
          style: TextStyle(
            color: ColorManager.currentHomeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Points: ${data['total_points'] ?? '0'}',
              style: TextStyle(
                  color: ColorManager.currentHomeColor.withOpacity(0.7)),
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

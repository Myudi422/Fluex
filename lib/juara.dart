import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flue/color.dart'; // Import ColorManager
import 'package:flue/widget/me.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import Font Awesome Flutter

class LeaderboardPage extends StatefulWidget {
  final String telegramId;

  const LeaderboardPage({super.key, required this.telegramId});

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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Informasi Peringkat'),
          content: Text(
              'Peringkat dihitung sebagai 1 XP per jam tonton dan 1 XP per 5 komentar. Contoh: Menonton anime selama 1 jam tanpa berkomentar akan menambah 1 level. Komentar sebanyak 5 kali juga akan menambah 1 level.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Peringkat User',
          style: TextStyle(color: ColorManager.currentHomeColor),
        ),
        backgroundColor: ColorManager.currentBackgroundColor,
        iconTheme: IconThemeData(color: ColorManager.currentHomeColor),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.infoCircle,
                color: ColorManager.currentHomeColor),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      backgroundColor: ColorManager.currentBackgroundColor,
      body: (leaderboardData != null && leaderboardData!.isNotEmpty)
          ? ListView.builder(
              itemCount: leaderboardData!.length,
              itemBuilder: (context, index) {
                final data = leaderboardData![index];
                final rank = index + 1;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          telegramId: data['telegram_id'] ?? '',
                          mytelegram: widget.telegramId,
                        ),
                      ),
                    );
                  },
                  child: LeaderboardItem(
                    data: data,
                    rank: rank,
                  ),
                );
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

  LeaderboardItem({
    required this.data,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    Widget trophyIcon;
    switch (rank) {
      case 1:
        trophyIcon =
            Icon(Icons.emoji_events, color: Colors.amber); // Gold Trophy
        break;
      case 2:
        trophyIcon =
            Icon(Icons.emoji_events, color: Colors.grey); // Silver Trophy
        break;
      case 3:
        trophyIcon =
            Icon(Icons.emoji_events, color: Colors.brown); // Bronze Trophy
        break;
      default:
        trophyIcon = Text('$rank',
            style: TextStyle(
                fontSize: 18,
                color: ColorManager.currentHomeColor)); // Regular rank number
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
              'Lv: ${data['total_points'] ?? '0'}',
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

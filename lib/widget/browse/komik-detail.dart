import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flue/color.dart'; // Import ColorManager
import 'package:flue/widget/browse/baca.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MangaDetailPage extends StatefulWidget {
  final String telegramId;
  final String mangaUrl;

  MangaDetailPage({required this.mangaUrl, required this.telegramId});

  @override
  _MangaDetailPageState createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  late Map<String, dynamic> mangaDetails = {};
  bool isLoading = true;
  List<bool> checkedEpisodes = [];

  @override
  void initState() {
    super.initState();
    _fetchMangaDetails();
  }

  Future<void> _fetchMangaDetails() async {
    try {
      final response = await http.get(Uri.parse(
          'https://ccgnimex.my.id/v2/android/komik/api_detail.php?url=${widget.mangaUrl}'));

      if (response.statusCode == 200) {
        setState(() {
          mangaDetails = json.decode(response.body);
          isLoading = false;
          checkedEpisodes =
              List.generate(mangaDetails['episodes'].length, (index) => false);
        });
        _loadCheckedEpisodes(); // Memuat status ceklis ketika widget diinisialisasi
      } else {
        throw Exception('Failed to load manga details');
      }
    } catch (error) {
      print(error.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCheckedEpisodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Memuat status ceklis untuk setiap episode
      checkedEpisodes = List.generate(
        mangaDetails['episodes'].length,
        (index) => prefs.getBool(_getEpisodeKey(index)) ?? false,
      );
    });
  }

  Future<void> _saveCheckedEpisode(int index, bool isChecked) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_getEpisodeKey(index), isChecked); // Menyimpan status ceklis
  }

  String _getEpisodeKey(int index) {
    return '${widget.telegramId}_${mangaDetails['title']}_episode_$index';
  }

  Future<void> _insertMangaHistory(int index) async {
    try {
      final response = await http.post(
        Uri.parse('https://ccgnimex.my.id/v2/android/komik/history.php'),
        body: {
          'image': mangaDetails['image'],
          'title': mangaDetails['title'],
          'episode_url': mangaDetails['episodes'][index]['url'],
          'title_eps': mangaDetails['episodes'][index]['title'],
          'telegram_id': widget.telegramId,
        },
      );

      if (response.statusCode == 200) {
        print('Manga history inserted successfully');
      } else {
        throw Exception('Failed to insert manga history');
      }
    } catch (error) {
      print(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          mangaDetails['title'] ?? 'Manga Detail',
          style: TextStyle(color: ColorManager.currentHomeColor),
        ),
        backgroundColor: ColorManager.currentBackgroundColor,
        iconTheme: IconThemeData(color: ColorManager.currentHomeColor),
      ),
      backgroundColor: ColorManager.currentBackgroundColor,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ColorManager.currentHomeColor,
              ),
            )
          : _buildMangaDetail(),
    );
  }

  String _getShortenedTitle(String title) {
    const int maxTitleLength = 20;
    return title.length <= maxTitleLength
        ? title
        : title.substring(0, maxTitleLength - 3) + '...';
  }

  Widget _buildMangaDetail() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: mangaDetails['image'],
            height: 200.0,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
          SizedBox(height: 16.0),
          Text(
            mangaDetails['title'] ?? 'Unknown Title',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: ColorManager.currentHomeColor,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'Genres: ${mangaDetails['genres'].join(', ')}',
            style:
                TextStyle(fontSize: 16.0, color: ColorManager.currentHomeColor),
          ),
          SizedBox(height: 8.0),
          Row(
            children: [
              Icon(FontAwesomeIcons.info,
                  size: 16.0, color: ColorManager.currentHomeColor),
              SizedBox(width: 8.0),
              Text(
                'Status: ${mangaDetails['status']}',
                style: TextStyle(
                    fontSize: 16.0, color: ColorManager.currentHomeColor),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          Row(
            children: [
              Icon(FontAwesomeIcons.star,
                  size: 16.0, color: ColorManager.currentHomeColor),
              SizedBox(width: 8.0),
              Text(
                'Rating: ${mangaDetails['rating']['percent']} (${mangaDetails['rating']['value']})',
                style: TextStyle(
                    fontSize: 16.0, color: ColorManager.currentHomeColor),
              ),
            ],
          ),
          SizedBox(height: 24.0),
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: ColorManager.currentAccentColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              'Description: ${mangaDetails['description']}',
              style: TextStyle(
                  fontSize: 16.0, color: ColorManager.currentHomeColor),
            ),
          ),
          SizedBox(height: 16.0),
          _buildEpisodeList(),
        ],
      ),
    );
  }

  Widget _buildEpisodeList() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorManager.currentAccentColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      height: 300.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Episodes:',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: ColorManager.currentHomeColor,
            ),
          ),
          SizedBox(height: 8.0),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => Divider(),
              itemCount: mangaDetails['episodes'].length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    mangaDetails['episodes'][index]['title'],
                    style: TextStyle(
                        fontSize: 16.0, color: ColorManager.currentHomeColor),
                  ),
                  onTap: () {
                    setState(() {
                      checkedEpisodes[index] = !checkedEpisodes[index];
                    });
                    _saveCheckedEpisode(index, checkedEpisodes[index]);
                    _insertMangaHistory(index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BacaPage(
                          episodeUrl: mangaDetails['episodes'][index]['url'],
                        ),
                      ),
                    );
                  },
                  trailing: Checkbox(
                    value: checkedEpisodes[index],
                    onChanged: (bool? value) {
                      setState(() {
                        checkedEpisodes[index] = value ?? false;
                      });
                      _saveCheckedEpisode(index, checkedEpisodes[index]);
                    },
                    checkColor: ColorManager.currentBackgroundColor,
                    activeColor: ColorManager.currentHomeColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

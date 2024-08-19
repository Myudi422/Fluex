import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flue/color.dart';

// Model Playlist
class Playlist {
  final String name;
  final List<String> videoLinks;

  Playlist({required this.name, required this.videoLinks});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'],
      videoLinks: List<String>.from(json['video_links']),
    );
  }
}

// PlaylistTab
class PlaylistTab extends StatefulWidget {
  final String telegramId;
  final String mytelegram;

  const PlaylistTab({
    super.key,
    required this.telegramId,
    required this.mytelegram,
  });

  @override
  _PlaylistTabState createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {
  late Future<List<Playlist>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = _loadPlaylists();
  }

  Future<List<Playlist>> _loadPlaylists() async {
    try {
      final response = await http.get(Uri.parse(
          'https://ccgnimex.my.id/v2/android/music/my.php?telegram_id=${widget.telegramId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['playlists'] as List)
              .map((playlistJson) => Playlist.fromJson(playlistJson))
              .toList();
        } else {
          throw Exception('Failed to load playlists: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to load playlists. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading playlists: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.currentBackgroundColor,
      body: FutureBuilder<List<Playlist>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No playlists available.',
                    style: TextStyle(color: Colors.white)));
          } else {
            final playlists = snapshot.data!;
            return ListView(
              padding: EdgeInsets.all(16.0),
              children: playlists.map((playlist) {
                return ExpansionTile(
                  title: Text(playlist.name,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  subtitle: Text('${playlist.videoLinks.length} videos',
                      style: TextStyle(color: Colors.grey[400])),
                  tilePadding: EdgeInsets.symmetric(vertical: 8.0),
                  backgroundColor: const Color.fromARGB(255, 15, 15, 15)!,
                  children: playlist.videoLinks.map((link) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                      leading: FaIcon(
                        FontAwesomeIcons.video,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      title: Text('Video Title',
                          style: TextStyle(color: Colors.white)),
                      subtitle: Text('Video Description',
                          style: TextStyle(color: Colors.grey[300])),
                      onTap: () {
                        // Handle video link tap
                        _launchURL(link); // Implement this method
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }

  void _launchURL(String url) async {
    // Implement URL launch functionality here
  }
}

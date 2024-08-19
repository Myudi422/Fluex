import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flue/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile/history_tab.dart';
import 'profile/koleksi_tab.dart';
import 'profile/playlist_tab.dart';

class ProfilePage extends StatefulWidget {
  final String telegramId;
  final String mytelegram;

  ProfilePage({required this.telegramId, required this.mytelegram});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _profileData;
  String bannerUrl = ''; // Start with an empty string

  @override
  void initState() {
    super.initState();
    _profileData = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://ccgnimex.my.id/v2/android/me.php?telegram_id=${widget.telegramId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Update the bannerUrl with the URL from the response
        setState(() {
          bannerUrl = data['banner_picture'] ??
              ''; // Use an empty string if 'banner_picture' is null
        });
        return data;
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (error) {
      throw Exception('Error during data fetch: $error');
    }
  }

  Future<void> _uploadBannerUrl(String newBannerUrl) async {
    try {
      final response = await http.post(
        Uri.parse('https://ccgnimex.my.id/v2/android/update_banner.php'),
        body: {
          'telegram_id': widget.telegramId,
          'banner_url': newBannerUrl,
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success']) {
          setState(() {
            bannerUrl = newBannerUrl;
          });
        } else {
          throw Exception(
              'Failed to update banner: ${responseBody['message']}');
        }
      } else {
        throw Exception('Failed to connect to server');
      }
    } catch (error) {
      print('Error uploading banner URL: $error');
    }
  }

  Future<void> _showBannerInputDialog() async {
    String newBannerUrl = bannerUrl;
    final TextEditingController urlController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ganti Banner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  hintText: 'Masukkan URL banner baru',
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Ganti banner hanya menggunakan URL yang berakhiran dengan ekstensi seperti .jpg, .png, .gif, dll, contoh "https://website.mu/gambar.jpg". '
                'Kamu bisa mencari gambar di Pinterest atau mengunggah gambar sendiri di situs seperti Imgbb atau sejenisnya dan salin linknya kesini.',
                style: TextStyle(fontSize: 12.0, color: Colors.grey),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Simpan'),
              onPressed: () {
                newBannerUrl = urlController.text.trim();
                if (newBannerUrl.isNotEmpty) {
                  _uploadBannerUrl(newBannerUrl);
                }
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
          'Profil User',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ColorManager.currentBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No data found',
                    style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;
          final xpForNextLevel = data['xp_for_next_level'] ?? 0;
          final currentXp = data['current_xp'] ?? 0;
          final xpProgress = (currentXp / xpForNextLevel).clamp(0.0, 1.0);

          return DefaultTabController(
            length: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50.0),
                              child: CachedNetworkImage(
                                imageUrl: data['profile_picture'] ?? '',
                                width: 80.0,
                                height: 80.0,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['first_name'] ?? 'Unknown User',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              data['akses'] ?? 'Free',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (data['akses'] == 'Premium')
                                              SizedBox(width: 4),
                                            if (data['akses'] == 'Premium')
                                              Icon(
                                                Icons.verified,
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        'Level ${data['level'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: xpProgress,
                                    backgroundColor: Colors.grey[700],
                                    color: Colors.blue,
                                    minHeight: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                'Menonton',
                                data['ditonton'] ?? '0:00:00',
                                FontAwesomeIcons.clockRotateLeft,
                                Colors.blue,
                              ),
                              _buildStatCard(
                                'Favorit',
                                data['favorite_anime']?.toString() ?? '0',
                                FontAwesomeIcons.star,
                                Colors.red,
                              ),
                              _buildStatCard(
                                'Komentar',
                                data['comment']?.toString() ?? '0',
                                FontAwesomeIcons.commentDots,
                                Colors.green,
                              ),
                              _buildStatCard(
                                'Peringkat',
                                '#${data['peringkat']?.toString() ?? 'N/A'}',
                                FontAwesomeIcons.trophy,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      Image.network(
                        bannerUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey[300],
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey[300],
                            child: Center(child: Icon(Icons.error)),
                          );
                        },
                      ),
                      if (widget.mytelegram ==
                          widget.telegramId) // Pengecekan ID
                        Positioned(
                          right: 16,
                          top: 16,
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Colors.white),
                            onPressed: _showBannerInputDialog,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ColorManager.currentBackgroundColor,
                          spreadRadius: 5,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(text: 'History'),
                        Tab(text: 'Koleksi'),
                        Tab(text: 'Playlist'),
                      ],
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: TabBarView(
                      children: [
                        HistoryTab(
                            telegramId: widget.telegramId,
                            mytelegram:
                                widget.mytelegram), // Use the HistoryTab widget
                        KoleksiTab(
                            telegramId: widget.telegramId,
                            mytelegram:
                                widget.mytelegram), // Use the KoleksiTab widget
                        PlaylistTab(
                            telegramId: widget.telegramId,
                            mytelegram: widget
                                .mytelegram), // Use the PlaylistTab widget
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'streaming/streaming.dart';
import './streaming/core/convertdurasi.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EpisodeWidget extends StatefulWidget {
  final int animeId;
  final String telegramId;
  final Map<String, dynamic> animeData;

  EpisodeWidget({
    required this.animeId,
    required this.telegramId,
    required this.animeData,
  });

  @override
  _EpisodeWidgetState createState() => _EpisodeWidgetState();
}

class _EpisodeWidgetState extends State<EpisodeWidget> {
  List<dynamic> episodes = [];
  bool isLoading = true;
  bool isAscending = true;
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  List<dynamic> filteredEpisodes = [];
  bool showThumbnails = false;

  @override
  void initState() {
    super.initState();
    fetchEpisodes();
  }

  Future<dynamic> fetchEpisodesFromAPI(String apiUrl) async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch episodes: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<void> fetchEpisodes() async {
    try {
      final response = await fetchEpisodesFromAPI(
        'https://ccgnimex.my.id/v2/android/api_episode.php?anime_id=${widget.animeId}&telegram_id=${widget.telegramId}',
      );

      setState(() {
        episodes = response.map((episode) {
          episode['episode_number'] = int.parse(episode['episode_number']);
          return episode;
        }).toList();

        isLoading = false;

        episodes.sort((a, b) {
          int episodeA = a['episode_number'];
          int episodeB = b['episode_number'];
          return isAscending
              ? episodeA.compareTo(episodeB)
              : episodeB.compareTo(episodeA);
        });
      });
    } catch (error) {
      print('Error: $error');
    }
  }

  void toggleSortOrder() {
    setState(() {
      isAscending = !isAscending;
      episodes.sort((a, b) {
        int episodeA = a['episode_number'];
        int episodeB = b['episode_number'];
        return isAscending
            ? episodeA.compareTo(episodeB)
            : episodeB.compareTo(episodeA);
      });
    });
  }

  void _onSearchChanged() {
    setState(() {
      isSearching = searchController.text.isNotEmpty;

      // Filter episodes based on search
      filteredEpisodes = episodes.where((episode) {
        return episode['episode_number']
            .toString()
            .contains(searchController.text.toLowerCase());
      }).toList();
    });
  }

  void _navigateToStreaming(int episodeNumber, String? videoTime) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamingWidget(
          episodeNumber: episodeNumber,
          episodes: episodes,
          animeId: widget.animeId,
          telegramId: widget.telegramId,
          videoTime: videoTime ?? '',
          animeData: widget.animeData,
        ),
      ),
    );

    // Refresh data episode setelah kembali dari StreamingWidget
    fetchEpisodes();
  }

  @override
  Widget build(BuildContext context) {
    final String jumlahEpisodeText =
        '${isSearching ? filteredEpisodes.length : episodes.length} Episode';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                jumlahEpisodeText,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD9DADE),
                ),
              ),
            ),
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.all(8.0),
                  onPressed: toggleSortOrder,
                  child: Icon(
                    isAscending
                        ? CupertinoIcons.arrow_up
                        : CupertinoIcons.arrow_down,
                    size: 20.0,
                  ),
                ),
                Switch(
                  value: showThumbnails,
                  onChanged: (value) {
                    setState(() {
                      showThumbnails = value;
                    });
                  },
                  activeColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
        // Pencarian Episode
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              _onSearchChanged();
            },
            style: TextStyle(
                color: Colors.white), // Tambahkan ini untuk mengubah warna teks
            decoration: InputDecoration(
              hintText: 'Cari episode...',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(
                      0.5)), // Tambahkan ini untuk mengubah warna teks petunjuk
              prefixIcon: Icon(Icons.search,
                  color: Colors
                      .white), // Tambahkan ini untuk mengubah warna ikon pencarian
              suffixIcon: isSearching
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          color: Colors
                              .white), // Tambahkan ini untuk mengubah warna ikon hapus
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          _onSearchChanged();
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        Visibility(
          visible: isLoading,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        Visibility(
          visible: !isLoading && episodes.isNotEmpty,
          child: Padding(
            padding: EdgeInsets.all(4.0),
            child: RefreshIndicator(
              onRefresh: fetchEpisodes,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: showThumbnails ? 3 : 1,
                    crossAxisSpacing: 1.0,
                    mainAxisSpacing: 1.0,
                    childAspectRatio: showThumbnails ? 0.7 : 6.0,
                  ),
                  itemCount:
                      isSearching ? filteredEpisodes.length : episodes.length,
                  itemBuilder: (context, index) =>
                      _buildEpisodeItem(context, index, isSearching),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeItem(BuildContext context, int index, bool isSearching) {
    final episode = isSearching ? filteredEpisodes[index] : episodes[index];
    final String defaultImageUrlWithoutVideoTime =
        'https://subjective-tobye-myudi422.koyeb.app/19540';
    final String defaultImageUrlWithVideoTime =
        'https://subjective-tobye-myudi422.koyeb.app/19541';

    // Determine the URL to be used based on the conditions
    String imageUrl = episode['link_gambar'] ??
        ''; // Assuming 'link_gambar' is the image URL property

    if (imageUrl.isEmpty) {
      // If there is no image
      if (episode['video_time'] != null) {
        // If there is video time, use the GIF with video time
        imageUrl = defaultImageUrlWithVideoTime;
      } else {
        // If there is no video time, use the default GIF without video time
        imageUrl = defaultImageUrlWithoutVideoTime;
      }
    }

    return GestureDetector(
      onTap: () {
        _navigateToStreaming(
          episode['episode_number'],
          episode['video_time'],
        );
      },
      child: showThumbnails
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              imageBuilder: (context, imageProvider) => Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Episode ${episode['episode_number']}',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            // Video Time
                            if (episode['video_time'] != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.clock,
                                      size: 12.0,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4.0),
                                    Text(
                                      convertDuration(episode['video_time']),
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              progressIndicatorBuilder: (context, url, progress) => Container(),
              errorWidget: (context, url, error) => CachedNetworkImage(
                imageUrl: defaultImageUrlWithoutVideoTime,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(),
              ),
            )
          : ListTile(
              title: Text(
                'Episode ${episode['episode_number']}',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
              subtitle: episode['video_time'] != null
                  ? Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 12.0,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.0),
                        Text(
                          convertDuration(episode['video_time']),
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : null,
              onTap: () {
                _navigateToStreaming(
                  episode['episode_number'],
                  episode['video_time'],
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    searchController.dispose(); // Pastikan untuk dispose controller
    super.dispose();
  }
}

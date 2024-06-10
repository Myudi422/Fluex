import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class CuplikanWidget extends StatefulWidget {
  final Map<String, dynamic> animeData;
  final int animeId;

  CuplikanWidget({required this.animeData, required this.animeId});

  @override
  _CuplikanWidgetState createState() => _CuplikanWidgetState();
}

class _CuplikanWidgetState extends State<CuplikanWidget> {
  List<String> videoUrls = [];

  @override
  void initState() {
    super.initState();
    // Fetch YouTube video URLs based on anime title
    fetchYouTubeVideos();
  }

  Future<void> fetchYouTubeVideos() async {
    final String apiBaseUrl = 'https://ccgnimex.my.id/v2/android/api_yt.php/';
    final String videoTitle = widget.animeData['title']['romaji'];

    try {
      final response =
          await http.get(Uri.parse('$apiBaseUrl?video_title=$videoTitle'));
      if (response.statusCode == 200) {
        final List<String> urls = response.body.split('\n');
        setState(() {
          videoUrls = urls;
        });
      } else {
        print('Failed to fetch YouTube videos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during HTTP request: $e');
    }
  }

  String _extractVideoId(String url) {
    final Uri uri = Uri.parse(url);
    return uri.queryParameters['v'] ?? '';
  }

  String getThumbnail({
    required String videoId,
    String quality = ThumbnailQuality.standard,
  }) =>
      'https://i3.ytimg.com/vi/$videoId/$quality.jpg';

  String _extractThumbnail(String videoUrl) {
    final String videoId = _extractVideoId(videoUrl);

    if (videoId.isEmpty) {
      print('Invalid video URL: $videoUrl');
      return '';
    }

    final thumbnailUrl = getThumbnail(videoId: videoId);
    print('Thumbnail URL: $thumbnailUrl');
    return thumbnailUrl;
  }

  Future<void> _onRefresh() async {
    // Implement the logic to refresh the data here
    await fetchYouTubeVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: videoUrls.where((url) => url.isNotEmpty).length,
              itemBuilder: (context, index) {
                final videoUrl = videoUrls[index];
                final thumbnailUrl = _extractThumbnail(videoUrl);

                final YoutubePlayerController _controller =
                    YoutubePlayerController(
                  initialVideoId: _extractVideoId(videoUrl),
                  params: YoutubePlayerParams(
                    startAt: Duration(seconds: 0),
                    showFullscreenButton: true,
                  ),
                );

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return YoutubePlayerIFrame(
                          controller: _controller,
                        );
                      },
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

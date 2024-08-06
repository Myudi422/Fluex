import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:translator/translator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewBerita extends StatefulWidget {
  final String link;
  final String translated_title;
  final String imageUrl;

  ViewBerita({
    required this.link,
    required this.translated_title,
    required this.imageUrl, // Add this parameter
  });

  @override
  _ViewBeritaState createState() => _ViewBeritaState();
}

class _ViewBeritaState extends State<ViewBerita> {
  String beritaContent = "Loading...";
  bool isLoading = true;
  Set<String> youtubeLinks = {}; // Use Set to store unique links
  List<YoutubePlayerController> youtubeControllers = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(widget.link));
      if (response.statusCode == 200) {
        String content = response.body;

        // Extract YouTube links before translation
        extractYouTubeLinks(content);

        // Remove YouTube links from content for translation
        for (final link in youtubeLinks) {
          content = content.replaceAll(link, '[YouTubeLink]');
        }

        // Translate the content to Indonesian
        final translator = GoogleTranslator();
        final translation = await translator.translate(content, to: 'id');

        String translatedContent = translation.text;

        // Re-insert YouTube links back into the translated content
        int linkIndex = 0;
        translatedContent = translatedContent.replaceAllMapped(
          '[YouTubeLink]',
          (match) => youtubeLinks.elementAt(linkIndex++),
        );

        setState(() {
          beritaContent = translatedContent;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        beritaContent = "Error loading content";
        isLoading = false;
      });
    }
  }

  void extractYouTubeLinks(String content) {
    // Clear previous links
    youtubeLinks.clear();
    youtubeControllers.clear();

    // Extract YouTube links from content
    final RegExp regExp =
        RegExp(r'https://www.youtube.com/embed/([a-zA-Z0-9_-]+)');
    final matches = regExp.allMatches(content);

    for (final match in matches) {
      String link = match.group(0)!;
      print("Found YouTube Link: $link");
      youtubeLinks.add(link);

      // Initialize the YoutubePlayerController for each link
      final controller = YoutubePlayerController(
        initialVideoId: YoutubePlayerController.convertUrlToId(link) ?? '',
        params: YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          autoPlay: false, // Set autoPlay to false to prevent autoplay
        ),
      );
      youtubeControllers.add(controller);
    }

    // Refresh the UI after extracting YouTube links
    setState(() {});
  }

  @override
  void dispose() {
    // Dispose of each YoutubePlayerController to release resources
    for (final controller in youtubeControllers) {
      controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(
                  left: 16.0, bottom: 16.0), // Align to left with padding
              title: Text(
                widget.translated_title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
                overflow: TextOverflow.ellipsis, // Add ellipsis for long titles
                maxLines: 1, // Ensure the title does not wrap to multiple lines
              ),
              background: Stack(
                children: [
                  widget.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.cover,
                          height: 250.0,
                          width: double.infinity,
                        )
                      : Container(
                          height: 250.0,
                          color: Colors.grey,
                        ),
                  Container(
                    height: 250.0,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display YouTube player for each link
                  for (int i = 0; i < youtubeLinks.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: YoutubePlayerIFrame(
                        controller: youtubeControllers[i],
                      ),
                    ),
                  // Use CircularProgressIndicator while data is loading
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Html(
                          data: beritaContent,
                          style: {
                            "body": Style(
                              backgroundColor: Colors.black, // Background color
                              color: Colors.white, // Text color
                            ),
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black, // Change scaffold background color
    );
  }
}

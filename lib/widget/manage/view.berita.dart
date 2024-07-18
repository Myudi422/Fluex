import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:translator/translator.dart'; // Import the translator package

class ViewBerita extends StatefulWidget {
  final String link;
  final String translated_title;

  ViewBerita({required this.link, required this.translated_title});

  @override
  _ViewBeritaState createState() => _ViewBeritaState();
}

class _ViewBeritaState extends State<ViewBerita> {
  String beritaContent = "Loading...";
  bool isLoading = true;
  Set<String> youtubeLinks = {}; // Use Set to store unique links

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
        });

        // Set loading to false after data is loaded
        setState(() {
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

    // Extract YouTube links from content
    final RegExp regExp =
        RegExp(r'https://www.youtube.com/embed/([a-zA-Z0-9_-]+)');
    final matches = regExp.allMatches(content);

    for (final match in matches) {
      String link = match.group(0)!;
      print("Found YouTube Link: $link");
      youtubeLinks.add(link);
    }

    // Refresh the UI after extracting YouTube links
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.translated_title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display YouTube player for each link
            for (final youtubeLink in youtubeLinks)
              YoutubePlayerIFrame(
                controller: YoutubePlayerController(
                  initialVideoId:
                      YoutubePlayerController.convertUrlToId(youtubeLink) ?? '',
                  params: YoutubePlayerParams(
                    showControls: true,
                    showFullscreenButton: true,
                    autoPlay:
                        false, // Set autoPlay to false to prevent autoplay
                  ),
                ),
              ),

            // Use CircularProgressIndicator while data is loading
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Html(data: beritaContent),
          ],
        ),
      ),
    );
  }
}

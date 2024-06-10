import 'package:fijkplayer_update/fijkplayer.dart';
import 'package:flutter/material.dart';

class StreamingWidget extends StatefulWidget {
  final String videoUrl;
  final int episodeNumber;
  final List<dynamic> episodes;
  final String videoTime;
  final String telegramId;
  final int animeId;
  final Map<String, dynamic> animeData;

  StreamingWidget({
    required this.videoUrl,
    required this.episodeNumber,
    required this.episodes,
    required this.videoTime,
    required this.telegramId,
    required this.animeId,
    required this.animeData,
  });

  @override
  _StreamingWidgetState createState() => _StreamingWidgetState();
}

class _StreamingWidgetState extends State<StreamingWidget> {
  final FijkPlayer player = FijkPlayer();

  _StreamingWidgetState();

  @override
  void initState() {
    super.initState();
    player.setDataSource(widget.videoUrl, autoPlay: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fijkplayer Example")),
      body: Stack(
        children: [
          // Place your other UI elements below
          Positioned(
            top: 100, // Adjust the top position as needed
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              // Your other UI elements (titles, list episodes, comments) go here
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Your UI elements go here
                  Text("Title"),
                  Text("List Episode"),
                  Text("Comments"),
                  // Add more UI elements as needed
                ],
              ),
            ),
          ),
          // Place the video player above other UI elements
          Positioned.fill(
            child: FijkView(
              player: player,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}

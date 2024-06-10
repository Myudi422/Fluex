// main_streaming.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
//import 'package:wakelock/wakelock.dart';
import 'core/convertdurasi.dart';
import 'core/episode_list.dart';
import 'core/riwayathistory.dart';
import 'core/video_player.dart'; // Import the VideoPlayerWidget

class StreamingWidget extends StatefulWidget {
  final String videoUrl;
  final int episodeNumber;
  final List<dynamic> episodes;
  final String videoTime;

  StreamingWidget({
    required this.videoUrl,
    required this.episodeNumber,
    required this.episodes,
    required this.videoTime,
  });

  @override
  _StreamingWidgetState createState() => _StreamingWidgetState();
}

class _StreamingWidgetState extends State<StreamingWidget>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  bool _isFullScreen = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
    _initializeVideoPlayer();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    Wakelock.disable();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _videoPlayerController.play();
    } else {
      _videoPlayerController.pause();
    }
  }

  void _initializeVideoPlayer() {
    int selectedIndex = widget.episodes.indexWhere(
      (episode) => episode['episode_number'] == widget.episodeNumber,
    );

    _videoPlayerController = VideoPlayerController.network(
      widget.episodes[selectedIndex]['video_url'],
    )..initialize().then((_) {
        setState(() {});
      });

    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.isPlaying) {
        setState(() {
          _isPlaying = true;
        });
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
      setState(() {}); // Trigger a rebuild on every frame
    });
  }

  Widget _buildVideoPlayer() {
    return VideoPlayerWidget(
      videoPlayerController: _videoPlayerController,
      isFullScreen: _isFullScreen,
      toggleFullScreen: _toggleFullScreen,
    );
  }

  Widget _buildProgressBar() {
    return VideoProgressIndicator(
      _videoPlayerController,
      allowScrubbing: true,
      colors: VideoProgressColors(
        playedColor: Colors.blue,
        bufferedColor: Colors.grey,
        backgroundColor: Colors.black,
      ),
    );
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _navigateToSelectedEpisode(
      String videoUrl, int episodeNumber, String? videoTime) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StreamingWidget(
          videoUrl: videoUrl,
          episodeNumber: episodeNumber,
          episodes: widget.episodes,
          videoTime: videoTime ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      _isFullScreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );

    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false; // Do not exit the screen
        }
        return true; // Allow normal back button behavior
      },
      child: Scaffold(
        body: Column(
          children: [
            _buildVideoPlayer(),
            SizedBox(
              height: 16.0,
            ), // Add spacing between video player and episodes
            EpisodeListWidget(
              episodes: widget.episodes,
              currentEpisodeNumber: widget.episodeNumber,
              onEpisodeSelected: (episodeNumber) {
                if (episodeNumber != widget.episodeNumber) {
                  _navigateToSelectedEpisode(
                    widget.episodes[episodeNumber - 1]['video_url'],
                    episodeNumber,
                    widget.episodes[episodeNumber - 1]['video_time'],
                  );
                }
              },
            ),
            SizedBox(height: 16.0), // Add spacing between episodes and history
            RiwayatDurasiWidget(
              videoTime: widget.videoTime,
              videoPlayerController: _videoPlayerController,
            ),
          ],
        ),
      ),
    );
  }
}

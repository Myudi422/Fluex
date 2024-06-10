import 'package:flutter/material.dart';
import 'package:modern_player/modern_player.dart';

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
  bool isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isFullScreen
          ? _buildFullScreenLayout()
          : _buildDefaultLayout(),
    );
  }

  Widget _buildDefaultLayout() {
    return Column(
      children: [
        Container(
          height: 250,
          child: ModernPlayer.createPlayer(
            qualityOptions: [
              ModernPlayerQualityOptions(
                name: "Episode ${widget.episodeNumber}",
                url: widget.videoUrl,
              ),
            ],
            sourceType: ModernPlayerSourceType.network,
            subtitles: [],
            audioTracks: [],
            themeOptions: _getThemeOptions(),
            controlsOptions: _getControlsOptions(),
          ),
        ),
        if (widget.videoTime != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Duration: ${widget.videoTime}',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
          ),
        GestureDetector(
          onTap: () {
            setState(() {
              isFullScreen = true;
            });
          },
          child: Container(
            height: kToolbarHeight,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenLayout() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          child: ModernPlayer.createPlayer(
            qualityOptions: [
              ModernPlayerQualityOptions(
                name: "Episode ${widget.episodeNumber}",
                url: widget.videoUrl,
              ),
            ],
            sourceType: ModernPlayerSourceType.network,
            subtitles: [],
            audioTracks: [],
            themeOptions: _getThemeOptions(),
            controlsOptions: _getControlsOptions(),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                isFullScreen = false;
              });
            },
            child: Container(
              padding: EdgeInsets.all(16),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ModernPlayerThemeOptions _getThemeOptions() {
    return ModernPlayerThemeOptions(
      backgroundColor: Colors.black,
      menuBackgroundColor: Colors.black,
      loadingColor: Colors.blue,
      menuIcon: const Icon(
        Icons.settings,
        color: Colors.white,
      ),
      volumeSlidertheme: ModernPlayerToastSliderThemeOption(
        sliderColor: Colors.blue,
        iconColor: Colors.white,
      ),
      progressSliderTheme: ModernPlayerProgressSliderTheme(
        activeSliderColor: Colors.blue,
        inactiveSliderColor: Colors.white70,
        bufferSliderColor: Colors.black54,
        thumbColor: Colors.white,
        progressTextStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  ModernPlayerControlsOptions _getControlsOptions() {
    return ModernPlayerControlsOptions(
      showControls: true,
      doubleTapToSeek: true,
      showMenu: true,
      showMute: false,
      showBackbutton: false,
      enableVolumeSlider: true,
      enableBrightnessSlider: true,
      showBottomBar: true,
      customActionButtons: [
        ModernPlayerCustomActionButton(
          icon: const Icon(
            Icons.info_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            // On Pressed
          },
        ),
      ],
    );
  }
}

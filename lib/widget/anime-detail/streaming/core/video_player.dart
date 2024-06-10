import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:floating/floating.dart'; // Import floating package


class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final bool isFullScreen;
  final Function toggleFullScreen;

  VideoPlayerWidget({
    required this.videoPlayerController,
    required this.isFullScreen,
    required this.toggleFullScreen,
  });

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isVisible = true;
  late Timer _timer;
  bool _isFullScreenLocked = false;
  bool _controlsVisible = true; // Added variable to track control visibility
  bool _isOriginalAspectRatio = true;
  late final Floating _floating = Floating(); // Initialize Floating instance

  @override
  void initState() {
    super.initState();
    widget.videoPlayerController.addListener(_onVideoControllerUpdate);
    _startTimer();
  }

  void _onVideoControllerUpdate() {
    if (widget.videoPlayerController.value.isPlaying) {
      _hideControls();
    } else {
      _showControls();
    }
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer(Duration(seconds: 5), _hideControls);
  }

  void _stopTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }
  }

  void _hideControls() {
    setState(() {
      _isVisible = false;
    });
  }

  void _showControls() {
    setState(() {
      _isVisible = true;
    });
    _startTimer();
  }

  void _skipVideo(bool isForward) {
    setState(() {
      _controlsVisible = true; // Show controls when skip buttons are clicked
    });

    Duration newPosition;
    if (widget.videoPlayerController.value.isPlaying) {
      newPosition = isForward
          ? widget.videoPlayerController.value.position + Duration(seconds: 10)
          : widget.videoPlayerController.value.position - Duration(seconds: 10);
    } else {
      newPosition = isForward
          ? widget.videoPlayerController.value.position + Duration(seconds: 10)
          : widget.videoPlayerController.value.position - Duration(seconds: 10);
    }

    widget.videoPlayerController.seekTo(newPosition);
    _startTimer();
  }

  void _onTap() {
    if (!_isFullScreenLocked) {
      // Toggle visibility of the play/pause button
      setState(() {
        _isVisible = !_isVisible;
        _controlsVisible = true; // Show controls when play/pause button is pressed
      });

      // Stop timer if running
      _stopTimer();

      // Play or pause video depending on current status
      _playPause();
    }
  }

  void _playPause() {
    if (widget.videoPlayerController.value.isPlaying) {
      widget.videoPlayerController.pause();
    } else {
      widget.videoPlayerController.play();
    }
  }

  void _toggleFullScreenLock() {
    setState(() {
      _isFullScreenLocked = !_isFullScreenLocked;
    });
  }

  void _toggleAspectRatio() {
    setState(() {
      _isOriginalAspectRatio = !_isOriginalAspectRatio;
    });
  }

Future<void> _enablePiP() async {
  // Check if the video is in fullscreen mode before enabling PiP
  if (widget.isFullScreen) {
    // Hide controls when entering PiP mode
    setState(() {
      _controlsVisible = false;
    });

    final status = await _floating.enable();
    print('PiP enabled? $status');

    // Hide play/pause button and lock icon when entering PiP mode
    setState(() {
      _isVisible = false;
      _isFullScreenLocked = true;
    });
  }
}

  Widget _buildPlayPauseButton() {
    IconData iconData =
        widget.videoPlayerController.value.isPlaying ? Icons.pause : Icons.play_arrow;
    return _isFullScreenLocked
        ? Container()
        : AnimatedContainer(
            duration: Duration(milliseconds: 500),
            height: _isVisible ? 60.0 : 0.0,
            width: _isVisible ? 60.0 : 0.0,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Center(
              child: IconButton(
                icon: Icon(
                  iconData,
                  size: 40,
                  color: Colors.white,
                ),
                onPressed: _playPause,
              ),
            ),
          );
  }

  Widget _buildControllerBarOverlay() {
    Duration position = widget.videoPlayerController.value.position;
    Duration duration = widget.videoPlayerController.value.duration;

    String currentTime =
        "${position.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(position.inSeconds.remainder(60)).toString().padLeft(2, '0')}";
    String totalTime =
        "${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(duration.inSeconds.remainder(60)).toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () {
        // Do nothing when overlay is tapped to prevent hiding controls
      },
      child: Container(
        color: Colors.black.withOpacity(0.3), // Semi-transparent black overlay
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.replay_10, color: Colors.white),
              onPressed: () => _skipVideo(false),
            ),
            IconButton(
              icon: Icon(Icons.forward_10, color: Colors.white),
              onPressed: () => _skipVideo(true),
            ),
            Expanded(child: Container()), // Spacer
            Text(
              "$currentTime / $totalTime",
              style: TextStyle(color: Colors.white),
            ),
Opacity(
            opacity: MediaQuery.of(context).orientation == Orientation.landscape ? 1.0 : 0.0,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isOriginalAspectRatio ? Icons.aspect_ratio : Icons.aspect_ratio_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _toggleAspectRatio,
                ),
                IconButton(
                  icon: Icon(Icons.picture_in_picture, color: Colors.white),
                  onPressed: () {
                    _enablePiP();
                  },
                ),
              ],
            ),
          ),
            IconButton(
              icon: Icon(Icons.fullscreen, color: Colors.white),
              onPressed: () {
                widget.toggleFullScreen();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return VideoProgressIndicator(
      widget.videoPlayerController,
      allowScrubbing: true,
      colors: VideoProgressColors(
        playedColor: Colors.red,
        bufferedColor: Colors.grey,
        backgroundColor: Colors.black,
      ),
    );
  }

Widget build(BuildContext context) {
  return GestureDetector(
    onTap: _onTap,
    child: Center(
      child: OrientationBuilder(
        builder: (context, orientation) {
          return widget.videoPlayerController.value.isInitialized
              ? Stack(
                  children: [
                    Container(
                      alignment: Alignment.center,
                        child: AspectRatio(
                          aspectRatio: _isOriginalAspectRatio
                              ? widget.videoPlayerController.value.aspectRatio
                              : orientation == Orientation.landscape
                                  ? MediaQuery.of(context).size.aspectRatio
                                  : widget.videoPlayerController.value.aspectRatio,
                          child: VideoPlayer(widget.videoPlayerController),
                        ),
                      ),
                    if (!_isFullScreenLocked) ...[
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildPlayPauseButton(),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          opacity: _controlsVisible ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 600),
                          child: Column(
                            children: [
                              _buildControllerBarOverlay(),
                              _buildProgressBar(),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        icon: _isFullScreenLocked
                            ? Icon(Icons.lock, color: Colors.white)
                            : Icon(Icons.lock_open, color: Colors.white),
                        onPressed: _toggleFullScreenLock,
                      ),
                    ),
                  ],
                )
              : Container(
                  height: 240.0,
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
        },
      ),
    ),
  );
}


  @override
  void dispose() {
    _timer.cancel();
    _floating.dispose(); // Dispose Floating instance
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:floating/floating.dart'; // Import floating package
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import google_mobile_ads package
import 'package:flue/color.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final bool isFullScreen;
  final Function toggleFullScreen;
  final String telegramId; // Define telegramId here

  VideoPlayerWidget({
    required this.videoPlayerController,
    required this.isFullScreen,
    required this.toggleFullScreen,
    required this.telegramId, // Initialize telegramId parameter
  });

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isVisible = true;
  late Timer _timer;
  bool _isFullScreenLocked = false;
  bool _controlsVisible = true;
  bool _skipOpeningVisible = true;
  double _skipOpeningOpacity = 1.0;
  bool _isOriginalAspectRatio = true;
  late final Floating _floating = Floating(); // Initialize Floating instance
  String userAccess = ''; // Status akses pengguna

  Timer? _lockIconTimer; // Timer for hiding lock icon
  bool _lockIconVisible = true; // Visibility of lock icon

  RewardedAd? _rewardedAd;
  bool _hasShownAdInLandscape = false;
  bool _isAdClosed = false; // Tambahkan deklarasi untuk _isAdClosed

  @override
  void initState() {
    super.initState();
    widget.videoPlayerController.addListener(_onVideoControllerUpdate);
    _startTimer();
    _fetchUserAccess();
    _loadRewardedAd();
    _isAdClosed = false; // Inisialisasi flag
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetAdStateIfNecessary();
  }

  void _resetAdStateIfNecessary() {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      _hasShownAdInLandscape = false;
    }
  }

  Future<void> _fetchUserAccess() async {
    final apiUrl =
        "https://ccgnimex.my.id/v2/android/cek_akses.php?telegram_id=${widget.telegramId}";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        userAccess = data['akses']; // Mendapatkan status akses pengguna
      });
    }
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

  void _skipOpening() {
    setState(() {
      _skipOpeningOpacity = 0.0;
    });
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _skipOpeningVisible = false;
      });
    });

    Duration newPosition;
    if (widget.videoPlayerController.value.isPlaying) {
      newPosition =
          widget.videoPlayerController.value.position + Duration(seconds: 90);
    } else {
      newPosition =
          widget.videoPlayerController.value.position + Duration(seconds: 90);
    }

    widget.videoPlayerController.seekTo(newPosition);
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
      setState(() {
        _isVisible = !_isVisible;
        _controlsVisible =
            true; // Show controls when play/pause button is pressed
      });

      _stopTimer();
      _playPause();
    } else {
      setState(() {
        _lockIconVisible = true;
      });
      _startLockIconTimer();
    }
  }

  void _playPause() {
    if (widget.videoPlayerController.value.isPlaying) {
      widget.videoPlayerController.pause();
    } else {
      if (userAccess != 'Premium' &&
          MediaQuery.of(context).orientation == Orientation.landscape &&
          !_hasShownAdInLandscape) {
        if (_rewardedAd != null) {
          _rewardedAd!.show(
              onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            _hasShownAdInLandscape = true; // Iklan sudah ditampilkan
            _isAdClosed = true;
            _loadRewardedAd();
            // Tidak memainkan video setelah iklan ditutup
            setState(() {
              _isAdClosed = false;
            });
          });
        } else {
          // Jika iklan tidak tersedia, tetap putar videonya
          widget.videoPlayerController.play();
        }
      } else {
        widget.videoPlayerController.play();
      }
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-1587740600496860/9704038856',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  void _toggleFullScreenLock() {
    setState(() {
      _isFullScreenLocked = !_isFullScreenLocked;
    });

    if (_isFullScreenLocked) {
      _startLockIconTimer();
    } else {
      setState(() {
        _lockIconVisible = true;
      });
      _lockIconTimer?.cancel();
    }
  }

  void _startLockIconTimer() {
    _lockIconTimer?.cancel();
    _lockIconTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _lockIconVisible = false;
      });
    });
  }

  void _toggleAspectRatio() {
    setState(() {
      _isOriginalAspectRatio = !_isOriginalAspectRatio;
    });
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fitur akan hadir')),
    );
  }

  Future<void> _enablePiP() async {
    if (widget.isFullScreen) {
      setState(() {
        _controlsVisible = false;
      });

      final status = await _floating.enable();
      print('PiP enabled? $status');

      setState(() {
        _isVisible = false;
        _isFullScreenLocked = true;
        _startLockIconTimer();
      });
    }
  }

  Widget _buildPlayPauseButton() {
    IconData iconData = widget.videoPlayerController.value.isPlaying
        ? Icons.pause
        : Icons.play_arrow;
    return _isFullScreenLocked
        ? Container()
        : AnimatedContainer(
            duration: Duration(milliseconds: 500),
            height: _isVisible ? 60.0 : 0.0,
            width: _isVisible ? 60.0 : 0.0,
            decoration: BoxDecoration(
              color: _isVisible ? Colors.black54 : Colors.transparent,
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

    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
            if (_skipOpeningVisible)
              GestureDetector(
                onTap: _skipOpening,
                child: AnimatedOpacity(
                  opacity: _skipOpeningOpacity,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            8.0), // Padding to add space around the container
                    decoration: BoxDecoration(
                      color: ColorManager.currentPrimaryColor.withOpacity(0.6),
                      borderRadius:
                          BorderRadius.circular(4.0), // Rounded corners
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.fast_forward, color: Colors.white),
                        SizedBox(
                            width:
                                4.0), // Add some space between the icon and text
                        Text(
                          "Skip Opening",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: Container()), // Spacer
            Text(
              "$currentTime / $totalTime",
              style: TextStyle(color: Colors.white),
            ),
            if (isLandscape)
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isOriginalAspectRatio
                          ? Icons.aspect_ratio
                          : Icons.aspect_ratio_outlined,
                      color: Colors.white,
                    ),
                    onPressed: _toggleAspectRatio,
                  ),
                  IconButton(
                    icon: Icon(Icons.picture_in_picture, color: Colors.white),
                    onPressed: _enablePiP,
                  ),
                ],
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (String result) {
                switch (result) {
                  case 'edit_video':
                  case 'cast':
                  case 'search_op_song':
                    _showComingSoonMessage();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit_video',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: Colors.black),
                    title: Text('Edit Video'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'cast',
                  child: ListTile(
                    leading: Icon(Icons.cast, color: Colors.black),
                    title: Text('Cast'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'search_op_song',
                  child: ListTile(
                    leading: Icon(Icons.music_note, color: Colors.black),
                    title: Text('Search OP & ED Song'),
                  ),
                ),
              ],
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
                      // Video Player
                      Container(
                        alignment: Alignment.center,
                        child: AspectRatio(
                          aspectRatio: _isOriginalAspectRatio
                              ? widget.videoPlayerController.value.aspectRatio
                              : orientation == Orientation.landscape
                                  ? MediaQuery.of(context).size.aspectRatio
                                  : widget
                                      .videoPlayerController.value.aspectRatio,
                          child: VideoPlayer(widget.videoPlayerController),
                        ),
                      ),

                      // Overlay untuk kontrol (play/pause)
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

                      // Tombol untuk mengunci/membuka fullscreen
                      Positioned(
                        top: 16,
                        left: 16,
                        child: AnimatedOpacity(
                          opacity: _lockIconVisible || !_isFullScreenLocked
                              ? 1.0
                              : 0.0,
                          duration: Duration(milliseconds: 600),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: IconButton(
                              icon: _isFullScreenLocked
                                  ? Icon(Icons.lock, color: Colors.white)
                                  : Icon(Icons.lock_open, color: Colors.white),
                              onPressed: _toggleFullScreenLock,
                            ),
                          ),
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
    _lockIconTimer?.cancel();
    _rewardedAd?.dispose(); // Dispose rewarded ad
    super.dispose();
  }
}

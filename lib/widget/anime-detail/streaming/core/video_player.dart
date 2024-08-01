import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:floating/floating.dart'; // Import floating package
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import google_mobile_ads package
import 'package:flue/color.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

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
  bool _autoSwitchEpisodes = false;
  bool _showMyPoint =
      false; // Tambahkan variabel untuk mengontrol visibilitas poin
  final int _point = 123;
  String _currentTime = '';
  String _profilePictureUrl = '';
  String _userName = '';
  Duration _watchDuration = Duration();
  String _watchTime =
      '00:00:00'; // Initial watch time // Waktu tonton sebagai sample

  @override
  void initState() {
    super.initState();
    widget.videoPlayerController.addListener(_onVideoControllerUpdate);
    _startTimer();
    _fetchUserAccess();
    _startsTimer();
    _loadRewardedAd();
    _isAdClosed = false;
    _currentTime = _formatCurrentTime();
    _loadWatchDuration();
    // Inisialisasi flag
  }

  void _startWatchTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _watchDuration += Duration(seconds: 1);
        _watchTime = _formatDuration(_watchDuration);
        _saveWatchDuration();
      });
    });
  }

  void _stopWatchTimer() {
    _timer?.cancel(); // Cancel the timer
  }

  Future<void> _loadWatchDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt('watchDuration') ?? 0;
    setState(() {
      _watchDuration = Duration(seconds: seconds);
      _watchTime = _formatDuration(_watchDuration);
    });
  }

  Future<void> _saveWatchDuration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('watchDuration', _watchDuration.inSeconds);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _startsTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        _currentTime = _formatCurrentTime();
      });
    });
  }

  String _formatCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return Icons.wb_sunny; // Morning
    } else if (hour >= 12 && hour < 17) {
      return Icons.wb_sunny_outlined; // Afternoon
    } else if (hour >= 17 && hour < 20) {
      return Icons.wb_twighlight; // Evening
    } else {
      return Icons.nightlight_round; // Night
    }
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
        _profilePictureUrl = data['profile_picture'];
        _userName = data['first_name']; // Mendapatkan URL gambar profil
      });
    } else {
      // Tangani kasus ketika status kode bukan 200
      print('Failed to load user access');
    }
  }

  void _toggleAutoSwitchEpisodes() {
    setState(() {
      _autoSwitchEpisodes = !_autoSwitchEpisodes;
    });

    if (_autoSwitchEpisodes) {
      // Implement logic to auto switch to the next episode
      // For example, you might want to set up a listener to automatically move to the next episode when the current one finishes.
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
      _stopWatchTimer(); // Stop the timer when the video is paused
    } else {
      if (userAccess != 'Premium' &&
          MediaQuery.of(context).orientation == Orientation.landscape &&
          !_hasShownAdInLandscape) {
        if (_rewardedAd != null) {
          _rewardedAd!.show(
              onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            _hasShownAdInLandscape = true; // Ad has been shown
            _isAdClosed = true;
            _loadRewardedAd();
            setState(() {
              _isAdClosed = false;
            });
          });
        } else {
          widget.videoPlayerController.play();
          _startWatchTimer(); // Start the timer when the video starts playing
        }
      } else {
        widget.videoPlayerController.play();
        _startWatchTimer(); // Start the timer when the video starts playing
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
              if (isLandscape)
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
                        color:
                            ColorManager.currentPrimaryColor.withOpacity(0.6),
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
                  case 'auto_switch_eps':
                    _toggleAutoSwitchEpisodes();
                    break;
                  case 'cast':
                  case 'search_op_song':
                    _showComingSoonMessage();
                    break;
                  case 'show_my_point':
                    setState(() {
                      _showMyPoint = !_showMyPoint;
                    });
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'auto_switch_eps',
                  child: ListTile(
                    leading: Icon(
                      _autoSwitchEpisodes
                          ? Icons.switch_video
                          : Icons.switch_video_outlined,
                      color: Colors.black,
                    ),
                    title: Text('Auto Switch EPS'),
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
                PopupMenuItem<String>(
                  value: 'show_my_point',
                  child: ListTile(
                    leading: Icon(
                        _showMyPoint
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: Colors.black),
                    title: Text('Statistik Saya'),
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
        playedColor: ColorManager.currentPrimaryColor,
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
                              color: ColorManager.currentPrimaryColor
                                  .withOpacity(0.2),
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

                      if (_showMyPoint)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(5.6), // 30% smaller
                                decoration: BoxDecoration(
                                  color: ColorManager.currentPrimaryColor
                                      .withOpacity(0.6),
                                  borderRadius:
                                      BorderRadius.circular(5.6), // 30% smaller
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: _profilePictureUrl
                                              .isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              _profilePictureUrl)
                                          : AssetImage(
                                                  'assets/placeholder_image.png')
                                              as ImageProvider,
                                      radius: 11.2, // 30% smaller
                                    ),
                                    SizedBox(width: 5.6), // 30% smaller
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _userName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.2, // 30% smaller
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.timer,
                                                color: Colors.white,
                                                size: 11.2), // 30% smaller
                                            SizedBox(width: 2.8), // 30% smaller
                                            Text(
                                              _watchTime,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9.8, // 30% smaller
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 5.6), // 30% smaller
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8), // 30% smaller
                                    decoration: BoxDecoration(
                                      color: ColorManager.currentPrimaryColor
                                          .withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(
                                          5.6), // 30% smaller
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getTimeIcon(),
                                          color: Colors.white,
                                          size: 11.0, // 30% smaller
                                        ),
                                        SizedBox(width: 2.0), // 30% smaller
                                        AnimatedSwitcher(
                                          duration: Duration(seconds: 1),
                                          transitionBuilder: (Widget child,
                                              Animation<double> animation) {
                                            return ScaleTransition(
                                                child: child, scale: animation);
                                          },
                                          child: Text(
                                            _currentTime,
                                            key: ValueKey<String>(_currentTime),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8, // 30% smaller
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 5.6), // 30% smaller
                                  Container(
                                    padding: EdgeInsets.all(5.6), // 30% smaller
                                    decoration: BoxDecoration(
                                      color: ColorManager.currentPrimaryColor
                                          .withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(
                                          5.6), // 30% smaller
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.leaderboard,
                                            color: Colors.amber,
                                            size: 16.8), // 30% smaller
                                        SizedBox(width: 2.8), // 30% smaller
                                        Text(
                                          '#$_point+',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8, // 30% smaller
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

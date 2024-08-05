import 'dart:async';
import 'dart:io';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/widgets/mini_controller.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:floating/floating.dart'; // Import floating package
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import google_mobile_ads package
import 'package:flue/color.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final bool isFullScreen;
  final Function toggleFullScreen;
  final String telegramId;
  final int episodeNumber;
  final int animeId; // Define telegramId here

  VideoPlayerWidget(
      {required this.videoPlayerController,
      required this.isFullScreen,
      required this.toggleFullScreen,
      required this.telegramId,
      required this.episodeNumber,
      required this.animeId // Initialize telegramId parameter
      });

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isVisible = true;
  late Timer _timer;
  late Timer _timers;
  late Timer _timerr;
  bool _isTimerRunning = false; // Tambahkan variabel ini
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
      ''; // Initialize with an empty string or a placeholder value
  int _peringkat = -1;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    widget.videoPlayerController.addListener(_onVideoControllerUpdate);
    _startTimer();
    _loadWatchDuration(); // Load watch duration from SharedPreferences
    _fetchUserAccess();
    _startWatchTimer(); // Fetch user access details including watch time from server
    _startsTimer();
    _loadRewardedAd();
    _isAdClosed = false;
    _currentTime = _formatCurrentTime();
    _loadShowMyPoint();
    _fetchVideoUrl();
    _initGoogleCast();
    // Inisialisasi flag
  }

  Future<void> _initGoogleCast() async {
    const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
    GoogleCastOptions? options;
    if (Platform.isIOS) {
      options = IOSGoogleCastOptions(
        GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
      );
    } else if (Platform.isAndroid) {
      options = GoogleCastOptionsAndroid(appId: appId);
    }
    GoogleCastContext.instance.setSharedInstanceWithOptions(options!);
  }

  Future<void> _fetchVideoUrl() async {
    final response = await http.get(Uri.parse(
      'https://ccgnimex.my.id/v2/android/api_resolusi.php?anime_id=${widget.animeId}&episode_number=${widget.episodeNumber}',
    ));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final hdVideo = data.firstWhere(
        (item) => item['resolusi'] == 'HD',
        orElse: () => data.first,
      );
      setState(() {
        _videoUrl = hdVideo['video_url'];
      });
    } else {
      // Handle error
    }
  }

  void _cast() async {
    if (_videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL video tidak tersedia')),
      );
      return;
    }

    // Mulai penemuan perangkat untuk mendapatkan daftar perangkat
    GoogleCastDiscoveryManager.instance.startDiscovery();

    final devices =
        await GoogleCastDiscoveryManager.instance.devicesStream.first;

    final device = await showDialog<GoogleCastDevice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pilih perangkat Cast'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.friendlyName),
                  subtitle: Text(device.modelName ?? ''),
                  onTap: () => Navigator.pop(context, device),
                );
              },
            ),
          ),
        );
      },
    );

    // Hentikan penemuan setelah mendapatkan daftar perangkat
    GoogleCastDiscoveryManager.instance.stopDiscovery();

    if (device != null) {
      // Mulai sesi dengan perangkat yang dipilih
      try {
        await GoogleCastSessionManager.instance.startSessionWithDevice(device);

        // Muat dan putar media di perangkat yang dipilih
        final mediaInfo = GoogleCastMediaInformation(
          contentId: '',
          streamType: CastMediaStreamType.BUFFERED,
          contentUrl: Uri.parse(_videoUrl!),
          contentType: 'video/mp4',
          metadata: GoogleCastMovieMediaMetadata(
            title: 'Judul Video',
            images: [
              GoogleCastImage(
                  url: Uri.parse(
                      'https://i.pinimg.com/564x/0a/64/83/0a6483c8ed077a393f1904377efd54b2.jpg'))
            ],
          ),
        );

        await GoogleCastRemoteMediaClient.instance
            .loadMedia(mediaInfo, autoPlay: true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Casting ke ${device.friendlyName} dimulai')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai sesi cast: $error')),
        );
        print("Error starting cast session: $error");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada perangkat yang dipilih')),
      );
    }
  }

  void _loadShowMyPoint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showMyPoint = prefs.getBool('showMyPoint') ?? false;
    });
  }

  void _toggleShowMyPoint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _showMyPoint = !_showMyPoint;
      prefs.setBool('showMyPoint', _showMyPoint);
    });
  }

  void _startWatchTimer() {
    _isTimerRunning = true; // Tandai timer sedang berjalan
    _timerr = Timer.periodic(Duration(seconds: 1), (timer) {
      if (widget.videoPlayerController.value.isPlaying) {
        setState(() {
          _watchDuration += Duration(seconds: 1);
          _watchTime = _formatDuration(_watchDuration);
          _saveWatchDuration();
        });
      } else {
        _stopWatchTimer(); // Stop the timer if the video is paused
        _sendWatchDuration(); // Save the watch duration when the video is paused
      }
    });
  }

  void _stopWatchTimer() {
    if (_timerr != null) {
      _timerr.cancel(); // Cancel the timer
      _isTimerRunning = false; // Tandai timer tidak aktif
    }
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

  Future<void> _sendWatchDuration() async {
    final response = await http.post(
      Uri.parse('https://ccgnimex.my.id/v2/android/save_duration.php'),
      body: {
        'telegram_id': widget.telegramId,
        'watch_duration': _watchTime,
      },
    );

    if (response.statusCode == 200) {
      print('Watch duration updated successfully.');
    } else {
      print('Failed to update watch duration.');
    }
  }

  void _startsTimer() {
    _timers = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateFormat('HH:mm').format(DateTime.now());
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
      _saveWatchDuration();
    }
  }

  Future<void> _fetchUserAccess() async {
    final apiUrl =
        "https://ccgnimex.my.id/v2/android/cek_akses.php?telegram_id=${widget.telegramId}";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        userAccess = data['akses'];
        _profilePictureUrl = data['profile_picture'];
        _userName = data['first_name'];
        if (data['ditonton'] != null && data['ditonton'] != '') {
          if (_watchDuration.inSeconds == 0) {
            // Hanya perbarui jika watchDuration masih 0
            _watchDuration = _parseDuration(data['ditonton']);
            _watchTime = _formatDuration(_watchDuration);
            _saveWatchDuration(); // Simpan durasi yang diambil dari server
          }
        }
        _peringkat = data['peringkat'] ?? -1;
      });
    } else {
      print('Gagal memuat akses pengguna');
    }
  }

  Duration _parseDuration(String watchTime) {
    final parts = watchTime.split(':');
    if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } else {
      return Duration.zero;
    }
  }

  // Fungsi untuk memotong nama pengguna jika lebih dari 11 karakter
  String _truncateUserName(String name) {
    final maxLength = 10;
    final truncated =
        name.length > maxLength ? '${name.substring(0, maxLength - 1)}…' : name;
    // Padding dengan spasi agar panjang total menjadi 13 karakter
    return truncated.padRight(13);
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
      widget.videoPlayerController
          .pause(); // Stop the timer when the video is paused
      _stopWatchTimer(); // Hentikan timer saat video dihentikan
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
          if (!_isTimerRunning) {
            _startWatchTimer(); // Mulai timer hanya jika belum ada timer aktif
          }
        }
      } else {
        widget.videoPlayerController.play();
        if (!_isTimerRunning) {
          _startWatchTimer(); // Mulai timer hanya jika belum ada timer aktif
        }
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
              child: Container(
                decoration: BoxDecoration(
                  color: ColorManager.currentPrimaryColor.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(8.0), // Adjust padding as needed
                child: IconButton(
                  icon: Icon(
                    iconData,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: _playPause,
                ),
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
                    _cast();
                    break;
                  case 'search_op_song':
                    _showComingSoonMessage();
                    break;
                  case 'show_my_point':
                    _toggleShowMyPoint();
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
                PopupMenuItem<String>(
                  value: 'cast',
                  child: ListTile(
                    leading: Icon(Icons.cast, color: Colors.black),
                    title: Text('Cast'),
                  ),
                ),
                PopupMenuItem<String>(
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
                      color: Colors.black,
                    ),
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
                                  .withOpacity(0.4),
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
                                      .withOpacity(0.4),
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
                                          _truncateUserName(_userName),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.2, // 30% smaller
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.remove_red_eye,
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
                                          .withOpacity(0.4),
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
                                          .withOpacity(0.4),
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
                                          '#$_peringkat', // Convert int to String using interpolation
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
    _timerr.cancel();
    _floating.dispose(); // Dispose Floating instance
    _lockIconTimer?.cancel();
    _rewardedAd?.dispose(); // Dispose rewarded ad
    _saveWatchDuration();
    super.dispose();
  }
}

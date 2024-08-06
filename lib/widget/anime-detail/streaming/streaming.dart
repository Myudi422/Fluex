// Impor yang diperlukan
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'core/convertdurasi.dart';
import 'core/episode_list.dart';
import 'core/video_player.dart';
import 'core/info.dart';
import 'package:http/http.dart' as http;
import 'package:flue/color.dart';
import 'dart:convert';
import 'dart:async';
import "package:shimmer/shimmer.dart";
import 'core/download.dart';
import 'core/komen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Definisi widget StreamingWidget
class StreamingWidget extends StatefulWidget {
  // Properti widget
  final int episodeNumber;
  final List<dynamic> episodes;
  final String videoTime;
  final String telegramId;
  final int animeId;
  final Map<String, dynamic> animeData;

  // Konstruktor
  StreamingWidget({
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

class _StreamingWidgetState extends State<StreamingWidget>
    with WidgetsBindingObserver {
  // Deklarasi variabel
  late VideoPlayerController _videoPlayerController;
  bool _isFullScreen = false;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  late String _selectedResolution;
  late List<Map<String, String>> _availableResolutions;

  // Declare the _timer variable
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Initialize the timer
    _timer = Timer(Duration(seconds: 0), () {});
    // Rest of your initState logic
    WidgetsBinding.instance?.addObserver(this);
    _selectedResolution = '';
    _availableResolutions = [];
    _videoPlayerController = VideoPlayerController.network('');
    _initializeVideoPlayer();
    _fetchEpisodes();
  }

  // Method to get the current video URL from the VideoPlayerController
  String getCurrentVideoUrl() {
    return _videoPlayerController.dataSource ?? '';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sendVideoTimeToServer();
    _videoPlayerController.dispose();
    _disableWakelock();
    _timer.cancel(); // Cancel the timer
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPlaying) {
      _enableWakelock();
    } else {
      _disableWakelock();
    }
  }

  // Metode dipanggil ketika widget diperbarui
  @override
  void didUpdateWidget(covariant StreamingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.episodeNumber != oldWidget.episodeNumber ||
        _selectedResolution.isEmpty) {
      _updateVideoPlayer();
    }
  }

  // Metode inisialisasi video player
  void _initializeVideoPlayer() {
    _videoPlayerController.addListener(() {
      if (_isDisposed) return;

      setState(() {});

      if (_videoPlayerController.value.position >=
          _videoPlayerController.value.duration) {
        _videoPlayerController.pause();
        _disableWakelock();
      }

      if (_videoPlayerController.value.isPlaying && !_isPlaying) {
        _isPlaying = true;
        _enableWakelock();
      } else if (!_videoPlayerController.value.isPlaying && _isPlaying) {
        _isPlaying = false;
        _disableWakelock();
        _sendVideoTimeToServer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Enable immersive sticky mode for full-screen
    SystemChrome.setEnabledSystemUIMode(
      _isFullScreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );

    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        _sendVideoTimeToServer();
        return true;
      },
      child: Scaffold(
        backgroundColor: ColorManager.currentBackgroundColor,
        body: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return _buildPortraitLayout();
            } else {
              return _buildLandscapeLayout();
            }
          },
        ),
      ),
    );
  }

// Modify _buildPortraitLayout() to include _buildDropdown() within DownloadPage
  Widget _buildPortraitLayout() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildVideoPlayer(), // Placeholder height for video player
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  SizedBox(height: 16.0),
                  EpisodeListWidget(
                    episodes: widget.episodes,
                    currentEpisodeNumber: widget.episodeNumber,
                    onEpisodeSelected: (episodeNumber) {
                      if (episodeNumber != widget.episodeNumber) {
                        // Mencari episode berdasarkan nomor episode
                        final selectedEpisode = widget.episodes.firstWhere(
                          (episode) =>
                              episode['episode_number'] == episodeNumber,
                          orElse: () => null,
                        );

                        if (selectedEpisode != null) {
                          _navigateToSelectedEpisode(
                            episodeNumber,
                            selectedEpisode['video_time'],
                          );
                        } else {
                          print("Nomor episode tidak valid: $episodeNumber");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Episode $episodeNumber tidak ditemukan")),
                          );
                        }
                      }
                    },
                  ),
                  SizedBox(height: 6.0),
                  AnimeInfoWidget(
                    animeData: widget.animeData,
                    episodeNumber: widget.episodeNumber,
                  ),
                  DownloadPage(
                    animeData: widget.animeData,
                    episodeNumber: widget.episodeNumber,
                    dropdown: _buildDropdown(),
                    videoUrl: getCurrentVideoUrl(),
                    animeId: widget.animeId,
                  ),
                  KomenPage(
                    episodeNumber: widget.episodeNumber,
                    animeId: widget.animeId,
                    telegramId: widget.telegramId,
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildVideoPlayer(),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: ColorManager.currentPrimaryColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.waveSquare,
              color: Colors.white), // Horizontal ellipsis icon
          SizedBox(width: 8.0),
          DropdownButton(
            value: _selectedResolution,
            dropdownColor: ColorManager
                .currentPrimaryColor, // Set dropdown background color
            icon: Icon(Icons.arrow_drop_down,
                color: Colors.white), // Default dropdown arrow
            underline: SizedBox.shrink(),
            items: _availableResolutions.map((resolution) {
              return DropdownMenuItem(
                value: resolution['resolusi'],
                child: Text(
                  resolution['resolusi']!,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (_isDisposed) return;
              setState(() {
                _selectedResolution = value as String;
                _videoPlayerController.dispose();
                _sendVideoTimeToServer();
                _updateVideoPlayer();
                _timer.cancel();

                // Save selected resolution to SharedPreferences
                _saveSelectedResolution(value as String);
              });
            },
          ),
        ],
      ),
    );
  }

// Metode untuk menyimpan resolusi yang dipilih ke SharedPreferences
  void _saveSelectedResolution(String resolution) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedResolution', resolution);
  }

// Metode untuk mendapatkan resolusi yang dipilih dari SharedPreferences
  Future<String?> _getSelectedResolution() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedResolution');
  }

  // Metode membangun tata letak untuk orientasi landscape
  Widget _buildLandscapeLayout() {
    return _buildVideoPlayer();
  }

  Widget _buildVideoPlayer() {
    if (_isInitialized && _videoPlayerController.value.isInitialized) {
      return VideoPlayerWidget(
        videoPlayerController: _videoPlayerController,
        isFullScreen: _isFullScreen,
        toggleFullScreen: _toggleFullScreen,
        telegramId: widget.telegramId,
        episodeNumber: widget.episodeNumber,
        animeId: widget.animeId, // Pass telegramId here
      );
    } else {
      double shimmerHeight = MediaQuery.of(context).size.height * 0.25;
      double shimmerWidth =
          _isFullScreen ? double.infinity : MediaQuery.of(context).size.width;

      return Shimmer.fromColors(
        baseColor: Colors.grey[500]!,
        highlightColor: ColorManager.currentHomeColor,
        child: Container(
          height: shimmerHeight,
          width: shimmerWidth,
          color: Colors.white,
        ),
      );
    }
  }

  // Metode memperbarui pemutar video
  void _updateVideoPlayer() async {
    if (_isDisposed) return;

    // Simpan waktu video saat ini ke server dan tunggu hingga selesai
    await _sendVideoTimeToServer();

    final selectedResolutionLowerCase = _selectedResolution.toLowerCase();

    final selectedEpisode = _availableResolutions.firstWhere(
      (resolution) =>
          resolution['resolusi']!.toLowerCase() == selectedResolutionLowerCase,
      orElse: () {
        print(
            'Defaulting to the first episode with resolution: $_selectedResolution');
        return _availableResolutions.first;
      },
    );

    if (selectedEpisode == null) {
      print('Episode not found for resolution: $_selectedResolution');
      return;
    }

    // Tampilkan shimmer saat menginisialisasi pemutar video baru
    setState(() {
      _isInitialized = false;
    });

    final newController =
        VideoPlayerController.network(selectedEpisode['video_url']!);
    await newController.initialize();

    if (_isDisposed) return;

    setState(() {
      _videoPlayerController.dispose();
      _videoPlayerController = newController;
      _isInitialized = true;
    });

    double providedTime = 0.0;
    if (widget.videoTime != null && widget.videoTime.isNotEmpty) {
      try {
        providedTime = double.parse(widget.videoTime);
      } catch (e) {
        print(
            "Error parsing video time: $e. Provided time: ${widget.videoTime}");
      }
    }

    if (providedTime <= _videoPlayerController.value.duration!.inSeconds) {
      _videoPlayerController.seekTo(Duration(seconds: providedTime.toInt()));
    } else {
      print(
          "Provided time is greater than video duration. Playing from the beginning.");
    }

    if (_isPlaying) {
      _videoPlayerController.play();
    }

    _initializeVideoPlayer(); // Inisialisasi listener lagi
  }

  // Metode mengaktifkan wakelock
  void _enableWakelock() {
    Wakelock.enable();
  }

  // Metode menonaktifkan wakelock
  void _disableWakelock() {
    Wakelock.disable();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // Aktifkan mode fullscreen dengan menyembunyikan status bar dan navigasi bar
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: []);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Kembalikan UI sistem ke mode edge-to-edge
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
          overlays: SystemUiOverlay.values);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // Force rebuild the widget to update the UI
    setState(() {});
  }

  void _navigateToSelectedEpisode(int episodeNumber, String? videoTime) async {
    _disableWakelock(); // Menonaktifkan wakelock sementara

    // Menemukan episode dengan nomor episode yang ditentukan
    final selectedEpisode = widget.episodes.firstWhere(
      (episode) => episode['episode_number'] == episodeNumber,
      orElse: () => null,
    );

    if (selectedEpisode == null) {
      // Menampilkan error atau menangani dengan baik jika episode tidak ada
      print("Nomor episode tidak valid: $episodeNumber");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Episode $episodeNumber tidak ditemukan")),
      );
      return;
    }

    // Navigasi ke halaman streaming untuk episode yang dipilih
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StreamingWidget(
          episodeNumber: episodeNumber,
          animeId: widget.animeId,
          telegramId: widget.telegramId,
          episodes: widget.episodes,
          videoTime: videoTime ?? '',
          animeData: widget.animeData,
        ),
      ),
    );

    _enableWakelock(); // Mengaktifkan wakelock kembali setelah navigasi
  }

  void _fetchEpisodes() async {
    try {
      // Debugging statement to check the episode number before fetching
      print("Fetching resolutions for episode number: ${widget.episodeNumber}");

      // Retrieve the previously selected resolution
      String? savedResolution = await _getSelectedResolution();

      final apiUrl =
          'https://ccgnimex.my.id/v2/android/api_resolusi.php?anime_id=${widget.animeId}&episode_number=${widget.episodeNumber}';
      final response = await http.get(Uri.parse(apiUrl));

      // Check the response status
      if (response.statusCode == 200) {
        // Parse the response
        List<dynamic> resolutions = json.decode(response.body);

        // Debugging statement to check the fetched resolutions
        print('Fetched resolutions: $resolutions');

        if (resolutions.isNotEmpty) {
          _availableResolutions = resolutions
              .map<Map<String, String>>((resolution) => {
                    'resolusi': resolution['resolusi'].toString(),
                    'video_url': resolution['video_url'].toString(),
                  })
              .toList();

          // Debugging statement to check the available resolutions
          print('Available Resolutions: $_availableResolutions');

          if (_availableResolutions.isNotEmpty) {
            setState(() {
              // If saved resolution exists and is in the available resolutions, use it; otherwise, use the first resolution
              _selectedResolution = savedResolution != null &&
                      _availableResolutions
                          .any((res) => res['resolusi'] == savedResolution)
                  ? savedResolution
                  : _availableResolutions[0]['resolusi']!;
            });

            _updateVideoPlayer();
          } else {
            throw Exception('No resolutions found in episode data');
          }
        } else {
          // Handle empty resolution list
          throw Exception('No resolutions available for this episode');
        }
      } else {
        // Handle non-200 status code
        throw Exception(
            'Failed to load episode data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Error: $e');
      // You can choose to show an error message to the user or take other actions.
    }
  }

  // Sending video time to the server method
  Future<void> _sendVideoTimeToServer() async {
    try {
      var url = 'https://ccgnimex.my.id/v2/android/api_episode.php';

      int videoTimeInSeconds = _videoPlayerController.value.position.inSeconds;

      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          'anime_id': widget.animeId.toString(),
          'telegram_id': widget.telegramId,
          'video_time': videoTimeInSeconds.toString(),
          'episode_number': widget.episodeNumber.toString(),
          'last_watched': DateTime.now().toString(),
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (e) {
      print('Error sending video time: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shimmer/shimmer.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flue/color.dart';

class Playlist {
  String name;
  List<String> videoLinks;

  Playlist({required this.name, required this.videoLinks});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'],
      videoLinks: List<String>.from(json['video_links']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'video_links': videoLinks,
    };
  }
}

class MusicPage extends StatefulWidget {
  final String telegramId;

  MusicPage({required this.telegramId, Key? key}) : super(key: key);

  @override
  _MusicPageState createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage>
    with AutomaticKeepAliveClientMixin {
  late AudioPlayer _audioPlayer;
  bool isMusicPlaying = false;
  Duration? _duration;
  Duration _position = Duration();
  bool isLoading = true;
  bool isPlayerExpanded = false;
  bool isPlayerVisible = true;
  bool isOfflineMode = false;
  bool isMusicSelected = true;
  List<Video> videos = [];
  int currentVideoIndex = 0;
  bool isLoadingVideos = true;
  TextEditingController searchController = TextEditingController();
  String searchKeyword = '';
  bool isSearching = false;
  int userSelectedIndex = 0;
  int selectedPlaylistIndex = -1;
  TextEditingController? playlistNameController;
  List<Playlist> playlists = [];
  List<FileSystemEntity> localFiles = [];
  final String folderPath = '/storage/emulated/0/Download/Flue';

  @override
  bool get wantKeepAlive => true; // Ensure this is set to true
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _loadVideos();
    _loadPlaylists();
  }

  Future<void> _initializeAudioPlayer() async {
    _audioPlayer = AudioPlayer()
      ..durationStream.listen((duration) {
        setState(() {
          _duration = duration;
        });
      })
      ..positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      })
      ..processingStateStream.listen((processingState) {
        if (processingState == ProcessingState.completed) {
          _playNextVideo();
        }
      });
  }

  Future<void> _loadVideos() async {
    try {
      final String apiUrl =
          'https://ccgnimex.my.id/v2/android/music/homepage.php';

      // Kirim request ke API untuk mendapatkan playlistId
      final response = await http.post(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Parsing JSON response untuk mendapatkan playlistId
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String playlistId = responseData['playlistId'];

        // Menggunakan YoutubeExplode untuk mengambil video dari playlistId
        final yt = YoutubeExplode();

        if (!isSearching) {
          videos = await yt.playlists.getVideos(playlistId).toList();
        }

        if (searchKeyword.isNotEmpty) {
          final searchResults = await yt.search.getVideos(searchKeyword);
          videos = searchResults.where((video) {
            return (video.duration?.inMinutes ?? 0) <= 20;
          }).toList();
        }

        if (currentVideoIndex >= videos.length) {
          currentVideoIndex = 0;
        }

        setState(() {
          isLoadingVideos = false;
        });

        yt.close();
      } else {
        setState(() {
          isLoadingVideos = false;
          videos = [];
        });
        print('Failed to load playlistId. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoadingVideos = false;
        videos = [];
      });
      print('Error loading playlistId: $e');
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final response = await http.get(Uri.parse(
          'https://ccgnimex.my.id/v2/android/music/my.php?telegram_id=${widget.telegramId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            playlists = (data['playlists'] as List)
                .map((playlistJson) => Playlist.fromJson(playlistJson))
                .toList();
          });
        } else {
          print('Failed to load playlists: ${data['message']}');
        }
      } else {
        print('Failed to load playlists. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading playlists: $e');
    }
  }

  Future<void> _loadVideosFromPlaylist(Playlist playlist) async {
    try {
      final yt = YoutubeExplode();

      // Use the video links from the selected playlist
      final videoLinks = playlist.videoLinks;

      // Load video details from the video links
      videos = [];
      for (final videoLink in videoLinks) {
        final videoId = VideoId(videoLink);
        final videoDetails = await yt.videos.get(videoId);
        videos.add(videoDetails);
      }

      // Set the current video index to the first video in the playlist
      currentVideoIndex = 0;

      // Update the UI
      setState(() {
        isLoadingVideos = false;
      });

      yt.close();
    } catch (e) {
      setState(() {
        isLoadingVideos = false;
        videos = [];
      });
      print("Error loading videos from playlist: $e");
    }
  }

  void _playPlaylist(Playlist playlist) async {
    setState(() {
      isLoadingVideos = true;
    });

    await _stopAndResetAudioPlayer();

    await _loadVideosFromPlaylist(playlist);

    if (videos.isNotEmpty) {
      await _updateAudioPlayer(videos[0]);
      await _handleMusicPlayback(true);
    }

    setState(() {
      isLoadingVideos = false;
    });
  }

  Widget _buildPlaylistSection() {
    List<Color> cardColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      // Add more colors as needed
    ];

    final double containerWidth = playlists.length <= 2 ? 250.0 : 120.0;

    if (playlists.isEmpty) {
      // Hide the widget if there are no playlists
      return Container();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.0),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          final currentColor = cardColors[index % cardColors.length];
          final isSelected = index == selectedPlaylistIndex;

          return Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0),
            child: Material(
              borderRadius: BorderRadius.circular(16.0),
              color: isSelected ? Colors.grey : Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16.0),
                onTap: () {
                  _playPlaylist(playlist);
                  setState(() {
                    selectedPlaylistIndex = index;
                  });
                },
                onLongPress: () {
                  // Tambahkan pemanggilan fungsi penghapus playlist di sini
                  _showDeleteConfirmationDialog(playlist);
                },
                child: Container(
                  width: containerWidth,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isSelected ? Colors.white : currentColor,
                    ),
                  ),
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.music,
                        color: isSelected ? Colors.white : currentColor,
                        size: 20.0,
                      ),
                      SizedBox(width: 4.0),
                      FittedBox(
                        child: Text(
                          playlist.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : currentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(Playlist playlist) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Playlist'),
          content:
              Text('Anda yakin ingin menghapus playlist "${playlist.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                // Panggil fungsi penghapus playlist di sini
                _deletePlaylist(playlist);
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

// Update the _deletePlaylist function
  Future<void> _deletePlaylist(Playlist playlist) async {
    try {
      // Send HTTP request to the PHP API to delete the specific playlist
      final response = await http.post(
        Uri.parse('https://ccgnimex.my.id/v2/android/music/hapus.php'),
        body: {
          'telegram_id': widget.telegramId,
          'playlist_name': playlist.name,
        },
      );

      if (response.statusCode == 200) {
        // Successfully deleted the specific playlist
        final result = jsonDecode(response.body)['message'];
        print(result);

        // Reload playlists to update the UI
        _loadPlaylists();
      } else {
        // Failed to delete the specific playlist
        print('Failed to delete the playlist.');
      }
    } catch (e) {
      print('Error deleting the playlist: $e');
    }
  }

  Future<void> _loadLocalFiles() async {
    final directory = Directory(folderPath);
    setState(() {
      localFiles = directory.listSync().where((file) {
        return file.path.endsWith('.mp3') || file.path.endsWith('.mp4');
      }).toList();
    });
  }

  void _offlinemode() {
    setState(() {
      isOfflineMode = true;
    });
    _loadLocalFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.currentBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari Di Youtube',
                        hintStyle:
                            TextStyle(color: ColorManager.currentHomeColor),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: ColorManager.currentHomeColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: ColorManager.currentHomeColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: ColorManager.currentHomeColor),
                        ),
                      ),
                      style: TextStyle(color: ColorManager.currentHomeColor),
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      Icon(Icons.search, color: ColorManager.currentHomeColor),
                  onPressed: () {
                    setState(() {
                      searchKeyword = searchController.text;
                      isSearching = true;
                      isOfflineMode = false;
                    });
                    _loadVideos();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.playlist_play,
                      color: ColorManager.currentHomeColor),
                  onPressed: () {
                    setState(() {
                      searchKeyword = '';
                      isSearching = false;
                      isOfflineMode = false;
                    });
                    _loadVideos();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.offline_pin,
                      color: ColorManager.currentHomeColor),
                  onPressed: () {
                    setState(() {
                      searchKeyword = '';
                      isSearching = false;
                      isOfflineMode = true;
                    });
                    _offlinemode();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                if (isOfflineMode)
                  Container(
                    width: double.infinity,
                    child: Center(
                      child: ToggleButtons(
                        constraints: BoxConstraints(
                          minWidth:
                              (MediaQuery.of(context).size.width - 32) / 2,
                          minHeight: 40.0,
                        ),
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('Music',
                                style: TextStyle(
                                    color: ColorManager.currentHomeColor)),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('Video',
                                style: TextStyle(
                                    color: ColorManager.currentHomeColor)),
                          ),
                        ],
                        isSelected: [isMusicSelected, !isMusicSelected],
                        onPressed: (index) {
                          setState(() {
                            isMusicSelected = index == 0;
                          });
                          _loadLocalFiles();
                        },
                      ),
                    ),
                  ),
                Expanded(
                  child: isOfflineMode
                      ? ListView.builder(
                          itemCount: localFiles.length,
                          itemBuilder: (context, index) {
                            final file = localFiles[index];
                            final fileName = file.path.split('/').last;
                            final fileExtension = file.path.split('.').last;
                            return ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  fileExtension == 'mp3'
                                      ? Icons.music_note
                                      : Icons.videocam,
                                  size: 30,
                                  color: ColorManager.currentHomeColor,
                                ),
                              ),
                              title: Text(fileName,
                                  style: TextStyle(
                                      color: ColorManager.currentHomeColor)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteFile(file);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete',
                                        style: TextStyle(
                                            color: ColorManager
                                                .currentBackgroundColor)),
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (fileExtension == 'mp3') {
                                  _audioPlayer.setFilePath(file.path).then((_) {
                                    _audioPlayer.play();
                                  });
                                } else if (fileExtension == 'mp4') {
                                  OpenFile.open(file.path);
                                }
                              },
                            );
                          },
                        )
                      : isLoadingVideos
                          ? Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                if (isPlayerExpanded) _buildMusicPlayer(),
                                _buildPlaylistSection(),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: videos.length,
                                    itemBuilder: (context, index) {
                                      final video = videos[index];
                                      return Container(
                                        color: currentVideoIndex == index
                                            ? ColorManager.currentPrimaryColor
                                            : null,
                                        child: ListTile(
                                          onTap: () => _handleVideoTap(video),
                                          leading: Hero(
                                            tag: 'thumbnail_${video.id}',
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  video.thumbnails.mediumResUrl,
                                              placeholder: (context, url) =>
                                                  CircularProgressIndicator(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Icon(Icons.error),
                                            ),
                                          ),
                                          title: Text(video.title,
                                              style: TextStyle(
                                                  color: ColorManager
                                                      .currentHomeColor)),
                                          trailing: PopupMenuButton<String>(
                                            icon: Icon(
                                              FontAwesomeIcons.ellipsisV,
                                              size: 18,
                                              color:
                                                  ColorManager.currentHomeColor,
                                            ),
                                            onSelected: (String result) async {
                                              if (result == 'download') {
                                                await _downloadVideo(video);
                                              } else if (result ==
                                                  'addToPlaylist') {
                                                await _addToPlaylist(video);
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) =>
                                                    <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: 'download',
                                                child: ListTile(
                                                  leading: Icon(Icons.download),
                                                  title: Text('Unduh'),
                                                ),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'addToPlaylist',
                                                child: ListTile(
                                                  leading:
                                                      Icon(Icons.playlist_add),
                                                  title: Text(
                                                      'Tambahkan ke Playlist'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> getVideoStreamUrl(Video video) async {
    final yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(video.id);
    var streamInfo = manifest.audioOnly.first;
    yt.close();
    return streamInfo.url.toString();
  }

  Future<void> _stopAudioPlayer() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> _resetAudioPlayer() async {
    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);
  }

  void _handleVideoTap(Video video) async {
    try {
      await _stopAndResetAudioPlayer();

      final int selectedVideoIndex = videos.indexOf(video);

      setState(() {
        isLoading = true;
        userSelectedIndex =
            selectedVideoIndex; // Simpan urutan pilihan pengguna
        currentVideoIndex = userSelectedIndex; // Perbarui currentVideoIndex
      });

      await _updateAudioPlayer(video);

      final videoUrl = 'https://www.youtube.com/watch?v=${video.id}';
      final streamUrl = await getVideoStreamUrl(video);

      final yt = YoutubeExplode();
      final videoDetails = await yt.videos.get(video.id);
      final thumbnails = videoDetails.thumbnails;
      final album = videoDetails.author;

      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          tag: MediaItem(
            id: video.id.toString(),
            album: album,
            title: videoDetails.title,
            artUri: Uri.parse(thumbnails.mediumResUrl),
          ),
        ),
      );

      // Update the currentVideoIndex before starting playback
      setState(() {
        isLoading = false;
        isPlayerExpanded = true;
        isPlayerVisible = true;
      });

      // Start audio playback
      await _handleMusicPlayback(true);

      yt.close();
    } catch (e) {
      print("Error handling video tap: $e");
      // TODO: Tampilkan pesan kesalahan kepada pengguna
    }
  }

  Future<void> _stopAndResetAudioPlayer() async {
    await _stopAudioPlayer();
    await _resetAudioPlayer();
  }

  Future<void> _playPreviousVideo() async {
    setState(() {
      currentVideoIndex = _calculatePreviousIndex();
      if (currentVideoIndex >= 0) {
        _updateAudioPlayer(videos[currentVideoIndex]);
      }
    });
  }

  int _calculatePreviousIndex() {
    if (currentVideoIndex - 1 >= 0) {
      return currentVideoIndex - 1;
    } else {
      return videos.length - 1;
    }
  }

  Future<void> _playNextVideo() async {
    int nextIndex = _calculateNextIndex();

    if (nextIndex < videos.length) {
      setState(() {
        currentVideoIndex = nextIndex;
        userSelectedIndex = currentVideoIndex; // Update userSelectedIndex
      });

      await _updateAudioPlayer(videos[currentVideoIndex]);
    } else {
      // Jika sudah di akhir playlist, stop pemutaran
      if (currentVideoIndex < videos.length) {
        setState(() {
          currentVideoIndex =
              videos.length; // Menandakan playlist telah selesai
          userSelectedIndex = currentVideoIndex; // Update userSelectedIndex
        });

        await _stopAudioPlayer();
      }
    }
  }

  int _calculateNextIndex() {
    int nextIndex = currentVideoIndex + 1;

    if (nextIndex < videos.length) {
      return nextIndex;
    } else {
      // Jika sudah di akhir playlist, kembali ke awal
      return 0;
    }
  }

  int _previousShuffleIndex = 0;

  void _handleShuffle() {
    setState(() {
      videos.shuffle();
      _previousShuffleIndex = currentVideoIndex;
      currentVideoIndex = 0;
      _updateAudioPlayer(videos[currentVideoIndex]);
    });
  }

  Future<void> _updateAudioPlayer(Video video) async {
    setState(() {
      isLoading = true;
      currentVideoIndex = videos.indexOf(video);
    });

    final videoUrl = 'https://www.youtube.com/watch?v=${video.id}';
    final streamUrl = await getVideoStreamUrl(video);

    await _audioPlayer.stop();
    await _audioPlayer.seek(Duration.zero);

    final yt = YoutubeExplode();
    final videoDetails = await yt.videos.get(video.id);
    final thumbnails = videoDetails.thumbnails;
    final album = videoDetails.author;

    _audioPlayer.setAudioSource(
      AudioSource.uri(
        Uri.parse(streamUrl),
        tag: MediaItem(
          id: video.id.toString(),
          album: album,
          title: videoDetails.title,
          artUri: Uri.parse(thumbnails.mediumResUrl),
        ),
      ),
    );

    _audioPlayer.play();

    setState(() {
      isLoading = false;
      isPlayerExpanded = true;
      isPlayerVisible = true;
    });

    yt.close();
  }

  void _togglePlayerVisibility() {
    setState(() {
      isPlayerVisible = !isPlayerVisible;
    });
  }

  Future<void> _handleMusicPlayback(bool isPlaying) async {
    if (isPlaying) {
      await _audioPlayer.play();
    } else {
      await _audioPlayer.pause();
    }
  }

  Widget _buildMusicPlayer() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? false;

        return AnimatedContainer(
          duration: Duration(milliseconds: 500),
          height: isPlayerExpanded ? 180 : 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(top: BorderSide(color: Colors.grey)),
          ),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 500),
            opacity: isPlayerVisible ? 1.0 : 0.0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            isPlayerExpanded = false;
                            isPlayerVisible = false;
                          });
                          _stopAudioPlayer();
                        },
                      ),
                    ],
                  ),
                  if (isLoading)
                    _buildShimmerLoading()
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              margin: EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    videos[currentVideoIndex]
                                            ?.thumbnails
                                            .mediumResUrl ??
                                        '',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.skip_previous),
                              onPressed: _playPreviousVideo,
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                              ),
                              onPressed: () {
                                _handleMusicPlayback(!isPlaying);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.skip_next),
                              onPressed: _playNextVideo,
                            ),
                            IconButton(
                              icon: Icon(Icons.shuffle),
                              onPressed: _handleShuffle,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    videos[currentVideoIndex]?.title ??
                                        'Song Title',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    videos[currentVideoIndex]?.author ??
                                        'Artist Name',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        if (_duration != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
                              ),
                              Expanded(
                                child: Slider(
                                  value: _position.inMilliseconds.toDouble(),
                                  min: 0.0,
                                  max: _duration!.inMilliseconds.toDouble(),
                                  onChanged: (value) {
                                    _audioPlayer.seek(
                                        Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              ),
                              Text(
                                '${_duration!.inMinutes}:${(_duration!.inSeconds % 60).toString().padLeft(2, '0')}',
                              ),
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<List<MuxedStreamInfo>> getAvailableMuxedStreamInfo(Video video) async {
    final yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(video.id);
    yt.close();
    return manifest.muxed.toList();
  }

  Future<List<AudioOnlyStreamInfo>> getAvailableAudioStreamInfo(
      Video video) async {
    final yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(video.id);
    yt.close();
    return manifest.audioOnly.toList();
  }

  Future<MuxedStreamInfo?> getMuxedStreamInfo(
      Video video, String resolution, String type) async {
    var availableStreams = await getAvailableMuxedStreamInfo(video);
    return availableStreams.firstWhereOrNull(
      (stream) =>
          stream.videoQualityLabel == resolution &&
          stream.container.name == type,
    );
  }

  Future<AudioOnlyStreamInfo?> getAudioStreamInfo(
      Video video, String type) async {
    var availableStreams = await getAvailableAudioStreamInfo(video);
    return availableStreams.firstWhereOrNull(
      (stream) => stream.container.name == type,
    );
  }

  Future<void> _downloadVideo(Video video) async {
    final muxedStreams = await getAvailableMuxedStreamInfo(video);
    final audioStreams = await getAvailableAudioStreamInfo(video);

    // Menggabungkan resolusi dan tipe untuk muxed dan audio
    final muxedOptions = muxedStreams
        .map((stream) =>
            '${stream.videoQualityLabel} - ${stream.container.name.toUpperCase()}')
        .toSet()
        .toList();
    final audioOptions = audioStreams
        .map((stream) => 'AUDIO - ${stream.container.name.toUpperCase()}')
        .toSet()
        .toList();

    final options = muxedOptions + audioOptions;

    final selectedOption = await _showOptionSelectionDialog(options);
    if (selectedOption == null) {
      // User canceled selection
      return;
    }

    if (selectedOption.startsWith('AUDIO')) {
      final type = selectedOption.split(' - ')[1].toLowerCase();
      try {
        // Tentukan path penyimpanan
        String downloadPath = '/storage/emulated/0/Download/Flue';

        // Buat direktori "Download/Flue" jika belum ada
        Directory downloadDir = Directory(downloadPath);
        if (!downloadDir.existsSync()) {
          downloadDir.createSync(recursive: true);
        }

        // Mulai unduhan dengan menggunakan path penyimpanan
        final streamInfo = await getAudioStreamInfo(video, type);
        final taskId = await FlutterDownloader.enqueue(
          url: streamInfo!.url.toString(), // Use the audio stream URL
          savedDir: downloadPath,
          fileName: 'Flue - ${video.title} - Audio.mp3',
          showNotification: true,
          openFileFromNotification: true,
          requiresStorageNotLow: true,
        );

        FlutterDownloader.registerCallback((id, status, progress) {
          // Handle download progress or completion here
          // Optionally, update UI or state
        });

        _showSnackBar('Download started');
      } catch (error) {
        print('Error downloading audio: $error');
        _showSnackBar('Failed to start download');
      }
    } else {
      final parts = selectedOption.split(' - ');
      final resolution = parts[0];
      final type = parts[1].toLowerCase();

      try {
        // Tentukan path penyimpanan
        String downloadPath = '/storage/emulated/0/Download/Flue';

        // Buat direktori "Download/Flue" jika belum ada
        Directory downloadDir = Directory(downloadPath);
        if (!downloadDir.existsSync()) {
          downloadDir.createSync(recursive: true);
        }

        // Mulai unduhan dengan menggunakan path penyimpanan
        final streamInfo = await getMuxedStreamInfo(video, resolution, type);
        final taskId = await FlutterDownloader.enqueue(
          url: streamInfo!.url.toString(), // Use the video stream URL
          savedDir: downloadPath,
          fileName: 'Flue - ${video.title} - Video.$type',
          showNotification: true,
          openFileFromNotification: true,
          requiresStorageNotLow: true,
        );

        FlutterDownloader.registerCallback((id, status, progress) {
          // Handle download progress or completion here
          // Optionally, update UI or state
        });

        _showSnackBar('Download started');
      } catch (error) {
        print('Error downloading video: $error');
        _showSnackBar('Failed to start download');
      }
    }
  }

  Future<String?> _showOptionSelectionDialog(List<String> options) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Resolution and Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((option) => ListTile(
                      title: Text(option),
                      onTap: () => Navigator.pop(context, option),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _addToPlaylist(Video video) async {
    // Retrieve existing playlists from the API
    List<String> existingPlaylists = await _getExistingPlaylists();

    String? playlistName =
        await _showPlaylistSelectionDialog(existingPlaylists);

    if (playlistName == null) {
      // Handle the case when the user cancels playlist selection
      return;
    }

    // Save necessary information to variables
    String youtubeLink = "https://www.youtube.com/watch?v=${video.id}";

    // Send HTTP request to the PHP API to add the video to the selected playlist
    final response = await http.post(
      Uri.parse('https://ccgnimex.my.id/v2/android/music/api.php'),
      body: {
        'telegram_id': widget.telegramId,
        'playlist_name': playlistName,
        'video_link': youtubeLink,
      },
    );

    if (response.statusCode == 200) {
      // Successfully added video to the playlist
      final result = jsonDecode(response.body)['result'];
      print(result);

      // Show success message
      _showSnackBar("Video Sudah ditambahkan ke Playlist");

      // Reload playlists to update the UI
      _loadPlaylists();
    } else {
      // Failed to add video to the playlist
      print('Failed to add video to the playlist.');

      // Show error message
      _showSnackBar("Video gagal ditambahkan ke Playlist");
    }
  }

// Function to show a snackbar at the bottom of the screen
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

// Fungsi untuk menampilkan dialog atau formulir meminta nama playlist dari pengguna
  Future<List<String>> _getExistingPlaylists() async {
    // Send HTTP request to the PHP API to retrieve existing playlists
    final response = await http.get(
      Uri.parse(
          'https://ccgnimex.my.id/v2/android/music/playlist.php?telegram_id=${widget.telegramId}'),
    );

    if (response.statusCode == 200) {
      // Successfully retrieved existing playlists
      final playlists = jsonDecode(response.body)['playlists'];
      return List<String>.from(
          playlists.map((playlist) => playlist['playlist_name']));
    } else {
      // Failed to retrieve existing playlists
      print('Failed to retrieve existing playlists.');
      return [];
    }
  }

  Future<String?> _getPlaylistNameFromUser() async {
    TextEditingController playlistNameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambahkan Ke Playlist'),
          content: TextField(
            controller: playlistNameController,
            decoration: InputDecoration(labelText: 'Nama Playlist'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(
                  context, null), // Dismiss dialog with null result
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                String playlistName = playlistNameController.text.trim();
                Navigator.pop(
                    context, playlistName.isNotEmpty ? playlistName : null);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showPlaylistSelectionDialog(
      List<String> existingPlaylists) async {
    // If there are no existing playlists, default to showing the new playlist input
    if (existingPlaylists.isEmpty) {
      return await _getPlaylistNameFromUser(); // Await the result here
    }

    // Show a dialog with existing playlists as options
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Playlist'),
          content: Column(
            children: [
              for (String playlist in existingPlaylists)
                ListTile(
                  title: Text(playlist),
                  onTap: () => Navigator.pop(context, playlist),
                ),
              Divider(),
              ListTile(
                title: Text('Buat Playlist Baru'),
                onTap: () async {
                  String? newPlaylist = await _getPlaylistNameFromUser();
                  Navigator.pop(context, newPlaylist);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteFile(FileSystemEntity file) {
    file.delete();
    _loadLocalFiles();
  }
}

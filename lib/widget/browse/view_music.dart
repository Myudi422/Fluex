import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ViewMusicPage extends StatefulWidget {
  final String videoTitle;
  final String videoThumbnailUrl;
  final String videoUrl;
  final Function(bool) onPlaybackStateChanged;

  ViewMusicPage({
    required this.videoTitle,
    required this.videoThumbnailUrl,
    required this.videoUrl,
    required this.onPlaybackStateChanged,
  });

  @override
  _ViewMusicPageState createState() => _ViewMusicPageState();
}

class _ViewMusicPageState extends State<ViewMusicPage> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration? _duration;
  Duration _position = Duration();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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
          setState(() {
            isPlaying = false;
          });
        }
      });

    _loadAndPlayAudio();
  }

  Future<void> _loadAndPlayAudio() async {
    try {
      String streamUrl = await getVideoStreamUrl(widget.videoUrl);
      await _audioPlayer.setUrl(streamUrl);
      await _audioPlayer.load();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading audio: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> playPauseAudio() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    setState(() {
      isPlaying = _audioPlayer.playing;
    });
    widget.onPlaybackStateChanged(isPlaying);
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      isPlaying = false;
    });
    widget.onPlaybackStateChanged(isPlaying);
  }

  Future<String> getVideoStreamUrl(String videoId) async {
    final yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(videoId);
    var streamInfo = manifest.audioOnly.first;
    yt.close();
    return streamInfo.url.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Now Playing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    widget.videoThumbnailUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                widget.videoTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              if (isLoading)
                CircularProgressIndicator()
              else
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: FaIcon(
                            isPlaying
                                ? FontAwesomeIcons.pause
                                : FontAwesomeIcons.play,
                          ),
                          onPressed: playPauseAudio,
                        ),
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.stop),
                          onPressed: stopAudio,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (_duration != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} - ${_duration!.inMinutes}:${(_duration!.inSeconds % 60).toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    if (_duration != null)
                      Slider(
                        value: _position.inMilliseconds.toDouble(),
                        min: 0.0,
                        max: _duration!.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

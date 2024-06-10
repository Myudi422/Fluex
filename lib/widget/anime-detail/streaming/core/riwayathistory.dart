// riwayathistory.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // Import VideoPlayerController
import 'convertdurasi.dart';

class RiwayatDurasiWidget extends StatelessWidget {
  final String videoTime;
  final VideoPlayerController videoPlayerController;

  RiwayatDurasiWidget({
    required this.videoTime,
    required this.videoPlayerController,
  });

  @override
  Widget build(BuildContext context) {
    return videoTime.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Durasi: ${convertDuration(videoTime)} / ${convertDuration(videoPlayerController.value.duration?.inSeconds.toString())}',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          )
        : SizedBox.shrink();
  }
}

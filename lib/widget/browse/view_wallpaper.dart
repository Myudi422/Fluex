import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ViewWallpaperPage extends StatelessWidget {
  final String imageUrl;

  ViewWallpaperPage({required this.imageUrl});

  Future<String> _downloadFile(String url, String fileName) async {
    final directory = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download') // Folder Unduhan di Android
        : await getApplicationDocumentsDirectory(); // Direktori aplikasi di iOS (perlu import 'package:path_provider/path_provider.dart')

    final filePath = '${directory.path}/$fileName';

    await FlutterDownloader.enqueue(
      url: url,
      savedDir: directory.path,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    );

    return filePath;
  }

  Future<void> _openFileManager() async {
    final directory = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download') // Folder Unduhan di Android
        : await getApplicationDocumentsDirectory(); // Direktori aplikasi di iOS (perlu import 'package:path_provider/path_provider.dart')

    OpenFile.open(directory.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Wallpaper'),
        actions: [
          IconButton(
            icon: Icon(Icons.folder),
            onPressed: _openFileManager,
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        itemCount: 1,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        scrollPhysics: BouncingScrollPhysics(),
        backgroundDecoration: BoxDecoration(
          color: Colors.black,
        ),
        pageController: PageController(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final fileName = imageUrl.split('/').last;
          await _downloadFile(imageUrl, fileName);
        },
        tooltip: 'Download Wallpaper',
        child: Icon(Icons.download),
      ),
    );
  }
}

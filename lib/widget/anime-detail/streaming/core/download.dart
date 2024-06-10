import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flue/color.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flue/admob/unity.dart';

class DownloadPage extends StatefulWidget {
  final Map<String, dynamic> animeData;
  final int episodeNumber;
  final String videoUrl;
  final int animeId;
  final Widget dropdown; // Pass the DropdownButton widget

  DownloadPage({
    required this.animeData,
    required this.videoUrl,
    required this.episodeNumber,
    required this.animeId,
    required this.dropdown,
  });

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  bool isDownloading = false;
  late Future<Map<String, dynamic>> animeDetails;

  @override
  void initState() {
    super.initState();
    animeDetails = fetchAnimeDetails(widget.animeId);
    UnityAdManager.initialize(); // Initialize Unity Ads
  }

  Future<Map<String, dynamic>> fetchAnimeDetails(int animeId) async {
    final response = await http.get(Uri.parse('https://ccgnimex.my.id/v2/android/detail_anime.php?anime_id=$animeId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load anime details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildButton(FontAwesomeIcons.download, 'Unduh', context),
              SizedBox(width: 8.0),
              Expanded(
                child: widget.dropdown,
              ),
              SizedBox(width: 8.0),
              _buildButton(FontAwesomeIcons.flagCheckered, 'Lapor', context),
            ],
          ),
        ),
        SizedBox(height: 16.0),
        FutureBuilder<Map<String, dynamic>>(
          future: animeDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              String sinopsis = snapshot.data!['sinopsis'];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: ColorManager.currentPrimaryColor,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Sinopsis:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorManager.currentHomeColor,
                          ),
                        ),
                        iconColor: ColorManager.currentHomeColor,
                        collapsedIconColor: ColorManager.currentHomeColor,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: ColorManager.currentAccentColor,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              sinopsis,
                              style: TextStyle(
                                fontSize: 16,
                                color: ColorManager.currentHomeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildButton(IconData iconData, String label, BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorManager.currentPrimaryColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Builder(
          builder: (context) => TextButton.icon(
            onPressed: () {
              if (label == 'Unduh') {
                _showDownloadConfirmationDialog(context);
              } else if (label == 'Lapor') {
                _showReportPopup(context);
              } else {
                // Handle logic for other buttons
              }
            },
            icon: Icon(
              iconData,
              color: Colors.white,
            ),
            label: Text(
              label,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            style: ButtonStyle(
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.all(8.0),
              ),
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }

  void _showDownloadConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 50.0,
              ),
              SizedBox(height: 16.0),
              Text(
                'Anda Yakin Ingin Mengunduh Berkas Ini?',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.0),
              Text(
                '(Download berkas, kemungkinan ada iklan, jadi mohon pengertiannya agar server aplikasi tetap berjalan terus)',
                style: TextStyle(
                  fontSize: 14.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Tidak',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showInterstitialAdOrDownload(context);
                UnityAdManager.loadInterstitialAd(); // Load the interstitial ad
              },
              child: Text(
                'Lihat Iklan',
                style: TextStyle(
                  color: ColorManager.currentPrimaryColor,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReportPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lapor Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih alasan laporan:',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              SizedBox(height: 8.0),
              _buildCheckbox('Konten tidak pantas'),
              _buildCheckbox('Pelanggaran hak cipta'),
              _buildCheckbox('Lainnya'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Batal',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Handle report logic here
                Navigator.of(context).pop();
              },
              child: Text(
                'Kirim Laporan',
                style: TextStyle(
                  color: ColorManager.currentPrimaryColor,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckbox(String label) {
    bool isChecked = false;

    return Row(
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (value) {
            setState(() {
              isChecked = value!;
            });
          },
        ),
        Text(label),
      ],
    );
  }

void _showInterstitialAdOrDownload(BuildContext context) {
  UnityAdManager.showInterstitialAd(
    onComplete: (String placementId) { // Add the expected String parameter
      _startDownload(context);
    },
    onFailed: (String placementId, dynamic error, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unity Ads failed to show: $error - $message. Continuing with download.'),
        ),
      );
      _startDownload(context);
    },
  );
}


  void _requestPermissionsAndDownload(BuildContext context) async {
    var status = await Permission.storage.status;

    if (status.isGranted) {
      _startDownload(context);
    } else if (status.isDenied) {
      // Jika izin ditolak, minta izin kembali
      await Permission.storage.request();
    } else if (status.isPermanentlyDenied) {
      // Jika izin secara permanen ditolak, tampilkan pesan untuk membuka pengaturan
      openAppSettings();
    }
  }

  void _startDownload(BuildContext context) async {
    try {
      // Cek apakah sedang dalam proses unduhan
      if (isDownloading) {
        return;
      }

      // Tandai bahwa sedang dalam proses unduhan
      setState(() {
        isDownloading = true;
      });

      // Pengecekan koneksi internet
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        _showErrorDialog(context, 'No internet connection');
        // Reset status unduhan
        setState(() {
          isDownloading = false;
        });
        return;
      }

      // Pengecekan validitas URL
      Uri uri = Uri.parse(widget.videoUrl);
      if (!uri.isAbsolute || !uri.hasScheme || !uri.hasAuthority) {
        _showErrorDialog(context, 'Invalid video URL');
        // Reset status unduhan
        setState(() {
          isDownloading = false;
        });
        return;
      }

      // Tentukan path penyimpanan
      String downloadPath = '/storage/emulated/0/Download';

      // Buat direktori "Download" jika belum ada
      Directory downloadDir = Directory(downloadPath);
      if (!downloadDir.existsSync()) {
        downloadDir.createSync(recursive: true);
      }

      // Mulai unduhan dengan menggunakan path penyimpanan
      final taskId = await FlutterDownloader.enqueue(
        url: widget.videoUrl,
        savedDir: downloadPath,
        fileName: 'Flue - ${widget.animeData['title']['romaji']} - Episode_${widget.episodeNumber.toString()}.mp4',
        showNotification: true,
        openFileFromNotification: true,
        requiresStorageNotLow: true,
      );

      print('Download task id: $taskId');
    } catch (error) {
      print('Download failed: $error');
      _showErrorDialog(context, 'Download failed: $error');
    } finally {
      // Reset status unduhan setelah selesai
      setState(() {
        isDownloading = false;
      });
    }
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

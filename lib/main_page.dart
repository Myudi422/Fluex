import 'package:flutter/material.dart';
import 'browse_page.dart';
import 'bookmark_page.dart';
import 'chat.dart';
import 'history_page.dart';
import 'jadwal_page.dart';
import 'background.dart';
import 'widget/profile.dart';
import 'widget/ongoing.dart';
import 'widget/ongoing.title.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_google.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flue/color.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widget/slider.dart';
import 'premium.dart';
import 'package:flutter/services.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String email = '';
  String firstName = '';
  String profilePicture = '';
  String telegramId = '';
  String akses = '';
  String expired = '';
  bool _isRefreshing = false;
  late PageController _pageController;
  int _currentIndex = 0;
  late FirebaseMessaging _firebaseMessaging;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _firebaseMessaging = FirebaseMessaging.instance;

    // Panggil method untuk mengambil FCM token
    _getFCMToken();
    _refreshData();
    // Meminta izin notifikasi saat halaman utama dimuat
    _requestNotificationPermission();

    // Meminta izin akses file saat halaman utama dimuat
    _requestFileAccessPermission();
  }

  // Method untuk meminta izin notifikasi
  Future<void> _requestNotificationPermission() async {
    // Memeriksa apakah izin notifikasi telah diberikan sebelumnya
    PermissionStatus permissionStatus = await Permission.notification.status;

    // Jika izin belum diberikan, maka minta izin
    if (permissionStatus != PermissionStatus.granted) {
      permissionStatus = await Permission.notification.request();
    }
  }

  Future<void> _requestFileAccessPermission() async {
    // Memeriksa apakah izin akses file telah diberikan sebelumnya
    PermissionStatus permissionStatus = await Permission.storage.status;

    // Jika izin belum diberikan, maka minta izin
    if (permissionStatus != PermissionStatus.granted) {
      permissionStatus = await Permission.storage.request();
    }
  }

  // Method untuk mengambil FCM token
  Future<void> _getFCMToken() async {
    String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      // Kirim FCM token ke server
      await _sendFCMTokenToServer(fcmToken);
    }
  }

  // Method untuk mengirim FCM token ke server
  Future<void> _sendFCMTokenToServer(String token) async {
    final String apiUrl = 'https://ccgnimex.my.id/v2/android/chat/fcm.php';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'email': email,
          'fcm_token': token,
        },
      );

      if (response.statusCode == 200) {
        // Berhasil mengirim FCM token ke server
      } else {
        print('Error ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? '';
    await _getUserData();

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _getUserData() async {
    final String apiUrl = 'https://ccgnimex.my.id/v2/android/api_user.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'email': email,
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          setState(() {
            firstName = responseData['first_name'];
            telegramId = responseData['telegram_id'];
            akses = responseData['akses'];

            // Assign the value from response to expired, with default value "Belum-langganan" if null
            expired = responseData['expired'] ?? 'Belum-langganan';

            // Handle the profile picture URL
            String pathOrUrl = responseData['profile_picture'] ?? '';
            if (pathOrUrl.isNotEmpty && !pathOrUrl.startsWith('http')) {
              pathOrUrl = 'https://ccgnimex.my.id/v2/$pathOrUrl';
            }
            profilePicture = pathOrUrl.isNotEmpty ? pathOrUrl : 'img/logo.png';
          });
        } else if (responseData['status'] == 'banned') {
          _showBannedPopup();
        } else {
          print('Error: ${responseData['message']}');
        }
      } else {
        print('Error ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showBannedPopup() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Membuat popup tidak bisa ditutup dengan klik di luar
      builder: (context) => AlertDialog(
        title: Text('Pemberitahuan'),
        content: Text('Anda sudah diblokir, harap pahami itu.'),
        actions: [
          TextButton(
            onPressed: () {
              SystemNavigator.pop(); // Keluar dari aplikasi
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          // Halaman Main
          _buildMainPage(),
          // Halaman Jadwal
          _buildJadwalPage(),
          // Halaman Browse
          _buildBrowsePage(),
          // Halaman History
          _buildRiwayatPage(),
          // Halaman Bookmark
          _buildChatRoomPage(),
        ],
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: ColorManager.currentPrimaryColor, // Warna stroke putih
                  width: 2.0, // Lebar stroke
                ),
              ),
            ),
          ),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: ColorManager.currentPrimaryColor,
            unselectedItemColor: ColorManager.currentHomeColor,
            backgroundColor: ColorManager.currentBackgroundColor,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Beranda",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.date_range),
                label: "Jadwal",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dataset),
                label: "Browse",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: "Riwayat",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: "Chat",
              ),
            ],
            onTap: (index) {
              _pageController.jumpToPage(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainPage() {
    return Stack(
      children: [
        BackgroundWidget(),
        RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16.0),
                  margin: EdgeInsets.only(bottom: 1.0),
                  child: ProfileInfoWidget(
                    firstName: firstName,
                    profilePicture: profilePicture,
                    telegramId: telegramId,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: PremiumWidget(
                    telegramId: telegramId,
                  ),
                ),
                OngoingTitleWidget(telegramId: telegramId),
                OngoingAnimeWidget(
                  firstName: firstName,
                  profilePicture: profilePicture,
                  telegramId: telegramId,
                ),
              ],
            ),
          ),
        ),
        // Loading indicator while refreshing
        if (_isRefreshing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildJadwalPage() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: JadwalPage(telegramId: telegramId),
    );
  }

  Widget _buildBrowsePage() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: BrowsePage(
        telegramId: telegramId,
        key: PageStorageKey<String>('browse_page'),
      ),
    );
  }

  Widget _buildRiwayatPage() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: RiwayatPage(telegramId: telegramId),
    );
  }

  Widget _buildChatRoomPage() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ChatRoomPage(
        firstName: firstName,
        profilePicture: profilePicture,
        premiumStatus: akses,
        telegramId: telegramId,
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _refreshData();
  }
}

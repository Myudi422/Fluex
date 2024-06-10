import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'profile-menu.dart';
import 'cari.dart';
import 'package:intl/intl.dart';
import 'package:flue/color.dart';
import 'package:flue/widget/profile-menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


Future<Map<String, dynamic>> fetchAkses(int telegramId) async {
  final apiUrl = 'https://ccgnimex.my.id/v2/android/cek_akses.php?telegram_id=$telegramId';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load akses data');
    }
  } catch (error) {
    throw Exception('Error');
  }
}




Future<List<Map<String, dynamic>>> fetchNotifications() async {
  final response = await http.get(Uri.parse('https://ccgnimex.my.id/v2/android/notif.php')); // Ganti URL sesuai dengan URL API.php Anda
  if (response.statusCode == 200) {
    // Jika request sukses
    List<dynamic> data = json.decode(response.body);
    // Mengembalikan daftar notifikasi dalam bentuk List<Map<String, dynamic>>
    return List<Map<String, dynamic>>.from(data);
  } else {
    // Jika request gagal
    throw Exception('Failed to load notifications');
  }
}

Future<List<Map<String, dynamic>>> fetchLeaderboard(int telegramId) async {
  final apiUrl = 'https://ccgnimex.my.id/v2/android/leaderboard/api.php?telegram_id=$telegramId';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load leaderboard data');
    }
  } catch (error) {
    throw Exception('Error: $error');
  }
}

class BlurredIcon extends StatelessWidget {
  final IconData icon;
  final Function()? onPressed;

  BlurredIcon({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 12.0), // Jarak antara kedua ikon
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            padding: EdgeInsets.all(1.0),
            child: IconButton(
              icon: Icon(icon, color: Colors.white),
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileInfoWidget extends StatelessWidget {
  final String firstName;
  final String profilePicture;
  final String telegramId;

  ProfileInfoWidget({
    required this.firstName,
    required this.profilePicture,
    required this.telegramId,
  });

  @override
Widget build(BuildContext context) {
  String finalProfilePicture = profilePicture.isNotEmpty
    ? _constructProfilePictureUrl(profilePicture)
    : 'img/logo.png';


String shortName = firstName.length > 10
    ? '${firstName.substring(0, 10)}..' 
    : firstName;


  // Get the current time
  DateTime now = DateTime.now();
  String greeting = _getGreeting(now);

  return Container(
    padding: EdgeInsets.only(top: 20.0, left: 10.0, right: 10.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to the ProfileMenu page when the CircleAvatar is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileMenu(
                      firstName: firstName,
                      profilePicture: profilePicture,
                      telegramId: telegramId,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 30.0,
                backgroundImage: NetworkImage(finalProfilePicture),
              ),
            ),
            SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(fontSize: 12.0, color: Colors.white),
                ),
                Text(
                  shortName,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
  decoration: BoxDecoration(
    color: ColorManager.currentPrimaryColor,
    borderRadius: BorderRadius.circular(5.0),
  ),
  padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 2.0),
  child: FutureBuilder<Map<String, dynamic>>(
  future: fetchAkses(int.tryParse(telegramId) ?? 0),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    } else {
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else {
        // Ambil nilai akses dari respons API
        String? akses = snapshot.data!['akses'] as String?;

        return Text(
          akses ?? '',
          style: TextStyle(
            fontSize: 8.0,
            fontWeight: FontWeight.normal,
            color: ColorManager.currentHomeColor,
          ),
);

        }
      }
    },
  ),
),

                    SizedBox(width: 4.0), // Adjust the spacing as needed
                    FutureBuilder(
  future: fetchLeaderboard(int.tryParse(telegramId) ?? 0),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Container();
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
      return Text('No data available');
    } else {
      final totalPoints = snapshot.data?[0]['total_points'] ?? 0;
      return Container(
        decoration: BoxDecoration(
          color: ColorManager.currentPrimaryColor,
          borderRadius: BorderRadius.circular(5.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 2.0),
        child: Text(
          'Point: $totalPoints',
          style: TextStyle(
            fontSize: 8.0,
            fontWeight: FontWeight.normal,
            color: ColorManager.currentHomeColor,
          ),
        ),
      );
    }
  },
),

                  ],
                ),
              ],
            ),
          ],
        ),

Align(
  alignment: Alignment.center,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      // Icon notifikasi dengan blur glass
          Stack(
      children: [
        BlurredIcon(
          icon: CupertinoIcons.bell,
          onPressed: () async {
            // Mengambil data notifikasi dari API
            List<Map<String, dynamic>> notifications = await fetchNotifications();

            // Aksi yang ingin diambil saat tombol notifikasi ditekan
            showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: Text('Info Terbaru!'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemCount: notifications.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      ListTile(
                        title: Text(notifications[index]['title']),
                        subtitle: Text(notifications[index]['content']),
                        // Tambahkan timestamp sesuai kebutuhan
                      ),
                      Divider(
                        color: Colors.grey,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.telegram), // Ikon Telegram dari Font Awesome
                  onPressed: () {
                    // Aksi yang diambil saat tombol Telegram ditekan
                    // Buka URL ke t.me/otakuindonew
                    launch('https://t.me/otakuindonew');
                  },
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.instagram), // Ikon Instagram dari Font Awesome
                  onPressed: () {
                    // Aksi yang diambil saat tombol Instagram ditekan
                    // Buka URL ke instagram.com/flue
                    launch('https://instagram.com/flue_app');
                  },
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup popup
              },
              child: Text('Tutup'),
            ),
          ],
        ),
      ],
    );
  },
);

          },
        ),
        Positioned(
          top: 0,
          right: 8,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red, // Warna dot merah
            ),
            child: Text(
              'Info',
              style: TextStyle(
                color: Colors.white,
                fontSize: 6,
              ),
            ),
          ),
        ),
      ],
    ),
      // Icon pencarian dengan blur glass
      BlurredIcon(
        icon: CupertinoIcons.search,
        onPressed: () {
          // Navigasi ke halaman pencarian saat tombol pencarian ditekan
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CariPage(telegramId: telegramId)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _constructProfilePictureUrl(String pathOrUrl) {
    if (!pathOrUrl.startsWith('http')) {
      pathOrUrl = 'https://ccgnimex.my.id/v2/$pathOrUrl';
    }

    return pathOrUrl;
  }

  String _getGreeting(DateTime now) {
    if (now.hour < 12) {
      return 'Selamat Pagi,';
    } else if (now.hour < 18) {
      return 'Selamat Siang,';
    } else {
      return 'Selamat Malam,';
    }
  }
}
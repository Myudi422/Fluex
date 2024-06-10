import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../welcome.dart';
import '../login_page.dart';
import 'package:flue/color.dart';
import 'package:flue/widget/profile.dart';
import 'package:flue/widget/settings/notifikasi.dart';
import 'package:url_launcher/url_launcher.dart';
import 'beli.dart';
import '../main_page.dart';

class ProfileMenu extends StatelessWidget {
  final String firstName;
  final String profilePicture;
  final String telegramId;

  ProfileMenu({
    required this.firstName,
    required this.profilePicture,
    required this.telegramId,
  });

  Future<void> _logout(BuildContext context) async {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    await _firebaseMessaging.deleteToken();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _showNotificationOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => NotificationOverlay(
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                image: DecorationImage(
                  image: AssetImage(profilePicture),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.7),
                    BlendMode.dstATop,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  CircleAvatar(
                    backgroundImage: AssetImage(profilePicture),
                    radius: 50.0,
                  ),
                  SizedBox(height: 20),
                  Text(
                    firstName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.currentHomeColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                        ),
                        builder: (context) => SubscriptionPage(
                          telegramId: telegramId,
                        ),
                      );
                    },
                    child: Text('Kelola Langganan Saya'),
                    style: ElevatedButton.styleFrom(
                      primary: ColorManager.currentHomeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    _launchURL('https://www.instagram.com/flue_app');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.facebook),
                  onPressed: () {
                    _launchURL('https://www.facebook.com/ccgnimex');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.telegram),
                  onPressed: () {
                    _launchURL('https://t.me/otakuindonew');
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('Notifikasi'),
                    onTap: () {
                      _showNotificationOverlay(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.extension),
                    title: Text('Plugin Manager'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ColorPickerWidget()),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}


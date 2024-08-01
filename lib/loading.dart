import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'login_page.dart';
import 'welcome.dart';
import 'dart:io';
import 'main_page.dart'; // Import MainPage

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    checkConnectionAndShowDialog(context);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);

    // Check app version and user login status before navigating
    checkAppVersion();
  }

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> checkConnectionAndShowDialog(BuildContext context) async {
    bool isConnected = await _checkInternetConnection();

    if (!isConnected) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false, // Disable back button
            child: AlertDialog(
              title: Text("Tidak Terhubung dengan Internet"),
              content: Text("Mohon periksa koneksi internet Anda."),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    exit(0); // Exit the app
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> checkAppVersion() async {
    try {
      bool isConnected = await _checkInternetConnection();

      if (!isConnected) {
        // Show dialog for no internet connection
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Tidak Terhubung dengan Internet"),
              content: Text("Mohon periksa koneksi internet Anda."),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Optionally, you can exit the app or perform other actions
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }

      // Fetch the current app version from the server
      final response = await http.get(
          Uri.parse('https://ccgnimex.my.id/v2/android/check_version.php'));

      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("Parsed data: $data");

        final String latestVersion = data['latest_version'];
        final String changelog = data['changelog']; // Added changelog
        final bool updateRequired =
            data['update_required']; // Added updateRequired

        print("Latest version from server: $latestVersion");

        final String currentVersion =
            '1.3.1'; // Replace with your actual app version
        print("Current app version: $currentVersion");

        if (updateRequired && currentVersion != latestVersion) {
          // Show a dialog prompting the user to update the app with changelog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.download), // Icon download
                    SizedBox(width: 10), // Add some space between icon and text
                    Text("Update!"),
                  ],
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      "Perubahan:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Container(
                      width: double.maxFinite,
                      height: 100, // Set the height as per your requirement
                      child: SingleChildScrollView(
                        child: Text(
                          changelog,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () async {
                      // Open the URL in the default browser or appropriate app
                      await _launchURL('https://apk.ccgnimex.my.id');
                    },
                    child: Text("Update"),
                  ),
                ],
              );
            },
          );
        } else {
          // Check if the user is already logged in
          SharedPreferences prefs = await SharedPreferences.getInstance();
          bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

          if (isLoggedIn) {
            // If user is logged in, navigate to MainPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(),
              ),
            );
          } else {
            // Check if it's the first launch
            bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

            if (isFirstLaunch) {
              // If it's the first launch, navigate to WelcomePage
              await prefs.setBool('isFirstLaunch', false); // Update the flag
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            } else {
              // If it's not the first launch, navigate to LoginPage
              Future.delayed(Duration(seconds: 3), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              });
            }
          }
        }
      } else {
        // Handle error if unable to fetch version data
        print(
            "Error fetching version data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception while checking app version: $e");
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            'img/app.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'img/logo.png',
                height: 200,
                width: 200,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

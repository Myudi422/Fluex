import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_page.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginGoogleWidget extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount == null) {
        // Handle login cancellation
        return;
      }

      final UserCredential authResult =
          await _authenticateUser(googleSignInAccount);

      if (authResult.user != null) {
        await _processUserData(authResult.user, context);
      } else {
        // Handle login failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login gagal'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error, stackTrace) {
      // Handle general login errors
      print("Error during sign-in: $error\n$stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login gagal: $error'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<UserCredential> _authenticateUser(GoogleSignInAccount account) async {
    final GoogleSignInAuthentication authentication =
        await account.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: authentication.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> _processUserData(User? user, BuildContext context) async {
    if (user != null && user.email != null && user.email!.isNotEmpty) {
      print("Email dikirim: ${user.email}");

      await _sendUserDataToDatabase(user);
      await _getUserDataFromDatabase(user, context);

      // Setel tanda bahwa pengguna sudah login
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);

      // Arahkan ke MainPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email pengguna hilang atau tidak valid'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendUserDataToDatabase(User user) async {
    final apiUrl = 'https://ccgnimex.my.id/v2/android/api_google.php';
    try {
      // Mengonversi user.uid menjadi integer
      final int telegramId = user.uid.hashCode;

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'telegram_id': telegramId.toString(),
          'profile_picture': user.photoURL ?? '',
          'first_name': user.displayName ?? '',
          'email': user.email ?? '',
        },
      );

      print("API Response (Send to Database): ${response.body}");

      if (response.statusCode == 200) {
        try {
          final dynamic responseData = json.decode(response.body);

          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('status')) {
            if (responseData['status'] == 'success') {
              print("User data sent to database successfully");
            } else {
              print(
                  "Failed to send user data to database. Message: ${responseData['message']}");
            }
          } else {
            print("Unexpected response format from server");
          }
        } catch (e) {
          print("Error parsing response from server: $e");
        }
      } else {
        print(
            "Failed to send user data to database. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending user data to database: $e");
    }
  }

  Future<void> _getUserDataFromDatabase(User user, BuildContext context) async {
    final apiUrl = 'https://ccgnimex.my.id/v2/android/api_user.php';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'email': user.email!,
          // Add any other parameters needed for user identification
        },
      );

      print("API Response (Get from Database): ${response.body}");

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          if (responseData['status'] == 'success') {
            // Save user email in SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('email', user.email!);

            // Use data from the database as needed
            final userData = responseData; // Directly access the top-level data
            print("User data from database: $userData");

            // Update the UI with user data (e.g., navigate to the main page)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(),
              ),
            );
          } else {
            print(
                "Failed to get user data from database. Message: ${responseData['message']}");
          }
        } catch (e) {
          print("Error parsing user data from database: $e");
        }
      } else {
        print(
            "Failed to get user data from database. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error getting user data from database: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            await _loginWithGoogle(context);
          },
          icon: FaIcon(
            FontAwesomeIcons.google,
            color: Colors.white, // Warna ikon
          ),
          label: Text(
            'Login dengan Google',
            style: TextStyle(
              color: Colors.white, // Warna teks
              fontSize: 16, // Ukuran teks
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Warna latar belakang tombol
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Bentuk tepi tombol
            ),
          ),
        ),
      ],
    );
  }
}

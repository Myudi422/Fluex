// login_email.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_page.dart';
import 'create.dart';

class LoginEmailWidget extends StatefulWidget {
  @override
  _LoginEmailWidgetState createState() => _LoginEmailWidgetState();
}

class _LoginEmailWidgetState extends State<LoginEmailWidget> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> _login() async {
  final String apiUrl = 'https://ccgnimex.my.id/v2/android/api_login.php';

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'email': emailController.text,
        'password': passwordController.text,
      },
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      if (responseData['status'] == 'success') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLoggedIn', true);
        prefs.setString('email', emailController.text);
        prefs.setString('firstName', responseData['first_name']);
        prefs.setString('telegram_id', responseData['telegram_id']);

        // Navigate to MainPage and remove the welcome page from the navigation stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
        setState(() {
          errorMessage = 'Email atau password salah.';
        });
        await _logout();
      }
    } else {
      print('Error ${response.statusCode}');
      setState(() {
        errorMessage = 'Terjadi kesalahan pada server.';
      });
    }
  } catch (e) {
    print('Error: $e');
    setState(() {
      errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
    });
  }
}

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }


@override
Widget build(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TextField(
        controller: emailController,
        style: TextStyle(color: Color(0xFFD9DADE)),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(color: Color(0xFFD9DADE)),
        ),
      ),
      SizedBox(height: 16),
      TextField(
        controller: passwordController,
        obscureText: true,
        style: TextStyle(color: Color(0xFFD9DADE)),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(color: Color(0xFFD9DADE)),
        ),
      ),
      SizedBox(height: 8),
      if (errorMessage.isNotEmpty)
        Text(
          errorMessage,
          style: TextStyle(color: Colors.red),
        ),
      SizedBox(height: 24),
      ElevatedButton(
        onPressed: _login,
        child: Text('Login'),
      ),
      SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 8),
        ],
      ),
    ],
  );
}
}

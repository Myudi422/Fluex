// login_page.dart
import 'package:flutter/material.dart';
import 'create.dart';
import 'login_all.dart'; // Import the custom Firebase initialization service

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Container(
        color: Color(0xFF1C2431),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LoginAll(),
        ),
      ),
    );
  }
}

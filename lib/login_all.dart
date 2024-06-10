// login_all.dart
import 'package:flutter/material.dart';
import 'login_email.dart';
import 'login_google.dart';

class LoginAll extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoginEmailWidget(),
          SizedBox(height: 16), // Menambahkan jarak vertikal sebesar 16
          LoginGoogleWidget(), // Tambahkan widget login Google di sini
        ],
      ),
    );
  }
}

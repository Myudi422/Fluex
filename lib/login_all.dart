import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Tambahkan impor untuk dart:convert
import 'login_email.dart';
import 'login_google.dart';

class LoginAll extends StatefulWidget {
  @override
  _LoginAllState createState() => _LoginAllState();
}

class _LoginAllState extends State<LoginAll> {
  bool agreeTerms = false;
  String termsAndConditions = '';

  // Method to fetch terms and conditions from PHP endpoint
  Future<void> fetchTermsAndConditions() async {
    final response =
        await http.get(Uri.parse('https://ccgnimex.my.id/v2/android/snk.php'));

    if (response.statusCode == 200) {
      setState(() {
        termsAndConditions = json.decode(response.body)['terms'];
      });
    } else {
      throw Exception('Failed to load terms and conditions');
    }
  }

  // Method to show the terms and conditions popup
  void showTermsAndConditionsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Syarat & Ketentuan'),
          content: SingleChildScrollView(
            child: Text(termsAndConditions),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchTermsAndConditions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'img/app.jpg', // Make sure the image path is correct
              fit: BoxFit.cover,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20),
                    IgnorePointer(
                      ignoring: !agreeTerms,
                      child: Opacity(
                        opacity: agreeTerms ? 1.0 : 0.5,
                        child: LoginGoogleWidget(),
                      ),
                    ),
                    SizedBox(height: 5),
                    IgnorePointer(
                      ignoring: !agreeTerms,
                      child: Opacity(
                        opacity: agreeTerms ? 1.0 : 0.5,
                        child: LoginEmailWidget(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: agreeTerms,
                          onChanged: (bool? value) {
                            setState(() {
                              agreeTerms = value ?? false;
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            showTermsAndConditionsPopup(
                                context); // Call method to show popup
                          },
                          child: Text(
                            'Saya Setuju, Syarat & Ketentuan Aplikasi',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

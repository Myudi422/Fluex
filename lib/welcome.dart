import 'package:flutter/material.dart';
import 'login_page.dart';
import 'main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flue/color.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
  }


  Future<void> showPrivacyDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Privacy Policy & Disclaimer'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                   Text(
                'Privacy Policy: Unofficial Streaming Application\n\n'
                'This Privacy Policy outlines how personal information is collected, used, and managed when you use this unofficial streaming application. Please read this policy carefully to understand our practices regarding your data and how we handle it.\n\n'
                '1. Information Collection:\n'
                'We do not collect any personally identifiable information (PII) from users of this application. The application solely provides access to publicly available links on the internet, and no user data is stored on our servers.\n\n'
                '2. Usage of Information:\n'
                'As no personal information is collected, there is no usage of such information for any purpose. The application focuses on delivering streaming content without accessing or storing user data.\n\n'
                '3. Third-Party Links:\n'
                'This application may contain links to external websites or content from social media platforms. We are not responsible for the privacy practices or content of these third-party sites. Users are encouraged to review the privacy policies of external websites they visit through the application.\n\n'
                '4. Security:\n'
                'While we strive to protect any non-personal information, users should be aware that the transmission of data over the internet is not completely secure. We cannot guarantee the security of information transmitted through the application.\n\n'
                '5. Changes to the Privacy Policy:\n'
                'This Privacy Policy may be updated periodically. Users are advised to review this page for any changes. By continuing to use the application after modifications to this policy, users are considered to have accepted the changes.\n\n'
                'Contact Information:\n'
                'For any questions or concerns regarding this Privacy Policy or the application\'s practices, please contact us at ccgnimex@gmail.com.\n\n'
                'By using this application, you agree to the terms outlined in this Privacy Policy. If you do not agree with these terms, please refrain from using the application.\n\n'
                'Thank you for your attention and understanding.\n\n'
                'Disclaimer: Unofficial Streaming Application\n\n'
                'This application is an unofficial version and is not endorsed by official streaming service providers. The use of this application is entirely at the user\'s discretion and may lack official support.\n\n'
                'Please Note:\n\n'
                'This application is not affiliated with official streaming service providers.\n'
                'The use of this application may involve security risks or copyright violations.\n'
                'We are not responsible for legal infringements or losses that may arise from using this application.\n'
                'Any issues or questions related to this application can be reported to our email address at ccgnimex@gmail.com.\n\n'
                'Media Source Notice:\n\n'
                'All media content within this application is sourced from publicly available links on the internet, often originating from various social media platforms. We solely provide access to these links for user convenience.\n\n'
                'Report Issues:\n\n'
                'If you encounter technical issues or have questions, please report them to the email address above. Our team will strive to assist and respond promptly.\n\n'
                'Important:\n\n'
                'If you disagree with the terms and conditions above or wish to avoid potential legal risks, it is advised not to use this application. We recommend using official streaming service providers for a safer and more reliable experience.\n\n'
                'Thank you for your understanding and cooperation.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDisagree();
              },
              child: Text('Disagree'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleAgree();
              },
              child: Text('Agree'),
            ),
          ],
        );
      },
    );
  }

  void _handleAgree() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('privacyAgreed', true);
  }

  void _handleDisagree() {
    Fluttertoast.showToast(
      msg: 'Mohon Untuk Setuju, Untuk melanjutkan aplikasi.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: ColorManager.currentPrimaryColor,
      textColor: Colors.white,
    );
    // Show the privacy dialog again if the user disagrees
    Future.delayed(Duration(seconds: 3), () {
    });
  }

  @override
  Widget build(BuildContext context) {
    // No need to check login status in the build method
    // Just let the checkLoginStatus handle the navigation
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/app.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                ColorManager.currentPrimaryColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Image.asset(
                          'img/logo.png',
                          height: 80,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      'di flue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        // Navigasi ke halaman LoginPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        'Next',
                        style: TextStyle(
                          color: ColorManager.currentPrimaryColor,
                          fontSize: 18,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

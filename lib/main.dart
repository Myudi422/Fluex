import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'loading.dart';
import 'welcome.dart';
import 'firebase_options.dart';
import 'color.dart'; // Import file color.dart
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await loadColors(); // Load the saved color during app initialization

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    loadColors(); // Load the saved color during app initialization

    return MaterialApp(
      title: 'Flue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorManager.currentPrimaryColor),
        fontFamily: 'Satoshi',
      ),
      home: SplashScreen(),
    );
  }
}

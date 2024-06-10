import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flue/color.dart';

class BackgroundWidget extends StatefulWidget {
  @override
  _BackgroundWidgetState createState() => _BackgroundWidgetState();
}

class _BackgroundWidgetState extends State<BackgroundWidget> {
  String imageUrl = ''; // No default image URL
  final String imageUrlKey = 'image_url';

  @override
  void initState() {
    super.initState();
    // Load the last saved image URL from shared preferences
    loadLastImageUrl();
    // Fetch a new image from the API
    fetchImage();
  }

  Future<void> loadLastImageUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      imageUrl = prefs.getString(imageUrlKey) ?? '';
    });
  }

  Future<void> saveImageUrl(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(imageUrlKey, url);
  }

  Future<void> fetchImage() async {
    try {
      final response = await http.get(Uri.parse('https://ccgnimex.my.id/v2/android/api_wallpaper.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newImageUrl = data['image_url'];

        setState(() {
          imageUrl = newImageUrl;
        });

        // Save the new image URL in shared preferences
        saveImageUrl(newImageUrl);
      } else {
        // Handle error
        print('Failed to load image from API');
      }
    } catch (error) {
      // Handle error when there is no internet connection or other exceptions
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Container(
            color: Colors.black, // You can customize the color as needed
          ),
          fit: BoxFit.cover,
          height: MediaQuery.of(context).size.height * 1.25,
          width: double.infinity,
        ),
        // Gradient Overlay
        Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorManager.currentBackgroundColor.withOpacity(0.3),
                 ColorManager.currentBackgroundColor.withOpacity(0.5),
                 ColorManager.currentBackgroundColor.withOpacity(0.8),
                 ColorManager.currentBackgroundColor.withOpacity(1.0),
                 ColorManager.currentBackgroundColor.withOpacity(1.0),
                 ColorManager.currentBackgroundColor.withOpacity(1.0),
              ],
              stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Shadow
        Positioned(
          top: MediaQuery.of(context).size.height * 0.20,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.80,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

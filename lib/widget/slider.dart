import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'anime-detail.dart';
import 'profile-menu.dart'; // Import file ProfileMenu.dart

class SliderWidget extends StatefulWidget {
  final String? telegramId;
  final String? firstName;
  final String? profilePicture;

  SliderWidget({
    Key? key,
    this.telegramId,
    this.firstName,
    this.profilePicture,
  }) : super(key: key);

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  late Future<List<dynamic>> _sliderData;
  late String _resolvedTelegramId;

  @override
  void initState() {
    super.initState();
    _sliderData = _fetchSliderData();
    _resolvedTelegramId = widget.telegramId ?? '';
  }

  Future<List<dynamic>> _fetchSliderData() async {
    try {
      final response = await http
          .get(Uri.parse('https://ccgnimex.my.id/v2/android/slider.php'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load slider images');
      }
    } catch (error) {
      print('Error fetching slider data: $error');
      // Return empty list to prevent crashing the UI
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _sliderData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerSlider();
        } else {
          return CarouselSlider.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index, _) {
              final item = snapshot.data![index];
              return GestureDetector(
                onTap: () => _onTap(item),
                child: Container(
                  width: 400,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: item['image_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      // Apply borderRadius to CachedNetworkImage
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 100.0,
              viewportFraction: 0.8,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 3),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
            ),
          );
        }
      },
    );
  }

  Widget _buildShimmerSlider() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CarouselSlider.builder(
        itemCount: 5, // Number of placeholder items to display
        itemBuilder: (context, index, _) {
          return Container(
            width: 400,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
        options: CarouselOptions(
          height: 100.0,
          viewportFraction: 0.8,
          initialPage: 0,
          enableInfiniteScroll: true,
          reverse: false,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 3),
          autoPlayAnimationDuration: Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: true,
          scrollDirection: Axis.horizontal,
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _onTap(Map<String, dynamic> data) {
    if (data['link'] != null) {
      _launchURL(data['link']);
    } else if (data['page'] != null && data['page'] == 'AnimeDetailPage') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeDetailPage(
            animeId: int.parse(data['anime_id']),
            telegramId: _resolvedTelegramId,
          ),
        ),
      );
    } else if (data['page'] != null && data['page'] == 'ProfileMenu') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileMenu(
            firstName: widget.firstName!,
            profilePicture: widget.profilePicture!,
            telegramId: widget.telegramId!,
          ),
        ),
      );
    } else {
      // Handle other pages if needed
    }
  }
}

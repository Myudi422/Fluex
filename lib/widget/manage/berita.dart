import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'view.berita.dart';
import 'package:flue/color.dart';

class BeritaContent extends StatefulWidget {
  @override
  _BeritaContentState createState() => _BeritaContentState();
}

class _BeritaContentState extends State<BeritaContent> {
  List<Map<String, dynamic>> beritaList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('https://ccgnimex.my.id/v2/android/berita/api.php'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          beritaList = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _openNewsDetail(String link, String translatedTitle, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewBerita(
          link: 'https://ccgnimex.my.id/v2/android/berita/view.php?url=$link',
          translated_title: translatedTitle,
          imageUrl: imageUrl, // Pass the imageUrl to ViewBerita
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Container(
        decoration: BoxDecoration(
          color: ColorManager.currentPrimaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 12.0),
            _buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Update Berita',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: ColorManager.currentHomeColor,
          ),
        ),
        IconButton(
          icon:
              Icon(FontAwesomeIcons.sync, color: ColorManager.currentHomeColor),
          onPressed: () {
            _handleRefresh();
          },
        ),
      ],
    );
  }

  Widget _buildListView() {
    return beritaList.isNotEmpty
        ? _buildNewsListView()
        : _buildShimmerListView();
  }

  Widget _buildNewsListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: beritaList.length,
      itemBuilder: (context, index) {
        final berita = beritaList[index];
        return _buildNewsCard(berita);
      },
    );
  }

  Widget _buildShimmerListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _buildShimmerCard();
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> berita) {
    return Card(
      color: ColorManager
          .currentPrimaryColor, // Set card color to currentPrimaryColor
      margin: EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: () {
          _openNewsDetail(
            berita['link'],
            berita['translated_title'],
            berita['image'], // Pass the imageUrl to _openNewsDetail
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(berita['image']), // Display the image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildText(berita['translated_title']),
                    _buildText(berita['translated_summary'], fontSize: 12.0),
                    _buildDateAndIcon(berita['published']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 150.0,
          decoration: BoxDecoration(
            color: ColorManager.currentHomeColor,
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      width: 100.0,
      height: 100.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        image: DecorationImage(
          image: CachedNetworkImageProvider(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildText(String text, {double fontSize = 16.0}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: ColorManager.currentHomeColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDateAndIcon(String publishedDate) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            publishedDate,
            style: TextStyle(
              fontSize: 12.0,
              color: ColorManager.currentHomeColor,
            ),
          ),
          Icon(
            FontAwesomeIcons.newspaper,
            size: 16.0,
            color: ColorManager.currentHomeColor,
          ),
        ],
      ),
    );
  }
}

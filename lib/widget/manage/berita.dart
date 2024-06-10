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
      final response = await http.get(Uri.parse('https://ccgnimex.my.id/v2/android/berita/api.php'));
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

  void _openNewsDetail(String link, String translatedTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewBerita(link: 'https://ccgnimex.my.id/v2/android/berita/view.php?url=$link', translated_title: translatedTitle),
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
          color: ColorManager.currentAccentColor,
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
            _buildGridView(),
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
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: ColorManager.currentHomeColor),
        ),
        IconButton(
          icon: Icon(FontAwesomeIcons.sync, color: ColorManager.currentHomeColor),
          onPressed: () {
            _handleRefresh();
          },
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return beritaList.isNotEmpty
        ? _buildNewsGridView()
        : _buildShimmerGridView();
  }

  Widget _buildNewsGridView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: beritaList.length,
      itemBuilder: (context, index) {
        final berita = beritaList[index];
        return _buildNewsCard(berita);
      },
    );
  }

  Widget _buildShimmerGridView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
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
      color: ColorManager.currentPrimaryColor,
      child: InkWell(
        onTap: () {
          _openNewsDetail(berita['link'], berita['translated_title']);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(berita['image']),
            _buildText(berita['translated_title']),
            _buildText(berita['translated_summary'], fontSize: 12.0),
            _buildDateAndIcon(berita['published']),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      color: ColorManager.currentAccentColor,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          color: ColorManager.currentHomeColor,
        ),
      ),
    );
  }

Widget _buildImage(String imageUrl) {
  return Expanded(
    child: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(), // Add an empty child to ensure BoxFit.cover works
    ),
  );
}



  Widget _buildText(String text, {double fontSize = 16.0}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: ColorManager.currentHomeColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDateAndIcon(String publishedDate) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            publishedDate,
            style: TextStyle(fontSize: 12.0, color: ColorManager.currentHomeColor),
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

import 'package:flutter/material.dart';
import 'manage/anime.dart';
import 'manage/manga.dart';
import 'manage/berita.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import FontAwesome icons
import 'package:flue/color.dart';
import 'package:flue/juara.dart';

enum Category { Anime, Berita }

class ManageWidget extends StatefulWidget {
  final String telegramId;
  ManageWidget({required this.telegramId});
  @override
  _ManageWidgetState createState() => _ManageWidgetState();
}

class _ManageWidgetState extends State<ManageWidget> {
  Category selectedCategory = Category.Anime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: Category.values
                    .map((category) => buildCategoryButton(category))
                    .toList(),
              ),
              Row(
                children: [
                  // Tambahkan jarak antara teks dan ikon
                  IconButton(
                    icon: Icon(FontAwesomeIcons.trophy),
                    onPressed: () {
                      // Handle the trophy button press
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                LeaderboardPage(telegramId: widget.telegramId)),
                      );
                    },
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
        buildSelectedContent(),
      ],
    );
  }

  Widget buildCategoryButton(Category category) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: category == selectedCategory
                ? ColorManager.currentPrimaryColor
                : Colors.transparent,
            width: 2.0,
          ),
        ),
      ),
      child: TextButton(
        onPressed: () => handleCategoryPress(category),
        style: TextButton.styleFrom(
          textStyle: TextStyle(
            fontSize: 20.0,
            color: Colors.white,
          ),
        ),
        child: Text(
          category.toString().split('.').last,
          style: TextStyle(
            color: category == selectedCategory
                ? ColorManager.currentPrimaryColor
                : Colors.white,
          ),
        ),
      ),
    );
  }

  void handleCategoryPress(Category category) {
    setState(() {
      selectedCategory = category;
    });

    // Handle category-specific logic
    switch (category) {
      case Category.Anime:
        // Handle anime button press
        break;
      case Category.Berita:
        // Handle berita button press
        break;
    }
  }

  Widget buildSelectedContent() {
    switch (selectedCategory) {
      case Category.Anime:
        return AnimeContent(telegramId: widget.telegramId);
      case Category.Berita:
        return BeritaContent();
      default:
        return Container();
    }
  }
}

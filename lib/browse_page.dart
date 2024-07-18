// Import necessary packages and widgets
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import './widget/browse/anime.dart';
import './widget/browse/music.dart';
import './widget/browse/manga.dart';
import './widget/browse/wallpaper.dart';
import 'package:flue/color.dart'; // Adjust as per your project structure

class BrowsePage extends StatefulWidget {
  final String telegramId;

  BrowsePage({required this.telegramId, Key? key}) : super(key: key);

  @override
  _BrowsePageState createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  late String currentCategory;

  Map<String, IconData> categoryIcons = {
    'Anime': FontAwesomeIcons.film,
    'Manga': FontAwesomeIcons.book,
    'Music': FontAwesomeIcons.music,
    'Wallpaper': FontAwesomeIcons.images,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    currentCategory = 'Anime'; // Set a default category
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose the page controller
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Browse',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ColorManager.currentBackgroundColor ??
            Colors.blue, // Fallback color
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          _buildCategoryDropdown(),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            currentCategory = categoryIcons.keys.toList()[index];
          });
        },
        children: categoryIcons.keys.map((category) {
          return _buildCategoryPage(category);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: DropdownButton<String>(
        value: currentCategory,
        dropdownColor: ColorManager.currentBackgroundColor ??
            Colors.blue, // Fallback color
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              currentCategory = newValue;
              int index = categoryIcons.keys.toList().indexOf(currentCategory);
              _pageController.animateToPage(index,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            });
          }
        },
        items: categoryIcons.keys.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                FaIcon(categoryIcons[value], size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(value, style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryPage(String category) {
    switch (category) {
      case 'Anime':
        return AnimePage(telegramId: widget.telegramId);
      case 'Manga':
        return MangaPage(telegramId: widget.telegramId);
      case 'Music':
        return MusicPage(
            telegramId: widget.telegramId,
            key: PageStorageKey<String>('Music'));
      case 'Wallpaper':
        return WallpaperPage(telegramId: widget.telegramId);
      default:
        return Container();
    }
  }
}

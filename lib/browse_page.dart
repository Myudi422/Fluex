import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import './widget/browse/anime.dart';
import './widget/browse/music.dart';
import './widget/browse/manga.dart';
import './widget/browse/wallpaper.dart';

class BrowsePage extends StatefulWidget {
  final String telegramId;

  BrowsePage({required this.telegramId, Key? key}) : super(key: key);

  @override
  _BrowsePageState createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> with AutomaticKeepAliveClientMixin {
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Browse"),
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
        onChanged: (String? newValue) {
          setState(() {
            currentCategory = newValue!;
            int index = categoryIcons.keys.toList().indexOf(currentCategory);
            _pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          });
        },
        items: categoryIcons.keys.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                FaIcon(categoryIcons[value], size: 16),
                SizedBox(width: 8),
                Text(value),
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
        return MusicPage(telegramId: widget.telegramId, key: PageStorageKey<String>('Music'));
      case 'Wallpaper':
  return WallpaperPage(telegramId: widget.telegramId);
      default:
        return Container();
    }
  }
}

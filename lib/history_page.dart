import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flue/history_anime.dart';
import 'package:flue/history_manga.dart';
import 'package:flue/history_manage.dart';
import 'package:flue/color.dart';

class RiwayatPage extends StatefulWidget {
  final String telegramId;

  RiwayatPage({required this.telegramId});

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  late SharedPreferences _prefs;
  late String currentCategory;

  Map<String, IconData> categoryIcons = {
    'Anime': FontAwesomeIcons.film,
    'Manga': FontAwesomeIcons.book,
  };

  @override
  void initState() {
    super.initState();
    _loadCategory(); // Muat kategori yang terakhir dipilih
  }

  Future<void> _loadCategory() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      currentCategory = _prefs.getString('lastCategory') ?? 'Anime';
    });
  }

  Future<void> _saveCategory(String category) async {
    await _prefs.setString('lastCategory', category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Riwayat Anda",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: ColorManager.currentBackgroundColor,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          _buildCategoryDropdown(),
        ],
      ),
      backgroundColor: ColorManager
          .currentBackgroundColor, // Menambahkan background hitam pada Scaffold
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RiwayatManage(
              telegramId: widget.telegramId), // Add RiwayatManage widget here
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildCategoryPage(currentCategory),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: DropdownButton<String>(
        dropdownColor:
            ColorManager.currentBackgroundColor, // Background dropdown hitam
        value: currentCategory,
        onChanged: (String? newValue) {
          setState(() {
            currentCategory = newValue!;
            _saveCategory(currentCategory); // Simpan kategori yang dipilih
          });
        },
        items: categoryIcons.keys.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                FaIcon(categoryIcons[value],
                    size: 16, color: Colors.white), // Icon putih
                SizedBox(width: 8),
                Text(value,
                    style: TextStyle(color: Colors.white)), // Text putih
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
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: HistoryPage(telegramId: widget.telegramId),
        );
      case 'Manga':
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: MangaHistoryPage(telegramId: widget.telegramId),
        );
      default:
        return Container();
    }
  }
}

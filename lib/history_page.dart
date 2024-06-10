import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan ini
import 'package:flue/history_anime.dart';
import 'package:flue/history_manga.dart';
import 'package:flue/history_manage.dart';


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
        title: Text("Riwayat Anda"),
        actions: [
          _buildCategoryDropdown(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RiwayatManage(telegramId: widget.telegramId), // Add RiwayatManage widget here
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
        return HistoryPage(telegramId: widget.telegramId);
      case 'Manga':
        return MangaHistoryPage(telegramId: widget.telegramId);
      default:
        return Container();
    }
  }
}

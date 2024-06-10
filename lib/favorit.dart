import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widget/anime-detail.dart';


class FavoritWidget extends StatefulWidget {
  final String telegramId;

  FavoritWidget({required this.telegramId});

  @override
  _FavoritWidgetState createState() => _FavoritWidgetState();
}

class _FavoritWidgetState extends State<FavoritWidget> {
  List<dynamic> _animeData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnimeData();
  }

  Future<void> _fetchAnimeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('https://ccgnimex.my.id/v2/android/fav_user.php?telegram_id=${widget.telegramId}'));
      final responseData = json.decode(response.body);

      setState(() {
        _animeData = responseData;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching anime data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorit Saya'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _animeData.isEmpty
              ? Center(
                  child: Text('Tidak ada anime favorit.'),
                )
              : ListView.builder(
  itemCount: _animeData.length,
  itemBuilder: (context, index) {
    final anime = _animeData[index];
    return GestureDetector(
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AnimeDetailPage(
        animeId: int.parse(anime['anime_id']), // Konversi tipe data String ke int
        telegramId: widget.telegramId,
      ),
    ),
  );
},

      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 0.3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  bottomLeft: Radius.circular(12.0),
                ),
                image: anime['image'] != null ? DecorationImage(
                  image: NetworkImage(anime['image']),
                  fit: BoxFit.cover,
                ) : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
  icon: Icon(Icons.close),
  onPressed: () {
    _showDeleteConfirmationDialog(anime['anime_id'], anime['judul']);
  },
),
                      ],
                    ),
                    Text(
                      anime['judul'] ?? 'Unknown Title',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Ditambahkan pada: ${anime['created_at'] ?? 'Unknown Date'}',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
),
    );
  }

  Future<void> _showDeleteConfirmationDialog(String animeId, String animeTitle) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Hapus anime dari favorit?'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Apakah Anda yakin ingin menghapus "$animeTitle" dari favorit Anda?'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Tidak'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Ya'),
            onPressed: () {
              _removeAnimeFromFavorites(animeId);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}




Future<void> _removeAnimeFromFavorites(String animeId) async {
  try {
    final response = await http.post(
      Uri.parse('https://ccgnimex.my.id/v2/android/fav.php'),
      body: {
        'animeId': animeId,
        'telegramId': widget.telegramId,
        'action': 'remove',
      },
    );

    if (response.statusCode == 200) {
      // Anime dihapus dari favorit
      print('Anime dihapus dari favorit');
      // Refresh data setelah menghapus anime dari favorit
      _fetchAnimeData();
    } else {
      // Gagal menghapus anime dari favorit
      print('Gagal menghapus anime dari favorit');
    }
  } catch (error) {
    // Error ketika menghubungi server
    print('Error: $error');
  }
}




}



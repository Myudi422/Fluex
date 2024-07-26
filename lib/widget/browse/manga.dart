import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flue/widget/browse/komik-detail.dart';
import 'package:flue/admob/googlads.dart';
import 'package:flue/color.dart';

class MangaPage extends StatefulWidget {
  final String telegramId;
  MangaPage({required this.telegramId});

  @override
  _MangaPageState createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  final String baseUrl = 'https://ccgnimex.my.id/v2/android/komik/api_home.php';
  int currentPage = 1;
  bool isLoading = false;
  List<Map<String, dynamic>> comics = [];
  String searchKeyword = "";
  List<int> selectedGenres = [];
  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  String userAccess = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _fetchData();
    _fetchUserAccess();
    AdManager()
        .loadInterstitialAd(); // Memuat iklan interstisial saat widget diinisialisasi
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchData() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      _loadDataAndUpdateComics();
    }
  }

  Future<void> _fetchUserAccess() async {
    final apiUrl =
        "https://ccgnimex.my.id/v2/android/cek_akses.php?telegram_id=${widget.telegramId}";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        userAccess = data['akses']; // Mendapatkan status akses pengguna
      });
    }
  }

  Future<void> _loadDataAndUpdateComics() async {
    try {
      String apiUrl =
          '$baseUrl?page=$currentPage&telegram_id=${widget.telegramId}';
      if (searchKeyword.isNotEmpty) {
        apiUrl =
            '$baseUrl?search=$searchKeyword&page=$currentPage&telegram_id=${widget.telegramId}';
      }
      if (selectedGenres.isNotEmpty) {
        apiUrl += '&' +
            selectedGenres.map((genreId) => 'genre%5B%5D=$genreId').join('&');
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> newComics =
            List<Map<String, dynamic>>.from(data);

        setState(() {
          comics.addAll(newComics);
          isLoading = false;
          currentPage++;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _scrollListener() {
    if (!isLoading &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
      _fetchData();
    }
  }

  void _navigateToMangaDetail(String mangaUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailPage(
          mangaUrl: mangaUrl,
          telegramId: widget.telegramId,
        ),
      ),
    );
  }

  void _performSearch() {
    setState(() {
      searchKeyword = _searchController.text;
      comics.clear();
      currentPage = 1;
      _fetchData();
    });
  }

  void _openGenreFilterPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GenreFilterPopup(
          selectedGenres: selectedGenres,
          onApply: (selected) {
            setState(() {
              selectedGenres = selected;
              comics.clear();
              currentPage = 1;
              _fetchData();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          ColorManager.currentBackgroundColor, // Mengatur latar belakang
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: _searchController,
                          style:
                              TextStyle(color: ColorManager.currentHomeColor),
                          decoration: InputDecoration(
                            labelText: 'Cari Manga...',
                            labelStyle:
                                TextStyle(color: ColorManager.currentHomeColor),
                            suffixIcon: Icon(Icons.search,
                                color: ColorManager.currentHomeColor),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: ColorManager.currentHomeColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: ColorManager.currentHomeColor),
                            ),
                          ),
                          onSubmitted: (value) => _performSearch(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.filter_list,
                          color: ColorManager.currentHomeColor),
                      onPressed: _openGenreFilterPopup,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: comics.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        if (userAccess != 'Premium') {
                          // Jika pengguna memiliki akses Free, tampilkan iklan
                          AdManager().showInterstitialAd(
                            onAdDismissed: () {
                              _navigateToMangaDetail(comics[index]['url']);
                            },
                            onAdFailed: () {
                              _navigateToMangaDetail(comics[index]['url']);
                            },
                          );
                        } else {
                          // Jika pengguna memiliki akses Premium, langsung navigasikan ke detail manga
                          _navigateToMangaDetail(comics[index]['url']);
                        }
                      },
                      child: Card(
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Stack(
                            children: [
                              // Full-size image
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  imageUrl: comics[index]['image'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                              // Gradient overlay for the bottom area
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black54,
                                        Colors.transparent
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      stops: [0, 0.5],
                                    ),
                                  ),
                                ),
                              ),
                              // Episode count at the top left
                              Positioned(
                                top: 8.0,
                                left: 8.0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    "${comics[index]['chapter']}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              ),
                              // History at the top right
                              if (comics[index]['title_eps'] != null &&
                                  comics[index]['title_eps'] != '')
                                Positioned(
                                  top: 8.0,
                                  right: 8.0,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Row(
                                      children: [
                                        Transform.scale(
                                          scale: 0.7,
                                          child: Icon(
                                            Icons.history,
                                            color: Colors.white,
                                            size: 15.0,
                                          ),
                                        ),
                                        SizedBox(width: 4.0),
                                        Text(
                                          comics[index]['title_eps'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Title at the bottom
                              Positioned(
                                bottom: 8.0,
                                left: 8.0,
                                right: 8.0,
                                child: Text(
                                  comics[index]['title'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (isLoading)
            Positioned(
              bottom: 16.0,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class GenreFilterPopup extends StatefulWidget {
  final List<int> selectedGenres;
  final Function(List<int>) onApply;

  GenreFilterPopup({required this.selectedGenres, required this.onApply});

  @override
  _GenreFilterPopupState createState() => _GenreFilterPopupState();
}

class _GenreFilterPopupState extends State<GenreFilterPopup> {
  List<int> selectedGenres = [];

  @override
  void initState() {
    super.initState();
    selectedGenres = List.from(widget.selectedGenres);
  }

  void _toggleGenreSelection(int genreId) {
    setState(() {
      if (selectedGenres.contains(genreId)) {
        selectedGenres.remove(genreId);
      } else {
        selectedGenres.add(genreId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> genres = [
      {'id': 3233, 'name': "4-Koma"},
      {'id': 2, 'name': "Action"},
      {'id': 2796, 'name': "Adaptation"},
      {'id': 405, 'name': "Adult"},
      {'id': 3, 'name': "Adventure"},
      {'id': 2669, 'name': "Bully"},
      {'id': 4, 'name': "Comedy"},
      {'id': 2766, 'name': "Cooking"},
      {'id': 2270, 'name': "Crime"},
      {'id': 2190, 'name': "Dark Fantasy"},
      {'id': 2670, 'name': "Delinquent"},
      {'id': 2549, 'name': "Demon"},
      {'id': 38, 'name': "Demons"},
      {'id': 631, 'name': "Doujinshi"},
      {'id': 14, 'name': "Drama"},
      {'id': 21, 'name': "Ecchi"},
      {'id': 5, 'name': "Fantasy"},
      {'id': 203, 'name': "Game"},
      {'id': 165, 'name': "Gender Bender"},
      {'id': 2797, 'name': "Genderswap"},
      {'id': 2447, 'name': "Girls' Love"},
      {'id': 2061, 'name': "Gore"},
      {'id': 399, 'name': "Gyaru"},
      {'id': 90, 'name': "Harem"},
      {'id': 4585, 'name': "Hero"},
      {'id': 127, 'name': "Historical"},
      {'id': 698, 'name': "horor"},
      {'id': 15, 'name': "Horror"},
      {'id': 2079, 'name': "Incest"},
      {'id': 393, 'name': "Isekai"},
      {'id': 2036, 'name': "Josei"},
      {'id': 4613, 'name': "Long Strip"},
      {'id': 22, 'name': "Magic"},
      {'id': 4614, 'name': "Magical Girls"},
      {'id': 4489, 'name': "Manhua"},
      {'id': 2191, 'name': "Manhwa"},
      {'id': 2244, 'name': "Martial Art"},
      {'id': 24, 'name': "Martial Arts"},
      {'id': 148, 'name': "Mature"},
      {'id': 128, 'name': "Mecha"},
      {'id': 2286, 'name': "Medical"},
      {'id': 139, 'name': "Military"},
      {'id': 3748, 'name': "Mirror"},
      {'id': 435, 'name': "Mistery"},
      {'id': 3970, 'name': "Monsters"},
      {'id': 2208, 'name': "Murim"},
      {'id': 57, 'name': "Music"},
      {'id': 13, 'name': "Mystery"},
      {'id': 2511, 'name': "One-Shot"},
      {'id': 8, 'name': "Parody"},
      {'id': 4152, 'name': "Philosophical"},
      {'id': 180, 'name': "Police"},
      {'id': 2373, 'name': "Project"},
      {'id': 91, 'name': "Psychological"},
      {'id': 2658, 'name': "Regression"},
      {'id': 2198, 'name': "Reincarnation"},
      {'id': 26, 'name': "Romance"},
      {'id': 27, 'name': "Samurai"},
      {'id': 23, 'name': "School"},
      {'id': 334, 'name': "School Life"},
      {'id': 9, 'name': "Sci-Fi"},
      {'id': 56, 'name': "Seinen"},
      {'id': 2027, 'name': "Shotacon"},
      {'id': 102, 'name': "Shoujo"},
      {'id': 1789, 'name': "Shoujo Ai"},
      {'id': 693, 'name': "shoun"},
      {'id': 6, 'name': "Shounen"},
      {'id': 2459, 'name': "Shounen Ai"},
      {'id': 118, 'name': "Slice of Life"},
      {'id': 129, 'name': "Space"},
      {'id': 25, 'name': "Sports"},
      {'id': 7, 'name': "Super Power"},
      {'id': 2624, 'name': "Superhero"},
      {'id': 10, 'name': "Supernatural"},
      {'id': 865, 'name': "System"},
      {'id': 2349, 'name': "Thriller"},
      {'id': 2671, 'name': "Time Travel"},
      {'id': 169, 'name': "Tragedy"},
      {'id': 111, 'name': "Vampire"},
      {'id': 2798, 'name': "Vampires"},
      {'id': 2799, 'name': "Video Games"},
      {'id': 4567, 'name': "Villainess"},
      {'id': 2800, 'name': "Virtual Reality"},
      {'id': 4615, 'name': "Web Comic"},
      {'id': 2491, 'name': "Webtoons"},
      {'id': 2282, 'name': "Wuxia"},
      {'id': 829, 'name': "Yuri"},
    ];

    return AlertDialog(
      title: Text('Filter Genre'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: genres.map((genre) {
            return CheckboxListTile(
              title: Text(genre['name']),
              value: selectedGenres.contains(genre['id']),
              onChanged: (bool? value) {
                _toggleGenreSelection(genre['id']);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Apply'),
          onPressed: () {
            widget.onApply(selectedGenres);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

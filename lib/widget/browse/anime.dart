import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flue/widget/anime-detail.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flue/admob/unity.dart';
import 'package:flue/color.dart';

class Anime {
  final String id;
  final String animeId;
  final String title;
  final String imageUrl;
  final String genre;
  final String format;
  final String duration;
  final String status;
  final String season;
  final String tags;

  Anime({
    required this.id,
    required this.title,
    required this.animeId,
    required this.imageUrl,
    required this.genre,
    required this.format,
    required this.duration,
    required this.status,
    required this.season,
    required this.tags,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id'],
      title: json['judul'],
      animeId: json['anime_id'],
      imageUrl: json['image'],
      genre: json['genre'],
      format: json['format'],
      duration: json['duration'],
      status: json['status'],
      season: json['season'],
      tags: json['tags'],
    );
  }

  List<String> splitAndTrim(String values) {
    return values.split(',').map((value) => value.trim()).toList();
  }

  List<String> getGenres() {
    return splitAndTrim(genre);
  }

  List<String> getFormats() {
    return splitAndTrim(format);
  }

  List<String> getStatuses() {
    return splitAndTrim(status);
  }

  List<String> getSeasons() {
    return splitAndTrim(season);
  }

  String getPropertyValue(String propertyName) {
    switch (propertyName) {
      case 'genre':
        return genre;
      case 'format':
        return format;
      case 'status':
        return status;
      case 'season':
        return season;
      default:
        return '';
    }
  }
}

class ApiService {
  static const String apiUrl =
      'https://ccgnimex.my.id/v2/android/api_browse.php';

  static Future<List<Anime>> fetchAnimeData() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Anime.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load anime data');
    }
  }
}

class AnimePage extends StatefulWidget {
  final String telegramId;

  AnimePage({required this.telegramId});

  @override
  _AnimePageState createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage> {
  late List<Anime> animeList;
  late String currentCategory;
  late List<Anime> filteredAnimeList;

  List<String> genres = [];
  List<String> formats = [];
  List<String> statuses = [];
  List<String> seasons = [];

  List<String> selectedGenres = [];
  List<String> selectedFormats = [];
  List<String> selectedStatuses = [];
  List<String> selectedSeasons = [];

  String searchQuery = ''; // Added for search functionality
  String userAccess = '';

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false; // Add this line

  @override
  void initState() {
    super.initState();
    _fetchUserAccess();
    animeList = [];
    currentCategory = ""; // Initialize the late variable here
    filteredAnimeList = [];
    fetchData();

    // Initialize the interstitial ad
    UnityAdManager.loadInterstitialAd();
  }

  @override
  void dispose() {
    super.dispose();
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

  Future<void> fetchData() async {
    try {
      final data = await ApiService.fetchAnimeData();
      setState(() {
        animeList = data;
        filteredAnimeList = List.from(animeList);

        genres = extractUniqueValues('genre');
        formats = extractUniqueValues('format');
        statuses = extractUniqueValues('status');
        seasons = extractUniqueValues('season');
      });

      // Load interstitial ad after fetching new data
      UnityAdManager.loadInterstitialAd();
    } catch (e) {
      throw Exception('Failed to load anime data');
    }
  }

  List<String> extractUniqueValues(String propertyName) {
    List<String> allValues = animeList
        .map((anime) {
          switch (propertyName) {
            case 'genre':
              return anime.getGenres();
            case 'format':
              return anime.getFormats();
            case 'status':
              return anime.getStatuses();
            case 'season':
              return anime.getSeasons();
            default:
              return [];
          }
        })
        .expand((values) => values)
        .whereType<String>() // Mengambil hanya nilai bertipe String
        .toList(); // Menggabungkan semua list menjadi satu

    List<String> uniqueValues = List<String>.from(
        allValues.toSet()); // Mengonversi ke Set kemudian kembali ke List

    return uniqueValues;
  }

  void filterAnime() {
    setState(() {
      filteredAnimeList = animeList
          .where((anime) =>
              (selectedGenres.isEmpty ||
                  anime
                      .getGenres()
                      .any((genre) => selectedGenres.contains(genre))) &&
              (selectedFormats.isEmpty ||
                  anime
                      .getFormats()
                      .any((format) => selectedFormats.contains(format))) &&
              (selectedStatuses.isEmpty ||
                  anime
                      .getStatuses()
                      .any((status) => selectedStatuses.contains(status))) &&
              (selectedSeasons.isEmpty ||
                  anime
                      .getSeasons()
                      .any((season) => selectedSeasons.contains(season))) &&
              (searchQuery.isEmpty ||
                  anime.title
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase())))
          .toList();

      // Filter tambahan: Hanya tampilkan anime yang memiliki semua genre yang dipilih
      if (selectedGenres.isNotEmpty) {
        filteredAnimeList = filteredAnimeList
            .where((anime) => selectedGenres
                .every((genre) => anime.getGenres().contains(genre)))
            .toList();
      }

      // Load interstitial ad after filtering anime
      UnityAdManager.loadInterstitialAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorManager.currentBackgroundColor,
                  ColorManager.currentBackgroundColor
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            style:
                                TextStyle(color: ColorManager.currentHomeColor),
                            decoration: InputDecoration(
                              labelText: 'Search',
                              labelStyle: TextStyle(
                                  color: ColorManager.currentHomeColor),
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
                            onChanged: (query) {
                              setState(() {
                                searchQuery = query;
                                filterAnime();
                              });
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.filter_list,
                            color: ColorManager.currentHomeColor),
                        onPressed: () {
                          showFilterDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(4.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: filteredAnimeList.length,
                    itemBuilder: (context, index) {
                      final anime = filteredAnimeList[index];
                      return GestureDetector(
                        onTap: () async {
                          if (userAccess != 'Premium') {
                            // Jika pengguna memiliki akses Free, tampilkan iklan
                            if (UnityAdManager.isInitialized) {
                              UnityAdManager.showInterstitialAd(
                                onComplete: (String rewardItemKey) {
                                  _navigateToAnimeDetail(anime);
                                },
                                onFailed: (String placementId, dynamic error,
                                    String message) {
                                  _navigateToAnimeDetail(anime);
                                },
                              );
                            } else {
                              print(
                                  "Unity Ads is not initialized. Please call UnityAdManager.initialize() first.");
                              _navigateToAnimeDetail(anime);
                            }
                          } else {
                            // Jika pengguna memiliki akses Premium, langsung navigasikan ke detail anime
                            _navigateToAnimeDetail(anime);
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              10.0), // Sesuaikan dengan keinginan Anda
                          child: Card(
                            elevation: 4.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  10.0), // Sesuaikan dengan keinginan Anda
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: anime.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(1.0),
                                          Colors.black.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10.0,
                                    left: 6.0,
                                    right: 6.0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          anime.title ?? 'Unknown Title',
                                          style: TextStyle(
                                              color: ColorManager
                                                  .currentHomeColor),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        SizedBox(height: 4.0),
                                        Row(
                                          children: [
                                            ...anime
                                                .getGenres()
                                                .take(2)
                                                .map((genre) {
                                              return Container(
                                                margin:
                                                    EdgeInsets.only(right: 2.0),
                                                decoration: BoxDecoration(
                                                  color: ColorManager
                                                      .currentPrimaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0), // Mengurangi ukuran borderRadius
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 4.0,
                                                    vertical:
                                                        4.0), // Mengurangi ukuran padding
                                                child: Text(
                                                  genre,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          10.5), // Mengurangi ukuran font
                                                ),
                                              );
                                            }).toList(),
                                            if (anime.getGenres().length > 2)
                                              Container(
                                                margin:
                                                    EdgeInsets.only(right: 6.0),
                                                padding: EdgeInsets.all(
                                                    4.8), // Mengurangi ukuran padding
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: ColorManager
                                                      .currentPrimaryColor,
                                                ),
                                                child: Text(
                                                  '+${anime.getGenres().length - 2}',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          10.5), // Mengurangi ukuran font
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateBack() {
    Navigator.pop(context);
  }

  void _navigateToAnimeDetail(Anime anime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimeDetailPage(
          animeId: int.parse(anime.animeId),
          telegramId: widget.telegramId,
        ),
      ),
    );
  }

  void showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Filter Options'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    buildFilterChipGroup(
                        'Genre', genres, selectedGenres, setState),
                    buildFilterChipGroup(
                        'Format', formats, selectedFormats, setState),
                    buildFilterChipGroup(
                        'Status', statuses, selectedStatuses, setState),
                    buildFilterChipGroup(
                        'Season', seasons, selectedSeasons, setState),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    filterAnime();
                  },
                  child: Text('Apply Filters'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildFilterChipGroup(String label, List<String> options,
      List<String> selectedOptions, StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0, // Menambah jarak antar baris
            children: [
              FilterChip(
                label: Text(
                  'All',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: selectedOptions.isEmpty,
                onSelected: (bool selected) {
                  setState(() {
                    selectedOptions.clear();
                    filterAnime();
                  });
                },
              ),
              ...options.map((option) {
                return FilterChip(
                  label: Text(option),
                  selected: selectedOptions.contains(option),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedOptions.add(option);
                      } else {
                        selectedOptions.remove(option);
                      }
                    });
                  },
                  backgroundColor:
                      selectedOptions.contains(option) ? Colors.blue : null,
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: selectedOptions.contains(option)
                        ? Colors.white
                        : Colors.black,
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimeSearchDelegate extends SearchDelegate<String> {
  final List<Anime> animeList;

  AnimeSearchDelegate(this.animeList);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? animeList
        : animeList
            .where((anime) =>
                anime.title.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final anime = suggestionList[index];
        return ListTile(
          title: Text(anime.title ?? 'Unknown Title'),
          onTap: () {
            close(context, anime.title ?? 'Unknown Title');
          },
        );
      },
    );
  }
}

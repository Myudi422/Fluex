import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BacaPage extends StatefulWidget {
  final String episodeUrl;

  BacaPage({required this.episodeUrl});

  @override
  _BacaPageState createState() => _BacaPageState();
}

class _BacaPageState extends State<BacaPage> {
  late Map<String, dynamic> episodeDetails;
  bool isLoading = true;
  late PageController pageController;
  int currentPage = 0;
  bool isHorizontalMode = true;
  String prevEpisodeUrl = '';
  String nextEpisodeUrl = '';
  String chapterNumber = '';
  String server = ''; // Default server (empty string means no server parameter)

  @override
  void initState() {
    super.initState();
    _fetchEpisodeDetails();
    pageController = PageController();
    _loadPageIndex(); // Load the last page index
  }

  Future<void> _fetchEpisodeDetails() async {
    // Normalisasi URL dengan menghapus garis miring di akhir
    String normalizedUrl = widget.episodeUrl.endsWith('/')
        ? widget.episodeUrl.substring(0, widget.episodeUrl.length - 1)
        : widget.episodeUrl;

    try {
      final response = await Dio().get(
          'https://ccgnimex.my.id/v2/android/komik/baca.php?url=$normalizedUrl&server=$server');

      if (response.statusCode == 200) {
        setState(() {
          episodeDetails = response.data;
          isLoading = false;

          // Extracting prev and next episode URLs
          prevEpisodeUrl = episodeDetails['prevUrl'] ?? '';
          nextEpisodeUrl = episodeDetails['nextUrl'] ?? '';

          // Extracting chapter number from the title
          RegExp regExp = RegExp(r"Chapter (\d+)");
          Match? match = regExp.firstMatch(episodeDetails['title']);
          chapterNumber = match?.group(1) ?? "";

          // Load the saved page index
          _loadPageIndex();
        });
      } else {
        throw Exception(
            'Failed to load episode details. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching episode details: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onServerSelected(String selectedServer) {
    setState(() {
      server = selectedServer == 'default' ? '' : selectedServer;
      isLoading = true; // Show loading indicator while fetching new data
    });
    _fetchEpisodeDetails(); // Fetch data with the new server
  }

  Future<void> _savePageIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentPage_${widget.episodeUrl}', index);
  }

  Future<void> _loadPageIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentPage = prefs.getInt('currentPage_${widget.episodeUrl}') ?? 0;
    });
    pageController.jumpToPage(currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter $chapterNumber'),
        actions: [
          IconButton(
            icon: Icon(isHorizontalMode ? Icons.swap_vert : Icons.swap_horiz),
            onPressed: () {
              setState(() {
                isHorizontalMode = !isHorizontalMode;
                _updatePageController();
              });
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.cloud),
            onSelected: _onServerSelected,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'default', child: Text('Default')),
                PopupMenuItem(value: 'komiku-id1', child: Text('DEF-KOM')),
                PopupMenuItem(value: 'komiku-id2', child: Text('01-1KOM')),
                PopupMenuItem(value: 'komiku-id3', child: Text('KMINDO-1KOM')),
                PopupMenuItem(value: 'komiku-id4', child: Text('1-01KOM')),
              ];
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isHorizontalMode
              ? _buildHorizontalView()
              : _buildVerticalView(),
    );
  }

  Widget _buildHorizontalView() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PhotoViewGallery.builder(
          itemCount: episodeDetails['imageUrls'].length,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(
                  episodeDetails['imageUrls'][index] ?? ''),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          },
          scrollPhysics: BouncingScrollPhysics(),
          backgroundDecoration: BoxDecoration(
            color: Colors.black,
          ),
          pageController: pageController,
          onPageChanged: (index) {
            setState(() {
              currentPage = index;
              _savePageIndex(currentPage); // Save the current page index
            });
          },
        ),
        if (isHorizontalMode) _buildControllerBar(),
      ],
    );
  }

  Widget _buildVerticalView() {
    return ListView.builder(
      itemCount: episodeDetails['imageUrls'].length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: episodeDetails['imageUrls'][index] ?? '',
          placeholder: (context, url) =>
              Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Icon(Icons.error),
        );
      },
      controller: pageController,
      scrollDirection: Axis.vertical,
    );
  }

  Widget _buildControllerBar() {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.navigate_before),
            onPressed: () {
              _scrollPage(-1);
            },
            color: Colors.white,
          ),
          Text(
            '${currentPage + 1} / ${episodeDetails['imageUrls'].length}',
            style: TextStyle(fontSize: 16.0, color: Colors.white),
          ),
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: () {
              _scrollPage(1);
            },
            color: Colors.white,
          ),
          IconButton(
            icon: Icon(Icons.skip_previous),
            onPressed: () {
              _navigateToEpisode(prevEpisodeUrl);
            },
            color: prevEpisodeUrl.isNotEmpty ? Colors.white : Colors.grey,
          ),
          IconButton(
            icon: Icon(Icons.skip_next),
            onPressed: () {
              _navigateToEpisode(nextEpisodeUrl);
            },
            color: nextEpisodeUrl.isNotEmpty ? Colors.white : Colors.grey,
          ),
        ],
      ),
    );
  }

  void _scrollPage(int delta) {
    int nextPage = currentPage + delta;
    if (nextPage >= 0 && nextPage < episodeDetails['imageUrls'].length) {
      pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        currentPage = nextPage;
        _savePageIndex(currentPage); // Save the current page index
      });
    }
  }

  void _updatePageController() {
    // Update the PageController with initialPage set based on the current mode
    pageController = PageController(initialPage: currentPage);
  }

  void _navigateToEpisode(String episodeUrl) {
    if (episodeUrl.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BacaPage(episodeUrl: episodeUrl),
        ),
      );
    }
  }
}

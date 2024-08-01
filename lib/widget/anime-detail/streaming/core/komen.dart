import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class KomenPage extends StatefulWidget {
  final int episodeNumber;
  final int animeId;
  final String telegramId;

  KomenPage({
    required this.episodeNumber,
    required this.animeId,
    required this.telegramId,
  });

  @override
  _KomenPageState createState() => _KomenPageState();
}

class _KomenPageState extends State<KomenPage> {
  String _profilePictureUrl = ''; // Store profile picture URL
  List comments = [];
  TextEditingController _controller = TextEditingController();
  String _sortOrder = 'Terbaru';

  @override
  void initState() {
    super.initState();
    fetchComments();
    fetchUserProfile();
  }

  fetchUserProfile() async {
    try {
      var response = await http.get(Uri.parse(
          'https://ccgnimex.my.id/v2/android/api_user.php?telegram_id=${widget.telegramId}'));
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            _profilePictureUrl = jsonResponse['profile_picture'];
          });
        } else {
          print("Error fetching user profile: ${jsonResponse['status']}");
        }
      } else {
        print("Error fetching user profile: ${response.statusCode}");
      }
    } catch (e) {
      print("Fetch User Profile Error: $e");
    }
  }

  fetchComments() async {
    try {
      var response = await http.get(Uri.parse(
          'https://ccgnimex.my.id/v2/android/komen/fetch_comment.php?anime_id=${widget.animeId}&episode_id=${widget.episodeNumber}'));
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse is List) {
          setState(() {
            comments = jsonResponse;
            _sortComments();
          });
        } else {
          print("Error: Expected a list but got ${jsonResponse.runtimeType}");
        }
      } else {
        print("Error fetching comments: ${response.body}");
      }
    } catch (e) {
      print("Fetch Comments Error: $e");
    }
  }

  postComment(String comment) async {
    try {
      var response = await http.post(
        Uri.parse('https://ccgnimex.my.id/v2/android/komen/post_comment.php'),
        body: {
          'anime_id': widget.animeId.toString(),
          'episode_id': widget.episodeNumber.toString(),
          'telegram_id': widget.telegramId,
          'comment': comment,
        },
      );
      if (response.statusCode == 200) {
        _controller.clear();
        fetchComments();
      } else {
        print("Error posting comment: ${response.body}");
      }
    } catch (e) {
      print("Post Comment Error: $e");
    }
  }

  deleteComment(String commentId, String telegramId) async {
    try {
      var response = await http.delete(
        Uri.parse('https://ccgnimex.my.id/v2/android/komen/delete_coment.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': commentId,
          'telegram_id': telegramId,
        }),
      );
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] != null) {
          fetchComments(); // Refresh comments after deletion
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Comment deleted successfully')),
          );
        } else {
          print("Error deleting comment: ${jsonResponse['error']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${jsonResponse['error']}')),
          );
        }
      } else {
        print("Error deleting comment: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      print("Delete Comment Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete Comment Error: $e')),
      );
    }
  }

  String _formatDate(String datePosting) {
    final dateTime = DateTime.parse(datePosting);
    final now = DateTime.now();
    return timeago.format(dateTime,
        locale: 'id', allowFromNow: true, clock: now);
  }

  void _showBottomSheet(
      BuildContext context, String commentId, String telegramId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom == 0
                ? 10.0
                : MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Container(
            color: Colors.black87,
            child: Wrap(
              children: <Widget>[
                SizedBox(height: 10.0),
                ListTile(
                  leading: Icon(Icons.person, color: Colors.white),
                  title: Text('Profile', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Handle Profile action
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.report, color: Colors.white),
                  title: Text('Report', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Handle Report action
                    Navigator.pop(context);
                  },
                ),
                if (telegramId ==
                    widget.telegramId) // Check if telegramId matches
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Hapus Komentar',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      // Handle Delete Comment action
                      deleteComment(commentId, telegramId);
                      Navigator.pop(context);
                    },
                  ),
                SizedBox(height: 10.0),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sortComments() {
    if (_sortOrder == 'Terbaru') {
      comments.sort((a, b) => DateTime.parse(b['date_posting'])
          .compareTo(DateTime.parse(a['date_posting'])));
    } else {
      comments.sort((a, b) => DateTime.parse(a['date_posting'])
          .compareTo(DateTime.parse(b['date_posting'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Text(
                "Jangan lupa untuk membuat komentar yang sopan dan santun dan mengikuti Aturan Komunitas kami.",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: _profilePictureUrl.isNotEmpty
                      ? CachedNetworkImageProvider(_profilePictureUrl)
                      : AssetImage('assets/placeholder_image.png')
                          as ImageProvider,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Tambahkan komentar...',
                      hintStyle: TextStyle(color: Colors.white),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      postComment(_controller.text);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${comments.length} Komentar",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _sortOrder,
                      dropdownColor: Colors.grey[850],
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                      onChanged: (String? newValue) {
                        setState(() {
                          _sortOrder = newValue!;
                          _sortComments();
                        });
                      },
                      items: <String>['Terbaru', 'Terlama']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                    ),
                    Icon(Icons.sort, color: Colors.white),
                  ],
                ),
              ],
            ),
            Divider(color: Colors.white),
            SizedBox(height: 10),
            comments.isEmpty
                ? Center(
                    child: Text(
                        "Tidak ada komentar. silahkan berkomentar untuk mendapatkan point.",
                        style: TextStyle(color: Colors.white)),
                  )
                : Column(
                    children: comments.map((comment) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 10.0),
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  comment['profile_picture']),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${comment['first_name']} · ${_formatDate(comment['date_posting'])}",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10),
                                  ),
                                  Text(
                                    '${comment['akses']} | #${comment['id_web']}',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 10),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    comment['comment'],
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.more_vert, color: Colors.white),
                              onPressed: () {
                                _showBottomSheet(
                                    context,
                                    comment['id'].toString(),
                                    comment['telegram_id']);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

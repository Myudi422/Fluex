import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flue/color.dart';
import './widget/me.dart';

class ChatRoomPage extends StatefulWidget {
  final String firstName;
  final String profilePicture;
  final String premiumStatus;
  final String telegramId;

  ChatRoomPage({
    required this.firstName,
    required this.profilePicture,
    required this.premiumStatus,
    required this.telegramId,
  });

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  List<ChatMessage> messages = [];
  TextEditingController messageController = TextEditingController();
  late Timer _timer;
  bool isFloatingVisible = false;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchChatroomMessages();

    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        setState(() {
          isFloatingVisible = true;
        });
      } else {
        setState(() {
          isFloatingVisible = false;
        });
      }
    });

    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      fetchChatroomMessages();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: ColorManager.currentBackgroundColor,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: ListView.builder(
                            itemCount: 15,
                            itemBuilder: (context, index) {
                              return ShimmerChatBubble();
                            },
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return ChatBubble(
                              message: messages[index],
                              myTelegramId:
                                  widget.telegramId, // Pass the telegramId here
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            filled: false,
                            fillColor: ColorManager.currentHomeColor,
                            hintText: 'Masukan Pesan...',
                            hintStyle:
                                TextStyle(color: ColorManager.currentHomeColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          style: TextStyle(
                              color: ColorManager
                                  .currentHomeColor), // Mengatur warna teks yang diketik
                        ),
                      ),
                      SizedBox(width: 8.0),
                      FloatingActionButton(
                        onPressed: () {
                          sendMessage();
                        },
                        child: Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Visibility(
                visible: isFloatingVisible,
                child: GestureDetector(
                  onTap: () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorManager.currentPrimaryColor,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: EdgeInsets.all(8.0),
                    margin: EdgeInsets.only(
                        bottom: 60.0), // Adding margin to avoid overlap
                    child: Icon(
                      Icons.arrow_downward,
                      color: ColorManager.currentHomeColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void sendMessage() async {
    String message = messageController.text;
    if (message.isNotEmpty &&
        widget.telegramId != null &&
        widget.telegramId!.isNotEmpty) {
      await sendChatroomMessage(message);
      await fetchChatroomMessages();
      messageController.clear();
    } else {
      // Handle the case where telegramId is null or empty
      // For example, show an error message
      print('Telegram ID is required to send a message');
    }
  }

  Future<void> sendChatroomMessage(String message) async {
    final url = 'https://ccgnimex.my.id/v2/android/chat/api.php';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_telegram_id': widget.telegramId,
        'message_text': message,
        'first_name': widget.firstName ?? '',
        'profile_picture': widget.profilePicture ?? '',
        'akses': widget.premiumStatus ?? '',
      }),
    );

    if (response.statusCode == 200) {
      print('Message sent successfully');
    } else {
      throw Exception('Failed to send message');
    }
  }

  Future<void> fetchChatroomMessages() async {
    final url = 'https://ccgnimex.my.id/v2/android/chat/api.php';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        messages =
            data.map((message) => ChatMessage.fromJson(message)).toList();
      });
    } else {
      throw Exception('Failed to load messages');
    }
  }
}

class ChatMessage {
  final String firstName;
  final String messageText;
  final DateTime timestamp;
  final String profilePicture;
  final String premiumStatus;
  final String telegramId;

  ChatMessage({
    required this.firstName,
    required this.messageText,
    required this.timestamp,
    required this.profilePicture,
    required this.premiumStatus,
    required this.telegramId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      firstName: json['first_name'],
      messageText: _truncateMessage(json['message_text']),
      timestamp: DateTime.parse(json['timestamp']),
      profilePicture: json['profile_picture'],
      premiumStatus: json['akses'],
      telegramId: json['telegram_id'],
    );
  }

  static String _truncateMessage(String message) {
    return message;
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String myTelegramId; // Add this

  const ChatBubble(
      {Key? key, required this.message, required this.myTelegramId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        telegramId: message.telegramId,
                        mytelegram: myTelegramId, // Pass the telegramId here
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundImage: NetworkImage(message.profilePicture),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: message.premiumStatus == 'Admin'
                        ? Colors.red
                        : (message.premiumStatus == 'Premium'
                            ? Color.fromARGB(255, 220, 200, 22)
                            : Colors.blue),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    message.premiumStatus == 'Admin'
                        ? FontAwesomeIcons.userAstronaut
                        : (message.premiumStatus == 'Premium'
                            ? FontAwesomeIcons.gem
                            : FontAwesomeIcons.bolt),
                    color: Colors.white,
                    size: 12.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${message.firstName} • ',
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: ColorManager.currentHomeColor
                        .withOpacity(0.2), // Transparansi 40%
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12.0),
                      bottomLeft: Radius.circular(12.0),
                      bottomRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Wrap(
                    children: [
                      Text(
                        message.messageText,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    Duration difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

class ShimmerChatBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            radius: 24.0,
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12.0),
                  bottomLeft: Radius.circular(12.0),
                  bottomRight: Radius.circular(12.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100.0,
                    height: 10.0,
                    color: Colors.white,
                  ),
                  SizedBox(height: 4.0),
                  Container(
                    width: 200.0,
                    height: 10.0,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

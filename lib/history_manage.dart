import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flue/color.dart';
import 'favorit.dart'; // Import FavoritWidget

class RiwayatManage extends StatelessWidget {
  final String telegramId;

  RiwayatManage({required this.telegramId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: LinearGradient(
          colors: [ColorManager.currentPrimaryColor, ColorManager.currentPrimaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navigasi ke halaman FavoritWidget saat grid pertama diklik
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FavoritWidget(telegramId: telegramId)),
                );
              },
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: ColorManager.currentAccentColor.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Icon(
                            FontAwesomeIcons.star,
                            size: 20,
                            color: ColorManager.currentHomeColor,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'Favorit Saya',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColorManager.currentHomeColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15.0),
                        onTap: () {
                          // Navigasi ke halaman FavoritWidget saat grid pertama diklik
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FavoritWidget(telegramId: telegramId)),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Menampilkan Snackbar karena fitur belum tersedia
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fitur belum tersedia, sedang dalam pengembangan.'),
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: ColorManager.currentAccentColor.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Icon(
                            FontAwesomeIcons.download,
                            size: 20,
                            color: ColorManager.currentHomeColor,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'Download Saya',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColorManager.currentHomeColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15.0),
                        onTap: () {
                          // Menampilkan Snackbar karena fitur belum tersedia
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fitur belum tersedia, sedang dalam pengembangan.'),
                            ),
                          );
                        },
                      ),
                    ),
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

import 'package:flutter/material.dart';
import 'package:flue/widget/ongoing.dart';
import '../jadwal_page.dart';

class OngoingTitleWidget extends StatelessWidget {
  final String telegramId;

  OngoingTitleWidget({required this.telegramId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Anime Terbaru",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Ubah warna teks sesuai kebutuhan
              shadows: [
                Shadow(
                  blurRadius: 5.0,
                  color: Colors.black,
                  offset: Offset(2.0, 2.0),
                ),
              ],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Navigate to the jadwal screen when the button is pressed
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => JadwalPage(telegramId: telegramId)),
            );
          },
          child: Row(
            children: [
              Text(
                "Lihat Jadwal",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ],
    );
  }
}

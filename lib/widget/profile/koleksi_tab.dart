import 'package:flutter/material.dart';

class KoleksiTab extends StatelessWidget {
  final String telegramId;
  final String mytelegram;

  const KoleksiTab(
      {super.key, required this.telegramId, required this.mytelegram});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Comming Soon', style: TextStyle(color: Colors.white)),
    );
  }
}

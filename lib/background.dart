import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flue/color.dart';

class BackgroundWidget extends StatefulWidget {
  @override
  _BackgroundWidgetState createState() => _BackgroundWidgetState();
}

class _BackgroundWidgetState extends State<BackgroundWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient Background
        Container(
          height: MediaQuery.of(context).size.height * 1.25,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorManager.currentPrimaryColor,
                ColorManager.currentPrimaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.1, 0.9],
            ),
          ),
        ),
        // Gradient Overlay
        Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorManager.currentBackgroundColor.withOpacity(0.3),
                ColorManager.currentBackgroundColor.withOpacity(0.5),
                ColorManager.currentBackgroundColor.withOpacity(0.8),
                ColorManager.currentBackgroundColor.withOpacity(1.0),
                ColorManager.currentBackgroundColor.withOpacity(1.0),
                ColorManager.currentBackgroundColor.withOpacity(1.0),
              ],
              stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Shadow
        Positioned(
          top: MediaQuery.of(context).size.height * 0.20,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.80,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

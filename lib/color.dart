import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'main.dart';

class ColorManager {
  static Color currentPrimaryColor = Warna.primaryColor;
  static Color currentAccentColor = Warna.accentColor;
  static Color currentHomeColor = Warna.homeColor;
  static Color currentBackgroundColor = Warna.backgroundColor;
}

class WarnaPaketKustom {
  static const Color customColor1 = Color(0xFF00FF00);
  static const Color customColor2 = Color(0xFFFFD700);
  static const Color customColor3 = Color(0xFF800080);
  static const Color customColor4 = Color(0xFF800080);
}

class Warna {
  static const Color primaryColor = Color.fromARGB(255, 254, 61, 126);
  static const Color accentColor = Color.fromARGB(255, 94, 7, 36);
  static const Color homeColor = Color.fromARGB(255, 255, 252, 253);
  static const Color backgroundColor = Color.fromARGB(21, 21, 21, 21);
}

Future<void> loadColors() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  ColorManager.currentPrimaryColor =
      Color(prefs.getInt('primaryColor') ?? Warna.primaryColor.value);
  ColorManager.currentAccentColor =
      Color(prefs.getInt('accentColor') ?? Warna.accentColor.value);
  ColorManager.currentHomeColor =
      Color(prefs.getInt('homeColor') ?? Warna.homeColor.value);
  ColorManager.currentBackgroundColor = Color(
      prefs.getInt('backgroundColor') ?? Warna.backgroundColor.value);
}

void saveColors() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('primaryColor', ColorManager.currentPrimaryColor.value);
  prefs.setInt('accentColor', ColorManager.currentAccentColor.value);
  prefs.setInt('homeColor', ColorManager.currentHomeColor.value);
  prefs.setInt('backgroundColor', ColorManager.currentBackgroundColor.value);
}


class ColorPickerWidget extends StatefulWidget {
  @override
  _ColorPickerWidgetState createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  @override
  void initState() {
    super.initState();
    loadColors();
  }

  void _showColorPicker(
    BuildContext context,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Warna'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                saveColors(); // Save the selected color
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorButton(
    String buttonText,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    return GestureDetector(
      onTap: () {
        _showColorPicker(context, currentColor, (Color color) {
          setState(() {
            onColorChanged(color);
          });
        });
      },
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(buttonText),
            SizedBox(height: 8.0),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Color Picker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          children: [
            _buildColorButton(
              'Warna Premier',
              ColorManager.currentPrimaryColor,
              (Color color) {
                setState(() {
                  ColorManager.currentPrimaryColor = color;
                });
              },
            ),
            _buildColorButton(
              'Warna Sekunder',
              ColorManager.currentAccentColor,
              (Color color) {
                setState(() {
                  ColorManager.currentAccentColor = color;
                });
              },
            ),
            _buildColorButton(
              'Warna (Teks & lainnya)',
              ColorManager.currentHomeColor,
              (Color color) {
                setState(() {
                  ColorManager.currentHomeColor = color;
                });
              },
            ),
            _buildColorButton(
              'Warna Background',
              ColorManager.currentBackgroundColor,
              (Color color) {
                setState(() {
                  ColorManager.currentBackgroundColor = color;
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          saveColors();
          _showRestartDialog();
        },
        child: Icon(Icons.save),
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Perlu Tindakan!'),
          content: Text('Silakan klik Restart, untuk merubah warna.'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartApp();
              },
              child: Text('Restart'),
            ),
          ],
        );
      },
    );
  }

  void _restartApp() {
  saveColors(); // Save the selected colors
  runApp(MyApp()); // Restart the app by running the MyApp again
}
}

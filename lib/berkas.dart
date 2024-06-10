import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class BerkasWidget extends StatefulWidget {
  @override
  _BerkasWidgetState createState() => _BerkasWidgetState();
}

class _BerkasWidgetState extends State<BerkasWidget> {
  final FileManagerController controller = FileManagerController();
  final String niFlexPath = '/storage/emulated/0/Download/NiFlex';

  @override
  void initState() {
    super.initState();
    _initializeFileManager();
  }

  _initializeFileManager() async {
    // Request permission
    await FileManager.requestFilesAccessPermission();

    // Open NiFlex directory if it exists, otherwise show error
    Directory niFlexDirectory = Directory(niFlexPath);
    if (await niFlexDirectory.exists()) {
      controller.openDirectory(niFlexDirectory);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('NiFlex directory not found.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: Scaffold(
        appBar: appBar(context),
        body: FileManager(
          controller: controller,
          builder: (context, snapshot) {
            final List<FileSystemEntity> entities = snapshot;
            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              itemCount: entities.length,
              itemBuilder: (context, index) {
                FileSystemEntity entity = entities[index];
                return Card(
                  child: ListTile(
                    leading: FileManager.isFile(entity)
                        ? Icon(Icons.feed_outlined)
                        : Icon(Icons.folder),
                    title: Text(FileManager.basename(
                      entity,
                      showFileExtension: true,
                    )),
                    subtitle: subtitle(entity),
                    onTap: () async {
                      if (entity.path.startsWith(niFlexPath)) {
                        if (FileManager.isDirectory(entity)) {
                          controller.openDirectory(entity);
                        } else {
                          // Handle file tap
                        }
                      } else {
                        // Show error message if trying to open a directory outside NiFlex
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Error'),
                            content: Text('Access restricted to NiFlex directory only.'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      title: ValueListenableBuilder<String>(
        valueListenable: controller.titleNotifier,
        builder: (context, title, _) => Text(title),
      ),
    );
  }

  Widget subtitle(FileSystemEntity entity) {
    return FutureBuilder<FileStat>(
      future: entity.stat(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (entity is File) {
            int size = snapshot.data!.size;
            return Text(
              "${FileManager.formatBytes(size)}",
            );
          } else {
            return Text(
              "${snapshot.data!.modified}".substring(0, 10),
            );
          }
        } else {
          return Text("");
        }
      },
    );
  }
}

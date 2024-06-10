import 'package:flutter/material.dart';

class NotificationOverlay extends StatelessWidget {
  final VoidCallback onClose;

  NotificationOverlay({required this.onClose});

  bool isChatroomEnabled = true;
  bool isUpdateAnimeEnabled = true;
  bool isUpdateBeritaEnabled = true;
  bool isUpdateInfoEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAppBar(),
          _buildNotificationContent(),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false, // Disable the back button
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'NOTIFIKASI',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }

  Widget _buildNotificationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleListTile(
          title: 'Chatroom',
          value: isChatroomEnabled,
          onChanged: (value) {
            // Toggle the Chatroom feature
            isChatroomEnabled = value;
          },
        ),
        _buildToggleListTile(
          title: 'Update Anime',
          value: isUpdateAnimeEnabled,
          onChanged: (value) {
            // Toggle the Update Anime feature
            isUpdateAnimeEnabled = value;
          },
        ),
        _buildToggleListTile(
          title: 'Update Berita',
          value: isUpdateBeritaEnabled,
          onChanged: (value) {
            // Toggle the Update Berita feature
            isUpdateBeritaEnabled = value;
          },
        ),
        _buildToggleListTile(
          title: 'Update Info',
          value: isUpdateInfoEnabled,
          onChanged: (value) {
            // Toggle the Update Info feature
            isUpdateInfoEnabled = value;
          },
        ),
        SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildToggleListTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.center,
    );
  }
}

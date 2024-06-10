import 'package:flutter/material.dart';
import 'package:flue/color.dart';

class EpisodeListWidget extends StatelessWidget {
  final List<dynamic> episodes;
  final int currentEpisodeNumber;
  final Function(int) onEpisodeSelected;

  EpisodeListWidget({
    required this.episodes,
    required this.currentEpisodeNumber,
    required this.onEpisodeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.0),
      child: Container(
        height: 40.0, // Adjust the height as needed
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: episodes
                .map(
                  (episode) => buildEpisodeItem(episode, context),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget buildEpisodeItem(dynamic episode, BuildContext context) {
    bool isCurrentEpisode = episode['episode_number'] == currentEpisodeNumber;

    return GestureDetector(
      onTap: () => onEpisodeSelected(episode['episode_number']),
      child: Container(
        margin: EdgeInsets.only(
          left: 4.0,
          right: 4.0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrentEpisode ? ColorManager.currentPrimaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: isCurrentEpisode
                  ? [
                      BoxShadow(
                        color: ColorManager.currentPrimaryColor.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: EdgeInsets.all(6.0),
              child: Padding(
                padding:
                    EdgeInsets.only(bottom: 8.0), // Add padding to the bottom
                child: Text(
                  'E${episode['episode_number']}',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isCurrentEpisode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'info.dart';
import '../api_detail.dart';
import 'episode.dart';
import 'cuplikan.dart';
import 'package:flue/color.dart';

enum DetailCategory { Info, Episode, Cuplikan }

class ManageDetailWidget extends StatefulWidget {
  final int animeId;
  final String telegramId;
  final Map<String, dynamic> animeData;

  ManageDetailWidget({
    required this.animeData,
    required this.animeId,
    required this.telegramId,
  });

  @override
  _ManageDetailWidgetState createState() => _ManageDetailWidgetState();
}

class _ManageDetailWidgetState extends State<ManageDetailWidget> {
  DetailCategory selectedCategory = DetailCategory.Info;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swipe right
          changeCategory(selectedCategory.index - 1);
        } else if (details.primaryVelocity! < 0) {
          // Swipe left
          changeCategory(selectedCategory.index + 1);
        }
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            color: ColorManager.currentAccentColor,
            child: Row(
              children: DetailCategory.values
                  .map((category) => buildCategoryButton(category))
                  .toList(),
            ),
          ),
          SizedBox(height: 10.0),
          buildSelectedContent(),
        ],
      ),
    );
  }

  Widget buildCategoryButton(DetailCategory category) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: category == selectedCategory
                  ? ColorManager.currentPrimaryColor
                  : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: TextButton(
          onPressed: () => handleCategoryPress(category),
          style: TextButton.styleFrom(
            textStyle: TextStyle(
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
          child: Text(
            category.toString().split('.').last,
            style: TextStyle(
              color: category == selectedCategory ? ColorManager.currentPrimaryColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void handleCategoryPress(DetailCategory category) {
    setState(() {
      selectedCategory = category;
    });
  }

  void changeCategory(int index) {
    if (index >= 0 && index < DetailCategory.values.length) {
      setState(() {
        selectedCategory = DetailCategory.values[index];
      });
    }
  }

  Widget buildSelectedContent() {
    switch (selectedCategory) {
      case DetailCategory.Info:
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: SingleChildScrollView(
              child: InfoWidget(
                animeId: widget.animeId,
                telegramId: widget.telegramId,
                animeData: widget.animeData,
                
              ),
            ),
        );
      case DetailCategory.Episode:
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0),
              child: EpisodeWidget(
                animeId: widget.animeId,
                telegramId: widget.telegramId,
                animeData: widget.animeData,
              ),
            ),
          ),
        );
      case DetailCategory.Cuplikan:
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CuplikanWidget(
                animeData: widget.animeData,
                animeId: widget.animeId,
              ),
            ),
          ),
        );
      default:
        return Container();
    }
  }
}

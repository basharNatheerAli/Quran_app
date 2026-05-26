import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class HadithDetailScreen extends StatefulWidget {
  final RiyadHadith riyadHadith;
  final int index;

  const HadithDetailScreen({
    Key? key,
    required this.riyadHadith,
    required this.index,
  }) : super(key: key);

  @override
  _HadithDetailScreenState createState() => _HadithDetailScreenState();
}

class _HadithDetailScreenState extends State<HadithDetailScreen> {
  double _fontSizeMultiplier = 1.0;
  double _baseFontSizeMultiplier = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الحديث ${widget.index + 1}'),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              final isFav = provider.isFavoriteHadith(widget.riyadHadith.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: AppColors.primaryDark,
                ),
                onPressed: () {
                  provider.toggleFavoriteHadith(widget.riyadHadith.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? 'تم إزالة الحديث من المفضلة'
                            : 'تم إضافة الحديث للمفضلة',
                      ),
                      backgroundColor: AppColors.primaryDark,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onScaleStart: (details) {
          _baseFontSizeMultiplier = _fontSizeMultiplier;
        },
        onScaleUpdate: (details) {
          setState(() {
            _fontSizeMultiplier = (_baseFontSizeMultiplier * details.scale)
                .clamp(0.5, 3.0);
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.riyadHadith.textArabic,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: AppStyles.titleSize * _fontSizeMultiplier,
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../models/models.dart';
import 'hadith_detail_screen.dart';

class HadithListScreen extends StatelessWidget {
  final RiyadChapter chapter;

  const HadithListScreen({Key? key, required this.chapter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapter.titleArabic)),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final hadiths = provider.riyadHadithsByChapter[chapter.id] ?? [];

          if (hadiths.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد أحاديث في هذه الفئة',
                style: TextStyle(fontFamily: 'Amiri', fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hadiths.length,
            itemBuilder: (context, index) {
              final hadith = hadiths[index];

              // Extract a short preview of the hadith text
              String preview = hadith.textArabic.split('\n').first;
              if (preview.length > 50) {
                preview = preview.substring(0, 50) + '...';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: AppStyles.defaultBorderRadius,
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    'الحديث ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppStyles.subtitleSize,
                      color: AppColors.text,
                    ),
                  ),
                  subtitle: Text(
                    preview,
                    style: const TextStyle(color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      provider.isFavoriteHadith(hadith.id)
                          ? Icons.star
                          : Icons.star_border,
                      color: AppColors.primaryDark,
                    ),
                    onPressed: () {
                      provider.toggleFavoriteHadith(hadith.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.isFavoriteHadith(hadith.id)
                                ? 'تم إضافة الحديث للمفضلة'
                                : 'تم إزالة الحديث من المفضلة',
                          ),
                          backgroundColor: AppColors.primaryDark,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HadithDetailScreen(
                          riyadHadith: hadith,
                          index: index,
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
            },
          );
        },
      ),
    );
  }
}

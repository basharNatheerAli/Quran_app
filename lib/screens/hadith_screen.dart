import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'hadith_list_screen.dart';
import 'bookmarks_screen.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رياض الصالحين'),
        leading: IconButton(
          icon: const Icon(Icons.bookmarks),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookmarksScreen(initialIndex: 1)),
            );
          },
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final chapters = provider.riyadChapters;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              final hadithCount =
                  provider.riyadHadithsByChapter[chapter.id]?.length ?? 0;

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
                    child: const Icon(
                      Icons.menu_book,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: Text(
                    chapter.titleArabic,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppStyles.subtitleSize,
                      color: AppColors.text,
                    ),
                  ),
                  subtitle: Text(
                    'عدد الأحاديث: $hadithCount',
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HadithListScreen(chapter: chapter),
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

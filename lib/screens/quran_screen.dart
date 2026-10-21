import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:flutter_animate/flutter_animate.dart';
import 'surah_screen.dart';
import '../utils/constants.dart';
import 'bookmarks_screen.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'quran_search_delegate.dart';
import '../widgets/main_drawer.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text('رفيق المسلم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookmarksScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: QuranSearchDelegate(),
              );
              if (result != null && result['surah'] != null) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurahScreen(
                        surahNumber: result['surah']!,
                        highlightVerse: result['verse'],
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              if (provider.recentSurahs.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  Text(
                    "آخر السور التي قرأتها",
                    style: TextStyle(
                      fontSize: AppStyles.subtitleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  Container(
                    height: 60,
                    color: AppColors.primary.withOpacity(0.05),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: provider.recentSurahs.length,
                      itemBuilder: (context, index) {
                        final surahNumber = provider.recentSurahs[index];
                        final hasSavedPage = provider.hasSurahLastPage(
                          surahNumber,
                        );
                        final lastPage = provider.getSurahLastPage(surahNumber);
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ActionChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  quran.getSurahNameArabic(surahNumber),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                if (hasSavedPage) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'ص $lastPage',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            backgroundColor: Colors.white,
                            elevation: 1,
                            side: const BorderSide(
                              color: AppColors.primaryDark,
                              width: 1,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SurahScreen(
                                    surahNumber: surahNumber,
                                    initialPage: lastPage,
                                    openLastPage: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: quran.totalSurahCount,
              itemBuilder: (context, index) {
                int surahNumber = index + 1;
                return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppStyles.defaultBorderRadius,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            surahNumber.toString(),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        title: Text(
                          quran.getSurahNameArabic(surahNumber),
                          style: const TextStyle(
                            fontSize: AppStyles.titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "اياتها: ${quran.getVerseCount(surahNumber)} - ${quran.getPlaceOfRevelation(surahNumber) == 'Makkah' ? 'مكية' : 'مدنية'}",
                          style: const TextStyle(color: AppColors.textLight),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SurahScreen(surahNumber: surahNumber),
                            ),
                          );
                        },
                      ),
                    )
                    .animate()
                    .fadeIn(
                      duration: 200.ms,
                      delay: Duration(milliseconds: 50 * index % 200),
                    )
                    .slideX(begin: 0.2, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

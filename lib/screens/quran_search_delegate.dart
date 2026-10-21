import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../utils/constants.dart';

class QuranSearchDelegate extends SearchDelegate<Map<String, int>?> {
  @override
  String get searchFieldLabel => 'ابحث في القرآن الكريم...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'اكتب كلمة للبحث عنها في القرآن الكريم',
          style: TextStyle(color: AppColors.textLight, fontSize: 16),
        ),
      );
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) return const SizedBox();

    int totalOccurrences = 0;
    final List<Map<String, dynamic>> results = [];
    final String searchWord = query.trim();
    final String cleanQuery = _normalizeArabic(searchWord);

    if (cleanQuery.isEmpty) return const SizedBox();

    // Search across all surahs and verses
    for (int surah = 1; surah <= 114; surah++) {
      final int verseCount = quran.getVerseCount(surah);
      for (int verse = 1; verse <= verseCount; verse++) {
        final String verseText = quran.getVerse(surah, verse, verseEndSymbol: false);
        final String cleanVerseText = _normalizeArabic(verseText);
        final int occurrences = _countOccurrences(cleanVerseText, cleanQuery);

        if (occurrences > 0) {
          totalOccurrences += occurrences;
          results.add({
            'surah': surah,
            'verse': verse,
            'text': verseText,
            'surahName': quran.getSurahNameArabic(surah),
            'occurrences': occurrences,
          });
        }
      }
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'لم يتم العثور على نتائج لـ "$query"',
              style: const TextStyle(color: AppColors.textLight, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'عدد النتائج: 0',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.format_list_numbered_rtl,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'نتائج البحث: $totalOccurrences مرة',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'في ${results.length} آية',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.defaultBorderRadius),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    result['text'],
                    style: const TextStyle(
                      fontFamily: 'Amiri', // assuming Amiri is used, or fallback
                      fontSize: 20,
                      height: 1.8,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'سورة ${result['surahName']}',
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'آية ${result['verse']}',
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (result['occurrences'] > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.shade400,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              result['occurrences'] == 2
                                  ? 'تكررت مرتين'
                                  : 'تكررت ${result['occurrences']} مرات',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  onTap: () {
                    close(context, {
                      'surah': result['surah'],
                      'verse': result['verse'],
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _normalizeArabic(String text) {
    // Regex to match Arabic diacritics (tashkeel and Quranic annotations)
    final RegExp diacriticsRegExp = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]');
    String clean = text.replaceAll(diacriticsRegExp, '');
    // Normalize Alef variations (أ, إ, آ, ٱ -> ا)
    clean = clean.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    // Normalize Yeh / Alef Maksura (ى -> ي)
    clean = clean.replaceAll(RegExp(r'[ى]'), 'ي');
    return clean;
  }

  int _countOccurrences(String text, String query) {
    if (query.isEmpty) return 0;
    int count = 0;
    int index = 0;
    while ((index = text.indexOf(query, index)) != -1) {
      count++;
      index += query.length;
    }
    return count;
  }
}

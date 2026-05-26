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

    final List<Map<String, dynamic>> results = [];
    final String searchWord = query.trim();

    // Search across all surahs and verses
    for (int surah = 1; surah <= 114; surah++) {
      final int verseCount = quran.getVerseCount(surah);
      for (int verse = 1; verse <= verseCount; verse++) {
        final String verseText = quran.getVerse(surah, verse, verseEndSymbol: false);
        // Using contains instead of regex for simplicity and speed
        // To handle diacritics we might want a more advanced search, 
        // but for now, we'll strip diacritics for search or just do direct match.
        // Stripping diacritics is better for Arabic search.
        final String cleanVerseText = _removeDiacritics(verseText);
        final String cleanQuery = _removeDiacritics(searchWord);
        
        if (cleanVerseText.contains(cleanQuery)) {
          results.add({
            'surah': surah,
            'verse': verse,
            'text': verseText,
            'surahName': quran.getSurahNameArabic(surah),
          });
        }
      }
    }

    if (results.isEmpty) {
      return Center(
        child: Text(
          'لم يتم العثور على نتائج لـ "$query"',
          style: const TextStyle(color: AppColors.textLight, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
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
                      color: AppColors.primary.withOpacity(0.1),
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
                      color: AppColors.primary.withOpacity(0.1),
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
    );
  }

  String _removeDiacritics(String text) {
    // Regex to match Arabic diacritics (tashkeel)
    final RegExp diacriticsRegExp = RegExp(r'[\u064B-\u065F\u0670]');
    return text.replaceAll(diacriticsRegExp, '');
  }
}

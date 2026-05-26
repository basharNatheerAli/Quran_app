import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'surah_screen.dart';
import 'hadith_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  final int initialIndex;

  const BookmarksScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحفوظات'),
          bottom: const TabBar(
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primaryDark,
            tabs: [
              Tab(text: 'الآيات'),
              Tab(text: 'الأحاديث'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AyahsTab(),
            _HadithsTab(),
          ],
        ),
      ),
    );
  }
}

class _AyahsTab extends StatelessWidget {
  const _AyahsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Last Read Container
          Card(
            shape: RoundedRectangleBorder(borderRadius: AppStyles.defaultBorderRadius),
            elevation: 2,
            child: InkWell(
              borderRadius: AppStyles.defaultBorderRadius,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahScreen(
                      surahNumber: provider.lastReadSurah,
                      highlightVerse: provider.lastReadAyah,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('آخر قراءة', style: TextStyle(fontSize: AppStyles.titleSize, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'سورة ${quran.getSurahNameArabic(provider.lastReadSurah)} - الآية ${provider.lastReadAyah}',
                            style: const TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: AppColors.primaryDark, size: 16),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Favorite Ayahs Container
          Card(
            shape: RoundedRectangleBorder(borderRadius: AppStyles.defaultBorderRadius),
            elevation: 2,
            child: InkWell(
              borderRadius: AppStyles.defaultBorderRadius,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoriteAyahsScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الآيات المفضلة', style: TextStyle(fontSize: AppStyles.titleSize, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            '${provider.favoriteAyahs.length} آية محفوظة',
                            style: const TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: AppColors.primaryDark, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithsTab extends StatelessWidget {
  const _HadithsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.favoriteHadiths.isEmpty) {
          return const Center(
            child: Text('لا توجد أحاديث مفضلة حالياً', style: TextStyle(fontSize: 18)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.favoriteHadiths.length,
          itemBuilder: (context, index) {
            final idStr = provider.favoriteHadiths[index];
            final id = int.tryParse(idStr) ?? 0;
            final hadith = provider.allRiyadHadithsMap[id];
            
            if (hadith == null) return const SizedBox.shrink();

            String preview = hadith.textArabic.split('\n').first;
            if (preview.length > 50) {
              preview = preview.substring(0, 50) + '...';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: AppStyles.defaultBorderRadius),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.star, color: AppColors.primaryDark),
                ),
                title: const Text(
                  'حديث محفوظ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppStyles.subtitleSize, color: AppColors.text),
                ),
                subtitle: Text(
                  preview,
                  style: const TextStyle(color: AppColors.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    provider.toggleFavoriteHadith(id);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HadithDetailScreen(
                        riyadHadith: hadith,
                        index: 0,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class FavoriteAyahsScreen extends StatelessWidget {
  const FavoriteAyahsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الآيات المفضلة'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.favoriteAyahs.isEmpty) {
            return const Center(
              child: Text('لا توجد آيات مفضلة حالياً', style: TextStyle(fontSize: 18)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.favoriteAyahs.length,
            itemBuilder: (context, index) {
              final itemStr = provider.favoriteAyahs[index];
              final item = json.decode(itemStr);
              final surah = item['surah'] as int;
              final ayah = item['ayah'] as int;
              
              final verseText = quran.getVerse(surah, ayah, verseEndSymbol: true);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: AppStyles.defaultBorderRadius),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    'سورة ${quran.getSurahNameArabic(surah)} - الآية $ayah',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      verseText,
                      style: const TextStyle(fontSize: 18, color: AppColors.text, height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      provider.toggleFavoriteAyah(surah, ayah);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurahScreen(
                          surahNumber: surah,
                          highlightVerse: ayah,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'package:flutter/gestures.dart';

String cleanVerse(int surahNumber, int verseNumber, String verseText) {
  if (verseNumber == 1 && surahNumber != 1 && surahNumber != 9) {
    const basmala1 = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ ';
    const basmala2 = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ';
    if (verseText.startsWith(basmala1)) {
      return verseText.substring(basmala1.length);
    } else if (verseText.startsWith(basmala2)) {
      return verseText.substring(basmala2.length);
    }
  }
  return verseText;
}

class SurahScreen extends StatefulWidget {
  final int surahNumber;
  final int? highlightVerse;
  final int? initialPage;
  final bool openLastPage;

  const SurahScreen({
    Key? key,
    required this.surahNumber,
    this.highlightVerse,
    this.initialPage,
    this.openLastPage = false,
  }) : super(key: key);

  @override
  _SurahScreenState createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> with WidgetsBindingObserver {
  double _fontSizeMultiplier = 1.0;
  double _baseFontSizeMultiplier = 1.0;
  late int _currentSurahNumber;
  late int _currentMushafPage;
  late bool _isPageMode;
  late AppProvider _provider;
  late PageController _surahPageController;
  late PageController _mushafPageController;
  Timer? _readingTimer;
  int? _targetVerseForContinuous;

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.surahNumber;

    final appProv = Provider.of<AppProvider>(context, listen: false);
    if (widget.openLastPage || widget.initialPage != null) {
      _isPageMode = true;
      _currentMushafPage = widget.initialPage ?? appProv.getSurahLastPage(_currentSurahNumber);
    } else {
      _isPageMode = appProv.isQuranPageMode;
      if (_isPageMode) {
        _currentMushafPage = appProv.getSurahLastPage(_currentSurahNumber);
      } else {
        _currentMushafPage = quran.getSurahPages(_currentSurahNumber).first;
      }
    }

    if (widget.highlightVerse != null) {
      final versePage = quran.getPageNumber(_currentSurahNumber, widget.highlightVerse!);
      if (_isPageMode) {
        _currentMushafPage = versePage;
      }
    }

    _surahPageController = PageController(initialPage: widget.surahNumber - 1);
    _mushafPageController = PageController(initialPage: (_currentMushafPage - 1).clamp(0, 603));
    WidgetsBinding.instance.addObserver(this);
    _startTimer();

    // Enable both portrait and landscape orientation when reading Quran
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Add initial surah to recents
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider.addRecentSurah(_currentSurahNumber);
        if (_isPageMode) {
          _provider.saveSurahLastPage(_currentSurahNumber, _currentMushafPage);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = Provider.of<AppProvider>(context, listen: false);
  }

  void _startTimer() {
    _readingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _provider.incrementReadingTime();
      }
    });
  }

  void _stopTimer() {
    _readingTimer?.cancel();
    _readingTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else if (state == AppLifecycleState.paused) {
      _stopTimer();
      if (_isPageMode) {
        _provider.saveSurahLastPage(_currentSurahNumber, _currentMushafPage);
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    if (_isPageMode) {
      _provider.saveSurahLastPage(_currentSurahNumber, _currentMushafPage);
    }
    _surahPageController.dispose();
    _mushafPageController.dispose();
    // Reset orientation back to portrait when leaving the reading screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _toggleViewMode() {
    int? targetVerse;
    if (_isPageMode) {
      // Find starting verse on current mushaf page for _currentSurahNumber
      final pageData = quran.getPageData(_currentMushafPage);
      for (final section in pageData) {
        if (section['surah'] == _currentSurahNumber) {
          targetVerse = section['start'] as int;
          break;
        }
      }
      if (targetVerse == null && pageData.isNotEmpty) {
        targetVerse = pageData.first['start'] as int;
      }
    }

    setState(() {
      _isPageMode = !_isPageMode;
      if (!_isPageMode) {
        _targetVerseForContinuous = targetVerse;
      }
    });
    _provider.setQuranPageMode(_isPageMode);

    if (_isPageMode) {
      // Switched to page mode
      final targetPage = _provider.getSurahLastPage(_currentSurahNumber);
      _currentMushafPage = targetPage;
      _provider.saveSurahLastPage(_currentSurahNumber, _currentMushafPage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mushafPageController.hasClients) {
          _mushafPageController.jumpToPage((_currentMushafPage - 1).clamp(0, 603));
        }
      });
    } else {
      // Switched to continuous mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_surahPageController.hasClients) {
          _surahPageController.jumpToPage((_currentSurahNumber - 1).clamp(0, 113));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (_isPageMode) {
          _provider.saveSurahLastPage(_currentSurahNumber, _currentMushafPage);
        }
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(quran.getSurahNameArabic(_currentSurahNumber)),
              if (_isPageMode)
                Text(
                  'صفحة $_currentMushafPage',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isPageMode ? Icons.format_align_justify : Icons.auto_stories,
              ),
              tooltip: _isPageMode ? 'عرض كسورة كاملة' : 'عرض على صفحات',
              onPressed: _toggleViewMode,
            ),
            IconButton(
              icon: Icon(
                MediaQuery.of(context).orientation == Orientation.landscape
                    ? Icons.stay_current_portrait
                    : Icons.stay_current_landscape,
              ),
              tooltip:
                  MediaQuery.of(context).orientation == Orientation.landscape
                      ? 'الوضع الرأسي'
                      : 'الوضع الأفقي',
              onPressed: () {
                final isLandscape =
                    MediaQuery.of(context).orientation == Orientation.landscape;
                if (isLandscape) {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown,
                  ]);
                } else {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]);
                }
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
          child: _isPageMode
              ? Directionality(
                  textDirection: TextDirection.rtl,
                  child: PageView.builder(
                    controller: _mushafPageController,
                    itemCount: 604,
                    onPageChanged: (index) {
                      final pageNum = index + 1;
                      setState(() {
                        _currentMushafPage = pageNum;
                        final pageData = quran.getPageData(pageNum);
                        if (pageData.isNotEmpty) {
                          final surahsOnPage = pageData
                              .map((e) => e['surah'] as int)
                              .toList();
                          if (!surahsOnPage.contains(_currentSurahNumber)) {
                            _currentSurahNumber = surahsOnPage.first;
                          }
                        }
                      });
                      _provider.saveSurahLastPage(_currentSurahNumber, pageNum);
                      _provider.addRecentSurah(_currentSurahNumber);
                    },
                    itemBuilder: (context, index) {
                      return QuranPageContent(
                        pageNumber: index + 1,
                        fontSizeMultiplier: _fontSizeMultiplier,
                        highlightSurah: widget.surahNumber,
                        highlightVerse: widget.highlightVerse,
                        onAyahTap: (surah, ayah) =>
                            _showAyahBottomSheet(context, surah, ayah),
                      );
                    },
                  ),
                )
              : PageView.builder(
                  controller: _surahPageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 114,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSurahNumber = index + 1;
                      _targetVerseForContinuous = null;
                    });
                    _provider.addRecentSurah(_currentSurahNumber);
                  },
                  itemBuilder: (context, index) {
                    final surahNum = index + 1;
                    final int? verseToHighlight = (surahNum == _currentSurahNumber)
                        ? (_targetVerseForContinuous ??
                            (surahNum == widget.surahNumber
                                ? widget.highlightVerse
                                : null))
                        : null;
                    return SurahPageContent(
                      key: ValueKey('surah_${surahNum}_verse_$verseToHighlight'),
                      surahNumber: surahNum,
                      highlightVerse: verseToHighlight,
                      fontSizeMultiplier: _fontSizeMultiplier,
                      onAyahTap: (surah, ayah) =>
                          _showAyahBottomSheet(context, surah, ayah),
                    );
                  },
                ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical:
                    MediaQuery.of(context).orientation == Orientation.landscape
                        ? 4.0
                        : 8.0,
              ),
              child: _isPageMode ? _buildPageNavRow() : _buildSurahNavRow(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNavRow() {
    final bool canGoNext = _currentMushafPage < 604;
    final bool canGoPrev = _currentMushafPage > 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNavButton(
          isNext: false,
          title: 'السابقة',
          subtitle: canGoPrev ? 'صفحة ${_currentMushafPage - 1}' : null,
          onTap: canGoPrev ? () => _goToMushafPage(_currentMushafPage - 1) : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'صفحة $_currentMushafPage من 604',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        _buildNavButton(
          isNext: true,
          title: 'التالية',
          subtitle: canGoNext ? 'صفحة ${_currentMushafPage + 1}' : null,
          onTap: canGoNext ? () => _goToMushafPage(_currentMushafPage + 1) : null,
        ),
      ],
    );
  }

  Widget _buildSurahNavRow() {
    final bool canGoNext = _currentSurahNumber < 114;
    final bool canGoPrev = _currentSurahNumber > 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSurahNavButton(
          isNext: false,
          targetSurahName: _currentSurahNumber > 1
              ? quran.getSurahNameArabic(_currentSurahNumber - 1)
              : null,
          onTap: canGoPrev ? () => _goToSurah(_currentSurahNumber - 1) : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'سورة $_currentSurahNumber من 114',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        _buildSurahNavButton(
          isNext: true,
          targetSurahName: _currentSurahNumber < 114
              ? quran.getSurahNameArabic(_currentSurahNumber + 1)
              : null,
          onTap: canGoNext ? () => _goToSurah(_currentSurahNumber + 1) : null,
        ),
      ],
    );
  }

  void _goToMushafPage(int page) {
    if (page < 1 || page > 604) return;
    _mushafPageController.animateToPage(
      page - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToSurah(int surahNumber) {
    if (surahNumber < 1 || surahNumber > 114) return;
    _surahPageController.animateToPage(
      surahNumber - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildNavButton({
    required bool isNext,
    required String title,
    required String? subtitle,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isNext
                ? [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isEnabled
                                ? AppColors.primaryDark
                                : Colors.grey.shade400,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isEnabled
                                  ? AppColors.text
                                  : Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 14,
                      color: isEnabled
                          ? AppColors.primaryDark
                          : Colors.grey.shade400,
                    ),
                  ]
                : [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isEnabled
                          ? AppColors.primaryDark
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isEnabled
                                ? AppColors.primaryDark
                                : Colors.grey.shade400,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isEnabled
                                  ? AppColors.text
                                  : Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahNavButton({
    required bool isNext,
    required VoidCallback? onTap,
    required String? targetSurahName,
  }) {
    return _buildNavButton(
      isNext: isNext,
      title: isNext ? 'التالية' : 'السابقة',
      subtitle: targetSurahName,
      onTap: onTap,
    );
  }

  void _showAyahBottomSheet(
    BuildContext context,
    int surahNumber,
    int ayahNumber,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'سورة ${quran.getSurahNameArabic(surahNumber)} - الآية $ayahNumber',
                    style: const TextStyle(
                      fontSize: AppStyles.titleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildActionIcon(
                        icon: Icons.bookmark_add,
                        label: 'آخر قراءة',
                        onTap: () {
                          final prov = Provider.of<AppProvider>(
                            context,
                            listen: false,
                          );
                          prov.saveLastRead(surahNumber, ayahNumber);
                          final page = quran.getPageNumber(surahNumber, ayahNumber);
                          prov.saveSurahLastPage(surahNumber, page);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم الحفظ كآخر قراءة'),
                              backgroundColor: AppColors.primaryDark,
                            ),
                          );
                        },
                      ),
                      Consumer<AppProvider>(
                        builder: (context, provider, _) {
                          final isFav = provider.isFavoriteAyah(
                            surahNumber,
                            ayahNumber,
                          );
                          return _buildActionIcon(
                            icon: isFav ? Icons.favorite : Icons.favorite_border,
                            label: 'مفضلة',
                            onTap: () {
                              provider.toggleFavoriteAyah(
                                surahNumber,
                                ayahNumber,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم تحديث قائمة الآيات المفضلة'),
                                  backgroundColor: AppColors.primaryDark,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      _buildActionIcon(
                        icon: Icons.copy,
                        label: 'نسخ',
                        onTap: () {
                          final verseText = quran.getVerse(
                            surahNumber,
                            ayahNumber,
                            verseEndSymbol: true,
                          );
                          Clipboard.setData(ClipboardData(text: verseText));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ الآية'),
                              backgroundColor: AppColors.primaryDark,
                            ),
                          );
                        },
                      ),
                      _buildActionIcon(
                        icon: Icons.play_circle_fill,
                        label: 'استماع',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'ميزة الاستماع للآية ستتوفر قريباً',
                              ),
                              backgroundColor: AppColors.primaryDark,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class QuranPageContent extends StatelessWidget {
  final int pageNumber;
  final double fontSizeMultiplier;
  final int? highlightSurah;
  final int? highlightVerse;
  final void Function(int surah, int ayah) onAyahTap;

  const QuranPageContent({
    Key? key,
    required this.pageNumber,
    required this.fontSizeMultiplier,
    this.highlightSurah,
    this.highlightVerse,
    required this.onAyahTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageData = quran.getPageData(pageNumber);
    if (pageData.isEmpty) {
      return const SizedBox();
    }

    final firstSurah = pageData.first['surah'] as int;
    final firstAyah = pageData.first['start'] as int;
    final juzNumber = quran.getJuzNumber(firstSurah, firstAyah);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Bar: Juz & Surah
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الجزء $juzNumber',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'سورة ${quran.getSurahNameArabic(firstSurah)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sections on this page
                for (final section in pageData) ...[
                  _buildPageSection(context, section),
                ],

                // Footer with page number
                Padding(
                  padding: const EdgeInsets.only(top: 14.0, bottom: 4.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '— $pageNumber —',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageSection(BuildContext context, Map<String, dynamic> section) {
    final int surah = section['surah'] as int;
    final int start = section['start'] as int;
    final int end = section['end'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Surah header banner if surah starts on this page
        if (start == 1) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آياتها ${quran.getVerseCount(surah)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'سورة ${quran.getSurahNameArabic(surah)}',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  quran.getPlaceOfRevelation(surah) == 'Makkah' ? 'مكية' : 'مدنية',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          if (surah != 1 && surah != 9)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
              child: Text(
                quran.basmala,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: AppStyles.titleSize * fontSizeMultiplier,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
        ],

        // Verses
        Text.rich(
          TextSpan(
            children: [
              for (int i = start; i <= end; i++) ...[
                TextSpan(
                  text: '${cleanVerse(
                    surah,
                    i,
                    quran.getVerse(
                      surah,
                      i,
                      verseEndSymbol: false,
                    ),
                  )} ',
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: AppStyles.titleSize * fontSizeMultiplier,
                    color: AppColors.text,
                    height: 2.2,
                    backgroundColor:
                        (surah == highlightSurah && i == highlightVerse)
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Colors.transparent,
                  ),
                ),
                TextSpan(
                  text: '${quran.getVerseEndSymbol(i, arabicNumeral: true)} ',
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    color: AppColors.primaryDark,
                    fontSize: AppStyles.titleSize * fontSizeMultiplier,
                    backgroundColor:
                        (surah == highlightSurah && i == highlightVerse)
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Colors.transparent,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => onAyahTap(surah, i),
                ),
              ],
            ],
          ),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

class SurahPageContent extends StatefulWidget {
  final int surahNumber;
  final int? highlightVerse;
  final double fontSizeMultiplier;
  final void Function(int surah, int ayah) onAyahTap;

  const SurahPageContent({
    Key? key,
    required this.surahNumber,
    this.highlightVerse,
    required this.fontSizeMultiplier,
    required this.onAyahTap,
  }) : super(key: key);

  @override
  _SurahPageContentState createState() => _SurahPageContentState();
}

class _SurahPageContentState extends State<SurahPageContent> {
  final ScrollController _scrollController = ScrollController();
  late AppProvider _provider;

  @override
  void initState() {
    super.initState();
    _initSurah();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = Provider.of<AppProvider>(context, listen: false);
  }

  void _initSurah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.highlightVerse != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _scrollToVerse();
        });
      } else {
        final offset = _provider.getSurahScrollOffset(widget.surahNumber);
        if (offset > 0) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                offset,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    if (_scrollController.hasClients) {
      _provider.saveSurahScrollOffset(
        widget.surahNumber,
        _scrollController.offset,
      );
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToVerse() {
    if (widget.highlightVerse == null || !_scrollController.hasClients) return;

    if (!_scrollController.position.hasContentDimensions ||
        _scrollController.position.maxScrollExtent <= 0) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _scrollToVerse();
      });
      return;
    }

    if (widget.highlightVerse == 1) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      return;
    }

    int totalChars = 0;
    int charsBefore = 0;
    int verseCount = quran.getVerseCount(widget.surahNumber);

    for (int i = 1; i <= verseCount; i++) {
      String verseText = quran.getVerse(
        widget.surahNumber,
        i,
        verseEndSymbol: false,
      );
      int length = verseText.length + 5;

      if (i < widget.highlightVerse!) {
        charsBefore += length;
      }
      totalChars += length;
    }

    if (totalChars > 0) {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double offset = (charsBefore / totalChars) * maxScroll;
      offset = (offset - 40).clamp(0.0, maxScroll);

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int verseCount = quran.getVerseCount(widget.surahNumber);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.surahNumber != 1 && widget.surahNumber != 9)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    quran.basmala,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: AppStyles.titleSize * widget.fontSizeMultiplier,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
              Text.rich(
                TextSpan(
                  children: [
                    for (int i = 1; i <= verseCount; i++) ...[
                      TextSpan(
                        text: '${cleanVerse(
                          widget.surahNumber,
                          i,
                          quran.getVerse(
                            widget.surahNumber,
                            i,
                            verseEndSymbol: false,
                          ),
                        )} ',
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize:
                              AppStyles.titleSize * widget.fontSizeMultiplier,
                          color: AppColors.text,
                          height: 2.2,
                          backgroundColor: widget.highlightVerse == i
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      TextSpan(
                        text: '${quran.getVerseEndSymbol(i, arabicNumeral: true)} ',
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          color: AppColors.primaryDark,
                          fontSize:
                              AppStyles.titleSize * widget.fontSizeMultiplier,
                          backgroundColor: widget.highlightVerse == i
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => widget.onAyahTap(widget.surahNumber, i),
                      ),
                    ],
                  ],
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

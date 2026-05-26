import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'package:flutter/gestures.dart';

class SurahScreen extends StatefulWidget {
  final int surahNumber;
  final int? highlightVerse;

  const SurahScreen({Key? key, required this.surahNumber, this.highlightVerse})
      : super(key: key);

  @override
  _SurahScreenState createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> with WidgetsBindingObserver {
  double _fontSizeMultiplier = 1.0;
  double _baseFontSizeMultiplier = 1.0;
  late int _currentSurahNumber;
  late AppProvider _provider;
  late PageController _pageController;
  Timer? _readingTimer;

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.surahNumber;
    _pageController = PageController(initialPage: widget.surahNumber - 1);
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    
    // Add initial surah to recents
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AppProvider>(context, listen: false).addRecentSurah(_currentSurahNumber);
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
    }
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quran.getSurahNameArabic(_currentSurahNumber)),
      ),
      body: GestureDetector(
        onScaleStart: (details) {
          _baseFontSizeMultiplier = _fontSizeMultiplier;
        },
        onScaleUpdate: (details) {
          setState(() {
            _fontSizeMultiplier = (_baseFontSizeMultiplier * details.scale).clamp(0.5, 3.0);
          });
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: 114,
          onPageChanged: (index) {
            setState(() {
              _currentSurahNumber = index + 1;
            });
            _provider.addRecentSurah(_currentSurahNumber);
          },
          itemBuilder: (context, index) {
            return SurahPageContent(
              surahNumber: index + 1,
              highlightVerse: (index + 1 == widget.surahNumber) ? widget.highlightVerse : null,
              fontSizeMultiplier: _fontSizeMultiplier,
            );
          },
        ),
      ),
    );
  }
}

class SurahPageContent extends StatefulWidget {
  final int surahNumber;
  final int? highlightVerse;
  final double fontSizeMultiplier;

  const SurahPageContent({
    Key? key,
    required this.surahNumber,
    this.highlightVerse,
    required this.fontSizeMultiplier,
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
      offset = (offset - 50).clamp(0.0, maxScroll);

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  String _cleanVerse(int surahNumber, int verseNumber, String verseText) {
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

  void _showAyahBottomSheet(BuildContext context, int ayahNumber) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الآية رقم ${ayahNumber}',
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
                      Provider.of<AppProvider>(
                        context,
                        listen: false,
                      ).saveLastRead(widget.surahNumber, ayahNumber);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم الحفظ كآخر قراءة'),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    },
                  ),
                  _buildActionIcon(
                    icon: Provider.of<AppProvider>(
                          context,
                          listen: false,
                        ).isFavoriteAyah(widget.surahNumber, ayahNumber)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: 'مفضلة',
                    onTap: () {
                      Provider.of<AppProvider>(
                        context,
                        listen: false,
                      ).toggleFavoriteAyah(widget.surahNumber, ayahNumber);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث قائمة الآيات المفضلة'),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    },
                  ),
                  _buildActionIcon(
                    icon: Icons.copy,
                    label: 'نسخ',
                    onTap: () {
                      final verseText = quran.getVerse(
                        widget.surahNumber,
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
                          content: Text('ميزة الاستماع للآية ستتوفر قريباً'),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
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
              color: AppColors.primary.withOpacity(0.1),
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
                        text: _cleanVerse(
                              widget.surahNumber,
                              i,
                              quran.getVerse(
                                widget.surahNumber,
                                i,
                                verseEndSymbol: false,
                              ),
                            ) +
                            ' ',
                        style: TextStyle(
                          fontSize: AppStyles.titleSize * widget.fontSizeMultiplier,
                          color: AppColors.text,
                          height: 2.0,
                          backgroundColor: widget.highlightVerse == i
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      TextSpan(
                        text: quran.getVerseEndSymbol(
                              i,
                              arabicNumeral: true,
                            ) +
                            ' ',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: AppStyles.titleSize * widget.fontSizeMultiplier,
                          backgroundColor: widget.highlightVerse == i
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showAyahBottomSheet(context, i),
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

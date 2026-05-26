import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// Top-level function for compute
Map<String, dynamic> _parseRiyadData(String jsonString) {
  final data = json.decode(jsonString);
  final chaptersList = data['chapters'] as List;
  final hadithsList = data['hadiths'] as List;

  final chapters = chaptersList.map((e) => RiyadChapter.fromJson(e)).toList();
  final hadiths = hadithsList.map((e) => RiyadHadith.fromJson(e)).toList();

  return {
    'chapters': chapters,
    'hadiths': hadiths,
  };
}

class AppProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // Tasbeeh
  int _currentTasbeehCount = 0;
  int _totalTasbeehCount = 0;
  int _tasbeehTarget = 33;

  int get currentTasbeehCount => _currentTasbeehCount;
  int get totalTasbeehCount => _totalTasbeehCount;
  int get tasbeehTarget => _tasbeehTarget;

  // Quran
  int _lastReadSurah = 1;
  int _lastReadAyah = 1;
  int get lastReadSurah => _lastReadSurah;
  int get lastReadAyah => _lastReadAyah;

  List<String> _favoriteAyahs = [];
  List<String> get favoriteAyahs => _favoriteAyahs;

  List<String> _favoriteHadiths = [];
  List<String> get favoriteHadiths => _favoriteHadiths;

  String _appLanguage = 'ar';
  String get appLanguage => _appLanguage;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  Map<String, int> _dailyReadingMinutes = {};
  Map<String, int> get dailyReadingMinutes => _dailyReadingMinutes;

  List<int> _recentSurahs = [];
  List<int> get recentSurahs => _recentSurahs;

  Map<int, double> _surahScrollOffsets = {};
  double getSurahScrollOffset(int surah) => _surahScrollOffsets[surah] ?? 0.0;

  // Data
  List<Hadith> _hadiths = [];
  List<RiyadChapter> _riyadChapters = [];
  Map<int, List<RiyadHadith>> _riyadHadithsByChapter = {};
  Map<int, RiyadHadith> _allRiyadHadithsMap = {};
  List<Zekr> _azkar = [];
  Map<String, List<Zekr>> _azkarByCategory = {};

  List<Hadith> get hadiths => _hadiths;
  List<RiyadChapter> get riyadChapters => _riyadChapters;
  Map<int, List<RiyadHadith>> get riyadHadithsByChapter => _riyadHadithsByChapter;
  Map<int, RiyadHadith> get allRiyadHadithsMap => _allRiyadHadithsMap;
  List<Zekr> get azkar => _azkar;
  Map<String, List<Zekr>> get azkarByCategory => _azkarByCategory;
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPrefs();
    await _loadData();
    _isLoading = false;
    notifyListeners();
  }

  void _loadPrefs() {
    _currentTasbeehCount = _prefs?.getInt('currentTasbeehCount') ?? 0;
    _totalTasbeehCount = _prefs?.getInt('totalTasbeehCount') ?? 0;
    _tasbeehTarget = _prefs?.getInt('tasbeehTarget') ?? 33;
    _lastReadSurah = _prefs?.getInt('lastReadSurah') ?? 1;
    _lastReadAyah = _prefs?.getInt('lastReadAyah') ?? 1;
    _favoriteAyahs = _prefs?.getStringList('favoriteAyahs') ?? [];
    _favoriteHadiths = _prefs?.getStringList('favoriteHadiths') ?? [];
    _appLanguage = _prefs?.getString('appLanguage') ?? 'ar';
    _notificationsEnabled = _prefs?.getBool('notificationsEnabled') ?? true;

    try {
      final statsStr = _prefs?.getString('dailyReadingMinutes') ?? '{}';
      final statsMap = json.decode(statsStr) as Map<String, dynamic>;
      _dailyReadingMinutes = statsMap.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      _dailyReadingMinutes = {};
    }

    final recentStrList = _prefs?.getStringList('recentSurahs') ?? [];
    _recentSurahs = recentStrList.map((e) => int.tryParse(e) ?? 1).toList();

    try {
      final offsetsStr = _prefs?.getString('surahScrollOffsets') ?? '{}';
      final offsetsMap = json.decode(offsetsStr) as Map<String, dynamic>;
      _surahScrollOffsets = offsetsMap.map((key, value) => MapEntry(int.parse(key), (value as num).toDouble()));
    } catch (e) {
      _surahScrollOffsets = {};
    }
  }

  Future<void> _loadData() async {
    try {
      // Load Nawawi Hadiths (if still needed, or we can keep it for fallback)
      try {
        final hadithString = await rootBundle.loadString('assets/json/nawawi.json');
        final hadithJson = json.decode(hadithString) as List;
        _hadiths = hadithJson.map((e) => Hadith.fromJson(e)).toList();
      } catch (e) {
        print('Could not load nawawi.json: \$e');
      }

      // Load Riyad as-Salihin using compute
      try {
        final riyadString = await rootBundle.loadString('assets/hadiths/riyad_assalihin.json');
        final parsedData = await compute(_parseRiyadData, riyadString);
        
        _riyadChapters = parsedData['chapters'] as List<RiyadChapter>;
        final allRiyadHadiths = parsedData['hadiths'] as List<RiyadHadith>;
        
        for (var hadith in allRiyadHadiths) {
          _allRiyadHadithsMap[hadith.id] = hadith;
          if (!_riyadHadithsByChapter.containsKey(hadith.chapterId)) {
            _riyadHadithsByChapter[hadith.chapterId] = [];
          }
          _riyadHadithsByChapter[hadith.chapterId]!.add(hadith);
        }
      } catch (e) {
        print('Could not load riyad_assalihin.json: \$e');
      }

      // Load Azkar
      final azkarString = await rootBundle.loadString('assets/json/azkar.json');
      final azkarJson = json.decode(azkarString);
      final rows = azkarJson['rows'] as List;
      _azkar = rows.map((e) => Zekr.fromJson(e)).toList();

      for (var zekr in _azkar) {
        if (!_azkarByCategory.containsKey(zekr.category)) {
          _azkarByCategory[zekr.category] = [];
        }
        _azkarByCategory[zekr.category]!.add(zekr);
      }
    } catch (e) {
      print('Error loading data: \$e');
    }
  }

  // Tasbeeh Methods
  void incrementTasbeeh() {
    _currentTasbeehCount++;
    _totalTasbeehCount++;
    if (_currentTasbeehCount > _tasbeehTarget) {
      _currentTasbeehCount = 1; // reset cycle
    }
    _saveTasbeehPrefs();
    notifyListeners();
  }

  void resetCurrentTasbeeh() {
    _currentTasbeehCount = 0;
    _saveTasbeehPrefs();
    notifyListeners();
  }

  void resetTotalTasbeeh() {
    // _totalTasbeehCount = 0;
    _currentTasbeehCount = 0;
    _saveTasbeehPrefs();
    notifyListeners();
  }

  void setTasbeehTarget(int target) {
    _tasbeehTarget = target;
    _currentTasbeehCount = 0; // optionally reset
    _saveTasbeehPrefs();
    notifyListeners();
  }

  void _saveTasbeehPrefs() {
    _prefs?.setInt('currentTasbeehCount', _currentTasbeehCount);
    _prefs?.setInt('totalTasbeehCount', _totalTasbeehCount);
    _prefs?.setInt('tasbeehTarget', _tasbeehTarget);
  }

  // Quran Methods
  void saveLastRead(int surah, int ayah) {
    _lastReadSurah = surah;
    _lastReadAyah = ayah;
    _prefs?.setInt('lastReadSurah', _lastReadSurah);
    _prefs?.setInt('lastReadAyah', _lastReadAyah);
    notifyListeners();
  }

  void addRecentSurah(int surah) {
    _recentSurahs.remove(surah);
    _recentSurahs.insert(0, surah);
    if (_recentSurahs.length > 5) {
      _recentSurahs = _recentSurahs.sublist(0, 5);
    }
    _prefs?.setStringList('recentSurahs', _recentSurahs.map((e) => e.toString()).toList());
    notifyListeners();
  }

  void saveSurahScrollOffset(int surah, double offset) {
    _surahScrollOffsets[surah] = offset;
    _prefs?.setString('surahScrollOffsets', json.encode(_surahScrollOffsets.map((key, value) => MapEntry(key.toString(), value))));
  }

  void toggleFavoriteAyah(int surah, int ayah) {
    final String ayahStr = json.encode({'surah': surah, 'ayah': ayah});
    if (_favoriteAyahs.contains(ayahStr)) {
      _favoriteAyahs.remove(ayahStr);
    } else {
      _favoriteAyahs.add(ayahStr);
    }
    _prefs?.setStringList('favoriteAyahs', _favoriteAyahs);
    notifyListeners();
  }

  bool isFavoriteAyah(int surah, int ayah) {
    final String ayahStr = json.encode({'surah': surah, 'ayah': ayah});
    return _favoriteAyahs.contains(ayahStr);
  }

  void toggleFavoriteHadith(int id) {
    final String idStr = id.toString();
    if (_favoriteHadiths.contains(idStr)) {
      _favoriteHadiths.remove(idStr);
    } else {
      _favoriteHadiths.add(idStr);
    }
    _prefs?.setStringList('favoriteHadiths', _favoriteHadiths);
    notifyListeners();
  }

  bool isFavoriteHadith(int id) {
    return _favoriteHadiths.contains(id.toString());
  }

  void setAppLanguage(String lang) {
    _appLanguage = lang;
    _prefs?.setString('appLanguage', _appLanguage);
    notifyListeners();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    _prefs?.setBool('notificationsEnabled', _notificationsEnabled);
    notifyListeners();
  }

  void incrementReadingTime() {
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    _dailyReadingMinutes[dateStr] = (_dailyReadingMinutes[dateStr] ?? 0) + 1;
    _prefs?.setString('dailyReadingMinutes', json.encode(_dailyReadingMinutes));
    notifyListeners();
  }
}

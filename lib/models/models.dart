class Hadith {
  final String description;
  final String hadith;

  Hadith({required this.description, required this.hadith});

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      description: json['description'] ?? '',
      hadith: json['hadith'] ?? '',
    );
  }
}

class Zekr {
  final String category;
  final String zekr;
  final String description;
  final int count;
  final String reference;

  Zekr({
    required this.category,
    required this.zekr,
    required this.description,
    required this.count,
    required this.reference,
  });

  factory Zekr.fromJson(List<dynamic> row) {
    return Zekr(
      category: row[0].toString(),
      zekr: row[1].toString(),
      description: row[2].toString(),
      count: row[3] is int ? row[3] : int.tryParse(row[3].toString()) ?? 1,
      reference: row[4].toString(),
    );
  }
}

class RiyadChapter {
  final int id;
  final String titleArabic;

  RiyadChapter({required this.id, required this.titleArabic});

  factory RiyadChapter.fromJson(Map<String, dynamic> json) {
    return RiyadChapter(
      id: json['id'] ?? 0,
      titleArabic: json['arabic'] ?? '',
    );
  }
}

class RiyadHadith {
  final int id;
  final int chapterId;
  final String textArabic;

  RiyadHadith({
    required this.id,
    required this.chapterId,
    required this.textArabic,
  });

  factory RiyadHadith.fromJson(Map<String, dynamic> json) {
    return RiyadHadith(
      id: json['id'] ?? 0,
      chapterId: json['chapterId'] ?? 0,
      textArabic: json['arabic'] ?? '',
    );
  }
}

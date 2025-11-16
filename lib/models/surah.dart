class Surah {
  Surah({
    required this.arabicName,
    required this.id,
    required this.name,
    required this.revelationOrder,
    required this.revelationPlace,
    required this.versesCount,
  });
  static Surah? fromMapOrNull(dynamic json) {
    if (json case {
      'name_arabic': final String nameArabic,
      'id': final int id,
      'name_simple': final String nameSimple,
      'revelation_order': final int revelationOrder,
      'revelation_place': final String revelationPlace,
      'verses_count': final int versesCount,
    }) {
      return Surah(
        arabicName: nameArabic,
        id: id,
        name: nameSimple,
        revelationOrder: revelationOrder,
        revelationPlace: revelationPlace,
        versesCount: versesCount,
      );
    }
    return null;
  }

  int id;
  String revelationPlace;
  int revelationOrder;
  String name;
  String arabicName;
  int versesCount;
}

import 'package:flutter/material.dart';
import 'package:my_quran/models/surah.dart';
import 'package:quran/quran.dart' as quran;

class SurahPage extends StatelessWidget {
  const SurahPage({required this.surah, super.key});
  final Surah surah;
  @override
  Widget build(BuildContext context) {
    final count = surah.versesCount;
    final index = surah.id;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          minimum: const EdgeInsets.all(15),
          child: ListView(
            children: [
              Padding(padding: const EdgeInsets.all(5), child: header()),
              const SizedBox(height: 5),
              RichText(
                textAlign: count <= 20 ? TextAlign.center : TextAlign.justify,
                text: TextSpan(
                  children: [
                    for (var i = 1; i <= count; i++) ...{
                      TextSpan(
                        text: ' ${quran.getVerse(index, i)} ',
                        style: const TextStyle(
                          fontFamily: 'Kitab',
                          fontSize: 25,
                          color: Colors.black87,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: CircleAvatar(
                          radius: 14,
                          child: Text(
                            '$i',
                            textAlign: TextAlign.center,
                            textScaler: TextScaler.linear(
                              i.toString().length <= 2 ? 1 : .8,
                            ),
                          ),
                        ),
                      ),
                    },
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget header() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          surah.arabicName,
          style: const TextStyle(
            fontFamily: 'Aldhabi',
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          ' ${quran.basmala} ',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 24),
        ),
      ],
    );
  }
}

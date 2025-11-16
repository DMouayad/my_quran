import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/models/surah.dart';
import 'package:my_quran/screens/reading_page.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Surah> surahList = [];
  int selectedIndex = 0;
  bool isReverse = false;
  final ScrollController _controller = ScrollController();
  @override
  void initState() {
    readJson();
    super.initState();
  }

  Future<void> readJson() async {
    final response = await rootBundle.loadString('assets/surah.json');
    final data = await json.decode(response);
    if (data case {
      'chapters': final List<dynamic> chapters,
    }) {
      for (final item in chapters) {
        if (Surah.fromMapOrNull(item) case final Surah surah) {
          surahList.add(surah);
        }
      }
    }
    debugPrint(surahList.length.toString());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Transform.rotate(
          angle: isReverse ? pi : 2 * pi,
          child: IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              setState(() {
                isReverse = !isReverse;
              });
            },
          ),
        ),
      ),
      body: surahList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : chaptersList(isReverse ? surahList.reversed.toList() : surahList),
    );
  }

  Widget chaptersList(List<Surah> chapters) {
    return ListView.separated(
      controller: _controller,
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(child: Text(chapters[index].id.toString())),
        title: Text(chapters[index].name),
        subtitle: Text(chapters[index].versesCount.toString()),
        trailing: Text(
          chapters[index].arabicName,
          style: GoogleFonts.cairo(fontSize: 18),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                SurahPage(surah: chapters[index]),
          ),
        ),
      ),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemCount: chapters.length,
    );
  }
}

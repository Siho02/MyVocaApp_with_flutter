import 'package:flutter/material.dart';
import 'package:voca_app/word_form_screen.dart';
import 'package:voca_app/word_list_screen.dart';
import 'package:voca_app/study_screen.dart';
import 'package:voca_app/stats_screen.dart';

class HomeScreen extends StatelessWidget {
  final String deckName;

  const HomeScreen({super.key, required this.deckName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deckName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // body 부분을 수정합니다.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('수동으로 단어 등록'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WordFormScreen(deckName: deckName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: const Text('이 덱의 통계 보기'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsScreen(deckName: deckName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt),
              label: const Text('등록한 단어 전체 보기'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WordListScreen(deckName: deckName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.school_outlined),
              label: const Text('단어 공부하러 가기'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudyScreen(deckName: deckName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18),
                // 주요 기능 버튼은 색상을 다르게 해서 강조할 수 있습니다.
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
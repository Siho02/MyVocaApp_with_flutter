import 'package:flutter/material.dart';
import 'package:voca_app/word_form_screen.dart';
import 'package:voca_app/word_list_screen.dart';
import 'package:voca_app/study_screen.dart';

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
        // 1. Padding: 버튼들이 화면 가장자리에 너무 붙지 않도록 여백을 줍니다.
        padding: const EdgeInsets.all(16.0),
        // 2. Column: 위젯들을 세로로 차곡차곡 쌓아줍니다.
        child: Column(
          // 3. crossAxisAlignment: 버튼들이 가로로 꽉 차게 만듭니다.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 4. ElevatedButton: 입체감이 있는 기본 버튼입니다.
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('수동으로 단어 등록'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // AddWordScreen을 만들 때 현재 덱 이름을 전달합니다.
                    builder: (context) => WordFormScreen(deckName: deckName),
                  ),
                );
              },
              // 버튼 스타일을 꾸며줍니다.
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            // 5. SizedBox: 버튼 사이에 간격을 만들어주는 투명한 상자입니다.
            const SizedBox(height: 16),
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
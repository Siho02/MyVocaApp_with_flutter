import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:voca_app/word_form_screen.dart';
import 'package:voca_app/word_list_screen.dart';
import 'package:voca_app/data_manager.dart';
import 'package:voca_app/study_screen.dart';
import 'package:voca_app/stats_screen.dart';

class HomeScreen extends StatelessWidget {
  final String deckName;

  const HomeScreen({super.key, required this.deckName});

  @override
  Widget build(BuildContext context) {
    final DataManager dataManager = DataManager();
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
              icon: const Icon(Icons.file_upload),
              label: const Text('CSV로 단어 등록'),
              onPressed: () async {
                // 2. 파일 피커 실행
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['csv'], // CSV 파일만 선택 가능하도록 필터링
                );

                if (result != null && result.files.single.path != null) {
                  // 사용자가 파일을 선택했다면
                  final path = result.files.single.path!;
                  // DataManager를 통해 단어 추가 로직 실행
                  final count = await dataManager.addWordsFromCsv(path, deckName);
                  
                  // 작업 완료 후 사용자에게 결과 알림
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$count개의 단어를 성공적으로 추가했습니다!')),
                    );
                  }
                } else {
                  // 사용자가 파일 선택을 취소한 경우
                  print('파일 선택이 취소되었습니다.');
                }

              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            
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
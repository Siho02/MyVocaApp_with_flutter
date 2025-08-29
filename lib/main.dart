// lib/main.dart

import 'package:flutter/material.dart';
import 'package:voca_app/home_screen.dart';
// DataManager를 import 합니다.
import 'package:voca_app/data_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VocaApp());
}

class VocaApp extends StatelessWidget {
  const VocaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '나만의 단어장',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DeckSelectionScreen(),
    );
  }
}

class DeckSelectionScreen extends StatefulWidget {
  const DeckSelectionScreen({super.key});

  @override
  State<DeckSelectionScreen> createState() => _DeckSelectionScreenState();
}

class _DeckSelectionScreenState extends State<DeckSelectionScreen> {
  // DataManager 인스턴스를 클래스 변수로 선언
  final DataManager dataManager = DataManager();
  List<String> _deckNames = [];

  @override
  void initState() {
    super.initState();
    _fetchDeckNames();
  }

  // JSON 파일에서 덱 이름을 불러와 화면을 갱신하는 함수
  Future<void> _fetchDeckNames() async {
    final names = await dataManager.getDeckNames();
    setState(() {
      _deckNames = names;
    });
  }

  // 덱 삭제 확인용 팝업 함수
  void _confirmDeleteDeck(String deckName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('덱 삭제 확인'),
          content: Text("'$deckName' 덱을 정말로 삭제하시겠습니까?\n\n덱 안의 모든 단어가 함께 삭제되며, 이 작업은 되돌릴 수 없습니다."),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await dataManager.deleteDeck(deckName);
                Navigator.of(context).pop(); // 확인 팝업 닫기
                _fetchDeckNames(); // 덱 목록 새로고침
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddDeckDialog() async {
    final TextEditingController deckNameController = TextEditingController();
    // 다이얼로그의 context를 저장하기 위한 변수
    final dialogContext = context;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('새 덱 만들기'),
          content: TextField(
            controller: deckNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: '예: 스페인어 회화'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('추가'),
              onPressed: () async {
                final String newDeckName = deckNameController.text.trim();
                if (newDeckName.isNotEmpty) {
                  // DataManager를 통해 새 덱을 파일에 생성
                  await dataManager.createDeck(newDeckName);
                  // 파일에서 덱 목록을 다시 불러와 화면을 갱신
                  await _fetchDeckNames();
                }
                // AlertDialog를 닫음
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나만의 단어장'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: _deckNames.length,
        itemBuilder: (BuildContext context, int index) {
          final deckName = _deckNames[index];
          return ListTile(
            leading: const Icon(Icons.book),
            title: Text(deckName),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {
                // 휴지통 아이콘을 누르면 삭제 확인 팝업을 띄웁니다.
                _confirmDeleteDeck(deckName);
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(deckName: deckName),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeckDialog,
        tooltip: '새 덱 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}
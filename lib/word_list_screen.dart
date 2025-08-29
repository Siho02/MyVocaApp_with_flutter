// lib/word_list_screen.dart

import 'package:flutter/material.dart';
import 'package:voca_app/data_manager.dart';
import 'package:voca_app/models/word.dart';
import 'package:voca_app/word_form_screen.dart';

class WordListScreen extends StatefulWidget {
  final String deckName;
  const WordListScreen({super.key, required this.deckName});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  // DataManager를 통해 단어 목록을 비동기적으로 불러옴
  late Future<List<Word>> _wordsFuture;
  final DataManager dataManager = DataManager();

  @override
  void initState() {
    super.initState();
    _wordsFuture = dataManager.getWordsForDeck(widget.deckName);
  }
  void _refreshWords() {
    setState(() {
      _wordsFuture = dataManager.getWordsForDeck(widget.deckName);
    });
  }
  void _showOptionsSheet(Word word) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('수정하기'),
              onTap: () async{
                Navigator.pop(context);

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WordFormScreen(
                      deckName: widget.deckName,
                      wordToEdit: word,
                    ),
                  ),
                );

                if (result == true){
                  _refreshWords();
                }
              },
            
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('삭제하기'),
              onTap: () {
                Navigator.pop(context); // 바텀 시트 먼저 닫기
                _confirmDelete(word);   // 삭제 확인 팝업 띄우기
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Word word) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: Text("'${word.word}' 단어를 정말로 삭제하시겠습니까?"),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('삭제'),
              onPressed: () async {
                await dataManager.deleteWordFromDeck(widget.deckName, word);
                Navigator.of(context).pop(); // 확인 팝업 닫기
                _refreshWords(); // 화면 새로고침
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
        title: Text('${widget.deckName}: 단어 목록'),
      ),
      // FutureBuilder: 비동기 데이터 로딩 상태를 손쉽게 처리해주는 위젯
      body: FutureBuilder<List<Word>>(
        future: _wordsFuture, // 이 Future의 상태를 감시
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('에러가 발생했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('저장된 단어가 없습니다.'));
          }
          final words = snapshot.data!;
          return ListView.builder(
            itemCount: words.length,
            itemBuilder: (context, index) {
              final word = words[index];
              return ListTile(
                title: Text(word.word),
                subtitle: Text(word.meaning.join(', ')),
                onTap: () => _showOptionsSheet(word),
              );
            },
          );
        },
      ),
    );
  }
}
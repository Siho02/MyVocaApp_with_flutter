// lib/word_list_screen.dart

import 'package:flutter/material.dart';
import 'package:voca_app/data_manager.dart';
import 'package:voca_app/models/word.dart';
import 'package:voca_app/word_form_screen.dart'; // <--- 정확한 파일 import

class WordListScreen extends StatefulWidget {
  final String deckName;
  const WordListScreen({super.key, required this.deckName});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final DataManager dataManager = DataManager();
  final TextEditingController _searchController = TextEditingController();

  List<Word> _allWords = [];
  List<Word> _filteredWords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterWords);
    _loadWords();
  }
  
  Future<void> _loadWords() async {
    final words = await dataManager.getWordsForDeck(widget.deckName);
    setState(() {
      _allWords = words;
      _filteredWords = words;
      _isLoading = false;
    });
  }

  void _filterWords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWords = _allWords.where((word) {
        final wordLower = word.word.toLowerCase();
        final meaningLower = word.meaning.join(' ').toLowerCase();
        return wordLower.contains(query) || meaningLower.contains(query);
      }).toList();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshWords() {
    setState(() { _isLoading = true; });
    _searchController.clear(); // 새로고침 시 검색어도 초기화
    _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.deckName}: 단어 목록'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '단어 또는 뜻으로 검색...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _filteredWords.isEmpty
                        ? const Center(child: Text('일치하는 단어가 없습니다.'))
                        : ListView.builder(
                            itemCount: _filteredWords.length,
                            itemBuilder: (context, index) {
                              final word = _filteredWords[index];
                              
                              return Dismissible(
                                key: Key(word.createdAt), // 고유 ID인 createdAt을 Key로 사용
                                
                                background: Container( // 왼쪽 -> 오른쪽 (수정)
                                  color: Colors.blue,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: const Icon(Icons.edit, color: Colors.white),
                                ),
                                
                                secondaryBackground: Container( // 오른쪽 -> 왼쪽 (삭제)
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.endToStart) { // 삭제 방향
                                    return await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('단어 삭제 확인'),
                                          content: Text("'${word.word}' 단어를 정말로 삭제하시겠습니까?"),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('취소'),
                                              onPressed: () => Navigator.of(context).pop(false),
                                            ),
                                            TextButton(
                                              child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                              onPressed: () => Navigator.of(context).pop(true),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else { // 수정 방향
                                    // 수정은 확인 없이 바로 진행
                                    return true;
                                  }
                                },
                                
                                onDismissed: (direction) async {
                                  if (direction == DismissDirection.endToStart) { // 삭제
                                    await dataManager.deleteWordFromDeck(widget.deckName, word);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("'${word.word}' 단어가 삭제되었습니다.")),
                                    );
                                    _refreshWords();
                                  } else if (direction == DismissDirection.startToEnd) { // 수정
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WordFormScreen(
                                          deckName: widget.deckName,
                                          wordToEdit: word,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _refreshWords();
                                    } else {
                                      // 수정 취소 시 화면을 원래대로 돌리기 위해 새로고침
                                      _refreshWords();
                                    }
                                  }
                                },
                                
                                child: Card(
                                  child: ListTile(
                                    title: Text(word.word),
                                    subtitle: Text(word.meaning.join(', ')),
                                    onTap: () async {
                                      // 탭했을 때도 수정 화면으로 이동
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WordFormScreen(
                                            deckName: widget.deckName,
                                            wordToEdit: word,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _refreshWords();
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
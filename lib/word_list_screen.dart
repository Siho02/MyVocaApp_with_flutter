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
  final DataManager dataManager = DataManager();
  final TextEditingController _searchController = TextEditingController();

  // 1. 상태 변수 추가
  List<Word> _allWords = [];
  List<Word> _filteredWords = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterWords);
    _loadWords();
  }
  
  // 최초에 한 번만 파일에서 모든 단어를 불러오는 함수
  Future<void> _loadWords() async {
    final words = await dataManager.getWordsForDeck(widget.deckName);
    setState(() {
      _allWords = words;
      _filteredWords = words; // 처음에는 모든 단어를 보여줌
      _isLoading = false;
    });
  }

  // 검색 텍스트에 따라 _filteredWords 리스트를 갱신하는 함수
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
  
  // 화면이 사라질 때 컨트롤러 정리
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 화면 새로고침 함수 (이제 _loadWords를 직접 호출)
  void _refreshWords() {
    setState(() { _isLoading = true; });
    _loadWords();
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
              onTap: () async {
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
                if (result == true) {
                  _refreshWords();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('삭제하기'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(word);
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
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await dataManager.deleteWordFromDeck(widget.deckName, word);
                Navigator.of(context).pop();
                _refreshWords();
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
      // 2. body 구조 변경
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // --- 검색창 UI 추가 ---
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

                  // --- 단어 목록 부분 ---
                  Expanded(
                    child: _filteredWords.isEmpty
                        ? const Center(child: Text('일치하는 단어가 없습니다.'))
                        : ListView.builder(
                            itemCount: _filteredWords.length,
                            itemBuilder: (context, index) {
                              final word = _filteredWords[index];
                              return ListTile(
                                title: Text(word.word),
                                subtitle: Text(word.meaning.join(', ')),
                                onTap: () => _showOptionsSheet(word),
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
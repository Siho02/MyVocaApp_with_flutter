// lib/word_list_screen.dart

import 'package:flutter/material.dart';
import 'package:voca_app/data_manager.dart';
import 'package:voca_app/models/word.dart';
import 'package:voca_app/word_form_screen.dart'; 
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordListScreen extends StatefulWidget {
  final String deckName;
  const WordListScreen({super.key, required this.deckName});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final DataManager dataManager = DataManager();
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  bool _showFab = true; // FloatingActionButton 표시 여부

  List<Word> _allWords = [];
  List<Word> _filteredWords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    try {
      _searchController.addListener(_filterWords);
      _loadWords();
      _scrollController.addListener(() {
        if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
          if (_showFab) setState(() => _showFab = false);
        } else {
          if (!_showFab) setState(() => _showFab = true);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // 오류 발생 시 로딩 중지
      });
      _showIntroductoryTip();
    }
  }
  
  Future<void> _loadWords() async {

    try {
      final words = await dataManager.getWordsForDeck(widget.deckName);
      
      if (mounted) {
        setState(() {
          _allWords = words;
          _filteredWords = words;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  // --- 스와이프 팁 스낵바를 보여주는 재사용 가능한 함수 ---
  void _showSwipeTipSnackBar() {
    // 혹시 떠 있는 스낵바가 있다면 먼저 제거
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // 새로운 스낵바를 보여줌
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💡 Tip: 단어를 옆으로 밀어서 수정하거나 삭제할 수 있습니다.'),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showIntroductoryTip() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasShown = prefs.getBool('hasShownSwipeTip') ?? false;

    if (!hasShown) {
      // 위젯 빌드가 완료된 후에 _showSwipeTipSnackBar 함수를 호출하도록 예약
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _showSwipeTipSnackBar();
      });
      
      await prefs.setBool('hasShownSwipeTip', true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshWords() {
    setState(() { _isLoading = true; });
    _searchController.clear(); // 새로고침 시 검색어도 초기화
    _loadWords();
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: Container(width: 24, height: 24, color: Colors.white),
              title: Container(
                width: double.infinity,
                height: 16.0,
                color: Colors.white,
                margin: const EdgeInsets.only(right: 40.0), // 실제 텍스트처럼 보이게
              ),
              subtitle: Container(
                width: double.infinity,
                height: 14.0,
                color: Colors.white,
                margin: const EdgeInsets.only(right: 80.0), // 실제 텍스트처럼 보이게
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.deckName}: 단어 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '도움말 보기', // 아이콘을 길게 눌렀을 때 나오는 설명
            onPressed: _showSwipeTipSnackBar, // 버튼을 누르면 팁 메시지 함수 호출
          ),
        ],
      ),
      body: Padding(
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
              child: _isLoading
                  ? _buildLoadingSkeleton() // 로딩 중일 때는 스켈레톤 UI 표시
                  : _filteredWords.isEmpty
                      ? const Center(child: Text('일치하는 단어가 없습니다.'))
                      : AnimationLimiter( // 애니메이션 적용 시작
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _filteredWords.length,
                            itemBuilder: (context, index) {
                              final word = _filteredWords[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Dismissible(
                                      key: Key(word.createdAt),
                                      background: Container(
                                        color: Colors.blue,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                        child: const Icon(Icons.edit, color: Colors.white),
                                      ),
                                      secondaryBackground: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                        child: const Icon(Icons.delete, color: Colors.white),
                                      ),
                                      confirmDismiss: (direction) async {
                                        if (direction == DismissDirection.endToStart) {
                                          return await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('단어 삭제 확인'),
                                                content: Text("'${word.word}' 단어를 정말로 삭제하시겠습니까?"),
                                                actions: <Widget>[
                                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
                                                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                                                ],
                                              );
                                            },
                                          ) ?? false;
                                        }
                                        return true;
                                      },
                                      onDismissed: (direction) async {
                                        if (direction == DismissDirection.endToStart) {
                                          await dataManager.deleteWordFromDeck(widget.deckName, word);
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'${word.word}' 단어가 삭제되었습니다.")));
                                          _refreshWords();
                                        } else if (direction == DismissDirection.startToEnd) {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => WordFormScreen(deckName: widget.deckName, wordToEdit: word)),
                                          );
                                          _refreshWords(); // 수정 완료 후 목록 갱신
                                        }
                                      },
                                      child: Card(
                                        child: ListTile(
                                          title: Text(word.word),
                                          subtitle: Text(word.meaning.join(', ')),
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => WordFormScreen(deckName: widget.deckName, wordToEdit: word)),
                                            );
                                            _refreshWords(); // 탭으로 수정 완료 후 목록 갱신
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _showFab ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Visibility(
          visible: _showFab,
          child: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WordFormScreen(deckName: widget.deckName)),
              );
              _refreshWords(); // 단어 추가 완료 후 목록 갱신
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
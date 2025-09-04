import 'dart:math';
import 'package:flutter/material.dart';
import 'package:voca_app/models/word.dart';
import 'package:voca_app/study_manager.dart';
import 'package:voca_app/data_manager.dart';

class StudyScreen extends StatefulWidget {
  final String deckName;
  const StudyScreen({super.key, required this.deckName});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final StudyManager _studyManager = StudyManager();
  final DataManager _dataManager = DataManager();
  final TextEditingController _answerController = TextEditingController();

  List<Word> _reviewWords = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  int _sessionCorrect = 0;
  int _sessionIncorrect = 0;

  bool _isSubjective = false;
  List<String> _choices = []; 

  @override
  void initState() {
    super.initState();
    _loadReviewWords();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewWords() async {
    final words = await _studyManager.getWordsForReview(widget.deckName);
    setState(() {
      _reviewWords = words;
      _isLoading = false;
    });
    // 단어를 불러온 후 첫 문제를 출제
    if (_reviewWords.isNotEmpty) {
      _prepareNextQuestion();
    }
  }

  // 다음 문제 준비 함수
  Future<void> _prepareNextQuestion() async {
    final currentWord = _reviewWords[_currentIndex];
    final stats = currentWord.reviewStats['study_to_native'];
    final totalReviews = (stats['correct_cnt'] ?? 0) + (stats['incorrect_cnt'] ?? 0);
    final accuracy = (totalReviews == 0) ? 0 : (stats['correct_cnt'] ?? 0) / totalReviews;

    // 1-2. 조건에 따라 주관식/객관식 결정
    if (totalReviews >= 15 && accuracy >= 0.85) {
      setState(() {
        _isSubjective = true;
        _answerController.clear();
      });
    } else {
      // 1-1. 객관식 문제 준비
      final distractors = await _studyManager.getDistractors(widget.deckName, currentWord);
      final correctAnswer = currentWord.meaning[0]; // 우선 첫 번째 뜻을 정답으로
      
      setState(() {
        _isSubjective = false;
        _choices = [...distractors, correctAnswer]..shuffle(); // 보기들을 합치고 섞음
      });
    }
  }

  // 정답 확인 및 결과 처리 함수
  Future<void> _checkAnswer(String userAnswer) async {
    final currentWord = _reviewWords[_currentIndex];
    final isCorrect = currentWord.meaning.contains(userAnswer.trim());
    
    if (isCorrect) {
      _sessionCorrect++;
    } else {
      _sessionIncorrect++;
    }

    // --- SRS(간격 반복 시스템) 로직 ---
    final stats = currentWord.reviewStats['study_to_native'];
    if (isCorrect) {
      stats['correct_cnt']++;
    } else {
      stats['incorrect_cnt']++;
    }
    stats['last_reviewed'] = DateTime.now().toIso8601String();
    
    // 정답/오답에 따라 다음 복습 간격 계산 (단순화된 버전)
    final correctCount = stats['correct_cnt'];
    int minutesToAdd = isCorrect ? (pow(2, correctCount) * 60).toInt() : 10; // 맞으면 간격 늘리고, 틀리면 10분 뒤
    stats['next_review'] = DateTime.now().add(Duration(minutes: minutesToAdd)).toIso8601String();

    // 변경된 통계를 파일에 저장
    await _dataManager.updateWordReviewStats(widget.deckName, currentWord);

    // 사용자에게 결과 피드백 보여주기
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? '정답입니다! 🎉' : '오답입니다 😥'),
        content: Text("정답: ${currentWord.meaning.join(', ')}"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
    
    // 다음 문제로 이동하거나 학습 종료
    if (_currentIndex < _reviewWords.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _prepareNextQuestion();
    } else {
      await _dataManager.logStudySession(widget.deckName, _sessionCorrect, _sessionIncorrect);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오늘의 학습을 모두 마쳤습니다!')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_reviewWords.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('오늘 복습할 단어가 없습니다!')));
    }

    final currentWord = _reviewWords[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.deckName}: 학습 중 (${_currentIndex + 1}/${_reviewWords.length})')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 문제 표시 부분 ---
            Expanded(
              child: Center(
                child: Text(
                  currentWord.word,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
            // --- 정답 입력 UI 부분 (조건에 따라 변경) ---
            if (_isSubjective)
              // 주관식 UI
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(hintText: '정답을 입력하세요'),
                      onSubmitted: _checkAnswer, // 엔터키로 제출
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _checkAnswer(_answerController.text),
                  ),
                ],
              )
            else
              // 객관식 UI
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _choices.map((choice) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () => _checkAnswer(choice),
                      child: Text(choice),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
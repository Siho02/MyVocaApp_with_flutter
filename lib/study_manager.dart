import 'package:voca_app/data_manager.dart';
import 'package:voca_app/models/word.dart';
import 'dart:math';

class StudyManager {
  final DataManager _dataManager = DataManager();

  // 특정 덱에서 오늘 복습할 단어만 골라내는 함수
  Future<List<Word>> getWordsForReview(String deckName) async {
    final allWords = await _dataManager.getWordsForDeck(deckName);
    final now = DateTime.now();
  
    final reviewWords = allWords.where((word) {
      final stats = word.reviewStats['study_to_native'];
      if (stats == null || stats['next_review'] == null) {
        return false; // 복습 정보가 없으면 학습 대상에서 제외
      }
      
      final nextReviewString = stats['next_review'];
      final nextReviewDate = DateTime.parse(nextReviewString);
      final isDue = nextReviewDate.isBefore(now) || nextReviewDate.isAtSameMomentAs(now);
      return isDue;
    }).toList();

    reviewWords.shuffle();
    return reviewWords;
  }

  //객관식 오답 보기 함수 
  Future<List<String>> getDistractors(String deckName, Word correctWord) async {
    final allWords = await _dataManager.getWordsForDeck(deckName);
    // 현재 단어의 뜻을 제외한 모든 단어의 뜻을 하나의 리스트로 만듦
    final pool = allWords
        .where((word) => word.createdAt != correctWord.createdAt)
        .expand((word) => word.meaning)
        .toList();
    
    final distinctPool = pool.toSet().toList();
    distinctPool.shuffle();
    return distinctPool.take(min(3, distinctPool.length)).toList();
  }
}
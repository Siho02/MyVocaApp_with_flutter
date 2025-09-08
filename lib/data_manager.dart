import 'dart:io'; 
import 'dart:convert'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:voca_app/models/word.dart'; 
import 'package:csv/csv.dart';

class DataManager {
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/app_data.json');
  }

  // --- 데이터를 읽어오는 함수 ---
  Future<Map<String, dynamic>> readData() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        final initialData = {"decks": {}};
        await writeData(initialData);
        return initialData;
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return {"decks": {}};
      }
      return json.decode(contents);
    } catch (e) {
      return {"decks": {}};
    }
  }

  // --- 데이터를 쓰는(저장하는) 함수 ---
  Future<File> writeData(Map<String, dynamic> data) async {
    final file = await _localFile;
    final jsonString = json.encode(data);
    return file.writeAsString(jsonString);
  }

  // 덱 이름 목록 가져오기 함수
  Future<List<String>> getDeckNames() async {
    final allData = await readData();
    final dynamic decksData = allData['decks'];
    if (decksData is Map) {
      final decksMap = Map<String, dynamic>.from(decksData);
      return decksMap.keys.toList();
    }
    return [];
  }

  // 새로운 덱 생성
  Future<void> createDeck(String deckName) async {
    final allData = await readData();
    if (!allData['decks'].containsKey(deckName)) {
      allData['decks'][deckName] = {'words': []};
      await writeData(allData);
      print("새 덱 생성 완료: $deckName");
    }
  }

  // 덱 삭제
  Future<void> deleteDeck(String deckName) async {
    final allData = await readData();
    allData['decks'].remove(deckName);
    await writeData(allData);
    print("덱 삭제 완료: $deckName");
  }

  // 덱에 단어 추가
  Future<void> addWordToDeck(String deckName, Map<String, dynamic> newWord) async {
    final allData = await readData();
    final deck = allData['decks'][deckName] ?? {'words': []};

    // 새 단어에 기본 복습 통계를 반드시 추가합니다.
    newWord['review_stats'] = {
      "study_to_native": {
        "correct_cnt": 0, "incorrect_cnt": 0, "last_reviewed": null,
        "next_review": DateTime.now().toIso8601String(),
      },
      "native_to_study": {
        "correct_cnt": 0, "incorrect_cnt": 0, "last_reviewed": null,
        "next_review": DateTime.now().toIso8601String(),
      }
    };
    
    deck['words'].add(newWord);
    allData['decks'][deckName] = deck;
    await writeData(allData);
    print("단어 저장 완료 (복습 정보 포함): $newWord");
  }
  
  // CSV파일로 덱에 단어 추가 
  Future<int> addWordsFromCsv(String path, String deckName) async {
    try {
      final file = File(path);
      final csvString = await file.readAsString(encoding: utf8);
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
      
      int addedCount = 0;
      for (final row in csvTable) {
        if (row.length >= 2) {
          final String word = row[0].toString().trim();
          final String allMeanings = row[1].toString().trim();
          
          final List<String> meanings = allMeanings.split(';')
                                          .map((m) => m.trim()) // 각 뜻의 앞뒤 공백 제거
                                          .where((m) => m.isNotEmpty) // 비어있는 뜻은 제외
                                          .toList();

          if (word.isNotEmpty && meanings.isNotEmpty) {
            final newWord = {
              'word': word,
              'meaning': meanings,
              'example': '', 
              'createdAt': DateTime.now().toIso8601String(),
            };
            await addWordToDeck(deckName, newWord);
            addedCount++;
          }
        }
      }
      return addedCount;

    } catch (e) {
      print("CSV 처리 중 오류 발생: $e");
      return 0;
    }
  }

  // 덱에 저장된 단어 조회
  Future<List<Word>> getWordsForDeck(String deckName) async {
    final allData = await readData();
    final deck = allData['decks'][deckName];

    if (deck != null && deck['words'] != null) {
      final wordList = deck['words'] as List;
      return wordList.map((wordJson) => Word.fromJson(wordJson)).toList();
    }
    return [];
  }

  // 덱에 저장된 단어 삭제
  Future<void> deleteWordFromDeck(String deckName, Word wordToDelete) async {
    final allData = await readData();
    final deck = allData['decks'][deckName];

    if (deck != null && deck['words'] != null) {
      final wordList = deck['words'] as List;
      
      // wordList에서 삭제할 단어와 'createdAt'(생성 시간)이 같은 항목을 찾아 제거합니다.
      // 생성 시간으로 비교하면 똑같은 단어가 여러 개 있어도 정확히 원하는 것만 지울 수 있습니다.
      wordList.removeWhere((wordJson) => wordJson['createdAt'] == wordToDelete.createdAt);
      
      await writeData(allData);
      print("단어 삭제 완료: ${wordToDelete.word}");
    }
  }
  
  // 덱에 저장된 단어 수정하기
  Future<void> updateWordInDeck(String deckName, Word oldWord, Map<String, dynamic> updatedWordData) async {
    final allData = await readData();
    final deck = allData['decks'][deckName];

    if (deck != null && deck['words'] != null) {
      final wordList = deck['words'] as List;
      final index = wordList.indexWhere((wordJson) => wordJson['createdAt'] == oldWord.createdAt);

      if (index != -1) { // 단어를 찾았다면
        updatedWordData['review_stats'] = oldWord.reviewStats;
        wordList[index] = updatedWordData;
        await writeData(allData);
        print("단어 수정 완료: ${updatedWordData['word']}");
      }
    }
  }

  // 단어의 복습 정보 업데이트
  Future<void> updateWordReviewStats(String deckName, Word word) async {
    final allData = await readData();
    final deck = allData['decks'][deckName];
    if (deck != null && deck['words'] != null) {
      final wordList = deck['words'] as List;
      final index = wordList.indexWhere((wordJson) => wordJson['createdAt'] == word.createdAt);
      if (index != -1) {
        // 기존 단어 데이터를 찾아서 review_stats 부분만 교체
        wordList[index]['review_stats'] = word.reviewStats;
        await writeData(allData);
        print("복습 정보 업데이트 완료: ${word.word}");
      }
    }
  }

  // 학습 로그 기록 
  Future<void> logStudySession(String deckName, int correctAnswers, int incorrectAnswers) async {
    // 0개의 단어를 학습한 경우는 기록하지 않음
    if (correctAnswers == 0 && incorrectAnswers == 0) return;

    final allData = await readData();
    final deck = allData['decks'][deckName];

    // study_log가 없으면 새로 생성
    deck['study_log'] ??= {}; 
    
    // 오늘 날짜를 'YYYY-MM-DD' 형식의 문자열로 만듦
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    // 오늘 날짜의 로그가 없으면 새로 생성
    deck['study_log'][today] ??= {'correct_count': 0, 'incorrect_count': 0};

    // 오늘 날짜의 로그에 정답/오답 개수 누적
    deck['study_log'][today]['correct_count'] += correctAnswers;
    deck['study_log'][today]['incorrect_count'] += incorrectAnswers;

    await writeData(allData);
    print("학습 로그 기록 완료: $today");
  }

  // 특정 덱의 학습로그 가져오기 
  Future<Map<String, dynamic>> getStudyLogForDeck(String deckName) async {
    final allData = await readData();
    final deck = allData['decks'][deckName];
    // study_log가 존재하면 해당 맵을, 없으면 빈 맵을 반환
    return deck?['study_log'] as Map<String, dynamic>? ?? {};
  }
}
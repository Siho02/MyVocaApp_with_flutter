// lib/word_form_screen.dart

import 'package:flutter/material.dart';
import 'package:voca_app/data_manager.dart';
import 'package:voca_app/models/word.dart';

class WordFormScreen extends StatefulWidget {
  final String deckName;
  // 수정 모드일 때는 Word 객체를 받고, 등록 모드일 때는 null을 받습니다.
  // '?'는 null이 될 수 있다는 의미입니다.
  final Word? wordToEdit;

  const WordFormScreen({super.key, required this.deckName, this.wordToEdit});

  @override
  State<WordFormScreen> createState() => _WordFormScreenState();
}

class _WordFormScreenState extends State<WordFormScreen> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();

  // 현재 수정 모드인지 쉽게 확인하기 위한 변수
  bool get isEditMode => widget.wordToEdit != null;

  @override
  void initState() {
    super.initState();
    // 만약 수정 모드라면 (wordToEdit 객체가 있다면),
    // 입력 필드의 초기값을 설정합니다.
    if (isEditMode) {
      _wordController.text = widget.wordToEdit!.word;
      _meaningController.text = widget.wordToEdit!.meaning.join('\n');
      _exampleController.text = widget.wordToEdit!.example;
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    super.dispose();
  }
  
  // 저장/수정 버튼을 눌렀을 때 실행될 로직을 별도 함수로 분리
  Future<void> _submitForm() async {
    final String word = _wordController.text.trim();
    final List<String> meanings = _meaningController.text
        .trim()
        .split('\n')
        .where((meaning) => meaning.isNotEmpty)
        .toList();
    final String example = _exampleController.text.trim();

    if (word.isEmpty || meanings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('단어와 뜻은 반드시 입력해야 합니다.')),
      );
      return; // 함수 종료
    }

    final dataManager = DataManager();

    if (isEditMode) {
      // --- 수정 모드 로직 ---
      final updatedWord = {
        'word': word,
        'meaning': meanings,
        'example': example,
        'createdAt': widget.wordToEdit!.createdAt,
      };
      await dataManager.updateWordInDeck(widget.deckName, widget.wordToEdit!, updatedWord);
    } else {
      // --- 등록 모드 로직 ---
      final newWord = {
        'word': word,
        'meaning': meanings,
        'example': example,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await dataManager.addWordToDeck(widget.deckName, newWord);
    }

    if (mounted) Navigator.pop(context, true); // 작업 완료 후 true를 반환하며 뒤로 가기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 수정 모드와 등록 모드에 따라 제목을 다르게 표시
        title: Text('${widget.deckName}: ${isEditMode ? '단어 수정' : '단어 추가'}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _wordController,
              decoration: const InputDecoration(labelText: '단어', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _meaningController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(labelText: '뜻 (줄바꿈으로 여러 개 입력)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _exampleController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(labelText: '예문 (선택 사항)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitForm, // 버튼을 누르면 _submitForm 함수 실행
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              // 수정 모드와 등록 모드에 따라 버튼 텍스트를 다르게 표시
              child: Text(isEditMode ? '수정 완료' : '저장하기', style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
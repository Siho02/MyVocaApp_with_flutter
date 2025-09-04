// lib/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:voca_app/data_manager.dart';

class StatsScreen extends StatefulWidget {
  final String deckName;
  const StatsScreen({super.key, required this.deckName});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DataManager dataManager = DataManager();
  bool _isLoading = true;
  int _totalCorrect = 0;
  int _totalIncorrect = 0;
  Map<String, dynamic> _studyLog = {};

  @override
  void initState() {
    super.initState();
    // 화면이 시작될 때 통계 데이터를 불러옵니다.
    _loadStats();
  }

  Future<void> _loadStats() async {
    final log = await dataManager.getStudyLogForDeck(widget.deckName);
    
    int correctSum = 0;
    int incorrectSum = 0;

    // log 맵의 모든 값을 순회하며 정답/오답 횟수를 합산
    log.forEach((date, dailyLog) {
      correctSum += dailyLog['correct_count'] as int? ?? 0;
      incorrectSum += dailyLog['incorrect_count'] as int? ?? 0;
    });

    // 3. 계산된 값을 setState를 통해 상태 변수에 저장하고 화면 갱신
    setState(() {
      _studyLog = log;
      _totalCorrect = correctSum;
      _totalIncorrect = incorrectSum;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.deckName}: 통계'),
      ),
      // 로딩 중일 경우 로딩 인디케이터를 표시
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('종합 정보', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: const Text('총 정답'),
                      // 4. 하드코딩된 '0 개' 대신 상태 변수 사용
                      trailing: Text('$_totalCorrect 개', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cancel, color: Colors.red),
                      title: const Text('총 오답'),
                      // 4. 하드코딩된 '0 개' 대신 상태 변수 사용
                      trailing: Text('$_totalIncorrect 개', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('학습 활동', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('여기에 학습 활동 그래프가 표시될 예정입니다.'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
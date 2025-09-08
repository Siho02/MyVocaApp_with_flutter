// lib/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:voca_app/data_manager.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

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
  Map<DateTime, int> _heatmapDatasets = {};

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
    Map<DateTime, int> datasets = {};

    log.forEach((dateString, dailyLog) {
      final correct = dailyLog['correct_count'] as int? ?? 0;
      final incorrect = dailyLog['incorrect_count'] as int? ?? 0;
      
      correctSum += correct;
      incorrectSum += incorrect;

      final date = DateTime.parse(dateString);
      datasets[date] = correct + incorrect;
    });

    setState(() {
      _totalCorrect = correctSum;
      _totalIncorrect = incorrectSum;
      _heatmapDatasets = datasets; // 변환된 데이터를 상태 변수에 저장
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
                      trailing: Text('$_totalCorrect 개', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cancel, color: Colors.red),
                      title: const Text('총 오답'),
                      trailing: Text('$_totalIncorrect 개', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('학습 활동', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: HeatMapCalendar(
                        datasets: _heatmapDatasets,
                        colorMode: ColorMode.color,
                        showColorTip: false, // 색상별 수치 안내 팁 숨기기
                        colorsets: const {
                          1: Color.fromARGB(255, 160, 215, 239), // 1~3개: 연한 파랑
                          4: Color.fromARGB(255, 108, 184, 216), // 4~6개
                          7: Color.fromARGB(255, 50, 150, 190),  // 7~9개
                          10: Color.fromARGB(255, 1, 97, 138),  // 10개 이상: 진한 파랑
                        },
                        onClick: (date) {
                          final count = _heatmapDatasets[date] ?? 0;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${date.toLocal().toString().substring(0, 10)}: 총 ${count}개 학습'))
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
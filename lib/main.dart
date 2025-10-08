// lib/main.dart

import 'package:flutter/material.dart';
import 'package:voca_app/data_manager.dart';
import 'package:voca_app/home_screen.dart';
import 'package:voca_app/settings_screen.dart'; 
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; // 앱 전체의 테마 모드를 관리하는 상태 변수
  final DataManager _dataManager = DataManager(); // DataManager 인스턴스

  @override
  void initState() {
    super.initState();
    _loadThemeMode(); // 앱 시작 시 저장된 테마 모드 불러오기
  }

  // 저장된 테마 모드를 불러오는 함수
  Future<void> _loadThemeMode() async {
    final savedThemeMode = await _dataManager.getAppThemeMode();
    setState(() {
      _themeMode = savedThemeMode;
    });
  }

  // 테마 모드가 변경되었을 때 호출될 함수 (SettingsScreen으로부터 콜백)
  void _onThemeModeChanged(ThemeMode newMode) {
    setState(() {
      _themeMode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '나의 단어장',
      // --- 테마 설정 적용 ---
      theme: ThemeData(
        brightness: Brightness.light, // 라이트 모드 기본 설정
        primarySwatch: Colors.blue, // 앱의 기본 색상
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, // 다크 모드 기본 설정
        primarySwatch: Colors.blueGrey, // 다크 모드에서는 좀 더 차분한 색상
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          color: Colors.grey[800], // 다크 모드 카드 색상
        ),
      ),
      themeMode: _themeMode, // <--- 이곳에서 현재 선택된 테마 모드를 앱에 적용
      home: DeckSelectionScreen(onThemeModeChanged: _onThemeModeChanged, initialThemeMode: _themeMode,), // <--- DeckSelectionScreen에 테마 정보 전달
    );
  }
}

class DeckSelectionScreen extends StatefulWidget {
  // 테마 변경 콜백과 초기 테마 모드 추가
  final Function(ThemeMode) onThemeModeChanged;
  final ThemeMode initialThemeMode;

  const DeckSelectionScreen({
    super.key,
    required this.onThemeModeChanged,
    required this.initialThemeMode,
  });

  @override
  State<DeckSelectionScreen> createState() => _DeckSelectionScreenState();
}

class _DeckSelectionScreenState extends State<DeckSelectionScreen> {
  final DataManager dataManager = DataManager();
  List<String> _deckNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeckNames();
  }

  Future<void> _loadDeckNames() async {
    final names = await dataManager.getDeckNames();
    setState(() {
      _deckNames = names;
      _isLoading = false;
    });
  }

  // 덱 삭제 함수는 그대로 ...
  void _confirmDeleteDeck(String deckName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('덱 삭제 확인'),
          content: Text("'$deckName' 덱을 정말로 삭제하시겠습니까?"),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await dataManager.deleteDeck(deckName);
                Navigator.of(context).pop();
                _loadDeckNames(); // 덱 목록 새로고침
              },
            ),
          ],
        );
      },
    );
  }

  // --- 데이터 관리 옵션 함수 (이전 단계에서 추가) ---
  Future<void> _showDataManagementOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('데이터 백업'),
              onTap: () async {
                Navigator.pop(context); // 바텀 시트 닫기
                await _performBackup(); // 백업 기능 실행
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('데이터 복원'),
              onTap: () async {
                Navigator.pop(context); // 바텀 시트 닫기
                await _performRestore(); // 복원 기능 실행
              },
            ),
          ],
        );
      },
    );
  }

  // --- 백업 실행 함수 (이전 단계에서 추가) ---
  Future<void> _performBackup() async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '데이터 백업 파일 저장',
        fileName: 'voca_app_backup_${DateTime.now().toIso8601String().substring(0, 10)}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath != null) {
        final success = await dataManager.backupData(outputPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? '데이터 백업 성공!' : '데이터 백업 실패!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('데이터 백업 취소')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백업 중 오류 발생: ${e.toString()}')),
        );
      }
    }
  }

  // --- 복원 실행 함수 (이전 단계에서 추가) ---
  Future<void> _performRestore() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: '복원할 데이터 파일 선택',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final success = await dataManager.restoreData(path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? '데이터 복원 성공! 앱을 재시작합니다.' : '데이터 복원 실패!')),
          );
          if (success) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => DeckSelectionScreen(onThemeModeChanged: widget.onThemeModeChanged, initialThemeMode: widget.initialThemeMode)), // <--- 테마 정보 다시 전달
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('데이터 복원 취소')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복원 중 오류 발생: ${e.toString()}')),
        );
      }
    }
  }


  // --- [새 기능] 설정 화면으로 이동하는 함수 ---
  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialThemeMode: widget.initialThemeMode, // 현재 테마 모드를 설정 화면으로 전달
          onThemeModeChanged: widget.onThemeModeChanged, // 테마 변경 콜백 함수 전달
        ),
      ),
    );
    // 설정 화면에서 돌아왔을 때, 혹시 모를 덱 이름 변경 등을 대비해 다시 로드
    _loadDeckNames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 단어장'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: _showDataManagementOptions,
            tooltip: '앱 데이터 관리',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: '설정',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deckNames.isEmpty
              ? const Center(child: Text('새 덱을 만들어 단어를 학습하세요!'))
              : ListView.builder(
                  itemCount: _deckNames.length,
                  itemBuilder: (context, index) {
                    final deckName = _deckNames[index];
                    
                    return Dismissible(
                      key: Key(deckName), 
                      // 1. direction: 오른쪽에서 왼쪽으로 미는 것만 허용
                      direction: DismissDirection.endToStart, 
                      
                      // background: 오른쪽에서 왼쪽으로 밀 때 나타나는 배경
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      
                      // 2. confirmDismiss: 스와이프가 끝났을 때 사용자에게 확인을 요청합니다.
                      confirmDismiss: (direction) async {
                        // showDialog를 띄워 사용자에게 삭제 여부를 묻습니다.
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('삭제 확인'),
                              content: Text("'$deckName' 덱을 정말로 삭제하시겠습니까?"),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('취소'),
                                  onPressed: () => Navigator.of(context).pop(false), // 취소 시 false 반환
                                ),
                                TextButton(
                                  child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                  onPressed: () => Navigator.of(context).pop(true), // 삭제 시 true 반환
                                ),
                              ],
                            );
                          },
                        );
                      },
                      
                      // onDismissed: 사용자가 삭제를 '확인'했을 때만 호출됩니다.
                      onDismissed: (direction) {
                        // 3. 실제 삭제 로직 호출
                        dataManager.deleteDeck(deckName);

                        // UI에서도 즉시 목록을 갱신합니다.
                        // 이전에 _deckNames.removeAt(index)를 사용했지만,
                        // _loadDeckNames()를 다시 호출하는 것이 데이터 일관성 면에서 더 안전합니다.
                        _loadDeckNames(); 

                        // 사용자에게 삭제되었음을 알려줍니다.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("'$deckName' 덱이 삭제되었습니다.")),
                        );
                      },
                      
                      // child: 기존 카드 UI는 그대로 유지
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.folder_open),
                          title: Text(deckName),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(deckName: deckName),
                              ),
                            ).then((_) => _loadDeckNames());
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDeckDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDeckDialog(BuildContext context) async {
    String? newDeckName = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('새 단어 덱 만들기'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: '덱 이름'),
            onChanged: (value) {
              newDeckName = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('만들기'),
              onPressed: () async {
                if (newDeckName != null && newDeckName!.isNotEmpty) {
                  await dataManager.createDeck(newDeckName!);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _loadDeckNames(); // 덱 목록 새로고침
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
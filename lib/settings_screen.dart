import 'package:flutter/material.dart';
import 'package:voca_app/data_manager.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final Function(ThemeMode) onThemeModeChanged;

  const SettingsScreen({
    super.key,
    required this.initialThemeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataManager _dataManager = DataManager();
  late ThemeMode _selectedThemeMode; // 사용자가 선택한 테마 모드를 저장

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.initialThemeMode; // 초기 테마 모드로 설정
  }

  // 테마 모드 변경 시 호출될 함수
  void _changeThemeMode(ThemeMode? newMode) async {
    if (newMode != null && newMode != _selectedThemeMode) {
      setState(() {
        _selectedThemeMode = newMode;
      });
      await _dataManager.saveAppThemeMode(newMode); // DataManager를 통해 설정 저장
      widget.onThemeModeChanged(newMode); // 홈 화면에 변경 사항 알림
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '테마 설정',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('시스템 기본값'),
            value: ThemeMode.system,
            groupValue: _selectedThemeMode,
            onChanged: _changeThemeMode,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('라이트 모드'),
            value: ThemeMode.light,
            groupValue: _selectedThemeMode,
            onChanged: _changeThemeMode,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('다크 모드'),
            value: ThemeMode.dark,
            groupValue: _selectedThemeMode,
            onChanged: _changeThemeMode,
          ),
        ],
      ),
    );
  }
}
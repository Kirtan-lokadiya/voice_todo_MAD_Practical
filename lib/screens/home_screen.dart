import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../providers/task_provider.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  String _transcription = 'Press mic to start speaking';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initTTS();
    _syncOfflineTasks();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          final words = result.recognizedWords;
          setState(() => _transcription = words);
          _handleCommand(words);
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _handleCommand(String words) async {
    final command = words.toLowerCase();

    // Handle Edit: "edit task buy milk to buy almond milk"
    final editMatch = RegExp(r'^(edit|update) task (.+?) (?:to|:) (.+)$')
        .firstMatch(command);
    if (editMatch != null) {
      final oldTitle = editMatch.group(2)!;
      final newTitle = editMatch.group(3)!;
      final tasks = ref.read(taskListProvider);
      Task? target = tasks.firstWhere(
        (t) => t.title.toLowerCase() == oldTitle.toLowerCase(),
        orElse: () => Task(title: ''),
      );
      if (target.title.isNotEmpty) {
        final conn = await Connectivity().checkConnectivity();
        if (conn != ConnectivityResult.none) {
          ref.read(taskListProvider.notifier).edit(target.id, newTitle);
          _speak("Task updated: $newTitle");
          setState(() => _transcription = 'Updated: $newTitle');
        } else {
          final box = Hive.box('offline_tasks');
          await box.add('EDIT::$oldTitle::$newTitle');
          ref.read(taskListProvider.notifier).edit(target.id, newTitle);
          _speak("Offline: Task updated locally to $newTitle");
          setState(() => _transcription = 'Saved edit offline: $newTitle');
        }
      } else {
        _speak("Task '$oldTitle' not found.");
        setState(() => _transcription = "No task: $oldTitle");
      }
      return;
    }

    // Handle Add
    final addMatch = RegExp(r'^(add task|create task) (.+)$')
        .firstMatch(command);
    if (addMatch != null) {
      final title = addMatch.group(2)!;
      final conn = await Connectivity().checkConnectivity();
      final isOnline = conn != ConnectivityResult.none;

      if (isOnline) {
        try {
          await ApiService.sendTask(title);
          ref.read(taskListProvider.notifier).add(title);
          _speak("Task added and synced: $title");
          setState(() => _transcription = 'Synced: $title');
        } catch (_) {
          final box = Hive.box('offline_tasks');
          await box.add(title);
          ref.read(taskListProvider.notifier).add(title);
          _speak("Added locally. Sync failed.");
          setState(() => _transcription = 'Saved offline: $title');
        }
      } else {
        final box = Hive.box('offline_tasks');
        await box.add(title);
        ref.read(taskListProvider.notifier).add(title);
        _speak("You're offline. Task saved locally: $title");
        setState(() => _transcription = 'Saved offline: $title');
      }
      return;
    }

    // Fallback
    _speak("Sorry, I didn’t understand that.");
    setState(() => _transcription = 'Command not recognized');
  }

  Future<void> _syncOfflineTasks() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn != ConnectivityResult.none) {
      final box = Hive.box('offline_tasks');
      final entries = box.values.cast<String>().toList();
      for (final entry in entries) {
        if (entry.startsWith('EDIT::')) {
          final parts = entry.split('::');
          final oldT = parts[1], newT = parts[2];
          final tasks = ref.read(taskListProvider);
          final task = tasks.firstWhere((t) => t.title == oldT, orElse: () => Task(title: ''));
          if (task.title.isNotEmpty) {
            ref.read(taskListProvider.notifier).edit(task.id, newT);
          }
        } else {
          await ApiService.sendTask(entry);
          ref.read(taskListProvider.notifier).add(entry);
        }
      }
      await box.clear();
      if (entries.isNotEmpty) {
        _speak("${entries.length} offline change(s) synced.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice ToDo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _transcription,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                for (final task in tasks)
                  CheckboxListTile(
                    value: task.isCompleted,
                    title: Text(task.title),
                    onChanged: (_) =>
                        ref.read(taskListProvider.notifier).toggle(task.id),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}

import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';



class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _syncOfflineTasks() async {
  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity != ConnectivityResult.none) {
    final box = Hive.box('offline_tasks');
    final tasks = box.values.cast<String>().toList();

    for (final title in tasks) {
      ref.read(taskListProvider.notifier).add(title);
    }

    await box.clear();
    if (tasks.isNotEmpty) {
      _speak("${tasks.length} offline task(s) synced.");
    }
  }
}

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
  _syncOfflineTasks(); // 👈 sync any offline tasks
}


  Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop(); // stop any ongoing speech
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
          _tryAddTask(words);
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

void _tryAddTask(String words) async {
  final command = words.toLowerCase();
  final match = RegExp(r'^(add task|create task)\s+(.+)$').firstMatch(command);

  if (match != null) {
    final title = match.group(2)!;
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;

    if (isOnline) {
      try {
        await ApiService.sendTask(title);
        ref.read(taskListProvider.notifier).add(title);
        _speak("Task added and synced: $title");
        setState(() => _transcription = 'Synced: $title');
      } catch (e) {
        _speak("Task added locally. Sync failed.");
        setState(() => _transcription = 'Sync failed. Saved locally.');
        final box = Hive.box('offline_tasks');
        await box.add(title);
      }
    } else {
      final box = Hive.box('offline_tasks');
      await box.add(title);
      _speak("You're offline. Task saved locally: $title");
      setState(() => _transcription = 'Saved offline: $title');
    }
  } else {
    _speak("Sorry, I didn’t understand that. Please say: Add task followed by your task.");
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/task_provider.dart';
import '../models/task.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcription = 'Press mic to start speaking';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          setState(() {
            _transcription = result.recognizedWords;
          });
          _tryAddTask(result.recognizedWords);
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _tryAddTask(String words) {
    final command = words.toLowerCase();
    final match = RegExp(r'^(add task|create task)\s+(.+)$')
        .firstMatch(command);
    if (match != null) {
      final title = match.group(2)!;
      ref.read(taskListProvider.notifier).add(title);
      // Clear transcription to avoid duplicate adds
      setState(() => _transcription = 'Added: $title');
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

import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:readright/models/word.dart';
import 'package:readright/widgets/student_base_scaffold.dart';

class WordListPage extends StatefulWidget {
  const WordListPage({super.key});

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  bool _loading = true;
  List<Word> _words = [];
  String _listTitle = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentWordList();
  }

  Future<void> _loadCurrentWordList() async {
    final supabase = Supabase.instance.client;

    try {
      final listData = await supabase
          .from('word_lists')
          .select('id, title')
          .eq('is_current', true)
          .maybeSingle();

      if (listData == null) {
        setState(() {
          _error = 'No current word list found.';
          _loading = false;
        });
        return;
      }

      final listId = listData['id'] as String;
      _listTitle = listData['title'] ?? 'Current List';

      final wordData = await supabase
          .from('words')
          .select('id, text, type, sentences')
          .eq('list_id', listId)
          .order('text', ascending: true);

      _words = wordData.map<Word>((w) {
        final sentenceList = (w['sentences'] as List?)?.cast<String>() ?? [];
        return Word(
          id: w['id'],
          text: w['text'],
          type: w['type'],
          sentences: sentenceList,
        );
      }).toList();

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading current list: $e');
      setState(() {
        _error = 'Failed to load current list.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentBaseScaffold(
      currentIndex: 2,
      pageTitle: 'Word List',
      pageIcon: Icons.list,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)),
                )
              else
                _buildWordList(),
              const SizedBox(height: 24),
              _buildButtons(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordList() {
    if (_words.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No words found in the current list.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: _words.map((w) => _buildWordItem(w)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildWordItem(Word word) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Color(AppConfig.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(AppConfig.primaryColor), width: 2),
        ),
        child: Text(
          '${word.text} (${word.type})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/practice'),
          icon: const Icon(Icons.mic, size: 22),
          label: const Text(
            'Go To Practice',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(AppConfig.secondaryColor),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}

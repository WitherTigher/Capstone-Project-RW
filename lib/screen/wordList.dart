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

  // ------------------------------------------------------------
  // LOAD CURRENT LIST + WORDS
  // ------------------------------------------------------------
  Future<void> _loadCurrentWordList() async {
    final supabase = Supabase.instance.client;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not logged in.';
          _loading = false;
        });
        return;
      }

      // 1. Fetch student’s current list index
      final userData = await supabase
          .from('users')
          .select('current_list_int')
          .eq('id', user.id)
          .maybeSingle();

      if (userData == null || userData['current_list_int'] == null) {
        setState(() {
          _error = 'No Dolch list assigned.';
          _loading = false;
        });
        return;
      }

      final currentOrder = userData['current_list_int'] as int;

      // 2. Find the matching word list
      final listData = await supabase
          .from('word_lists')
          .select('id, title, list_order')
          .eq('list_order', currentOrder)
          .maybeSingle();

      if (listData == null) {
        setState(() {
          _error = 'Word list not found for order $currentOrder.';
          _loading = false;
        });
        return;
      }

      final listId = listData['id'] as String;
      _listTitle = listData['title'] ?? 'Current List';

      // 3. Fetch words from this list
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
        _error = 'Failed to load current word list.';
        _loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  //  UI
  // ------------------------------------------------------------
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
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
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
            children: [
              Text(
                _listTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              /// <<< NEW: horizontal flow layout >>>
              Wrap(
                spacing: 16,       // horizontal spacing
                runSpacing: 16,    // vertical spacing
                alignment: WrapAlignment.center,
                children: _words.map((w) => _buildWordChip(w)).toList(),
              ),
            ],
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
          word.text,
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
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/practice');
          },
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

  Widget _buildWordChip(Word word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Color(AppConfig.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(AppConfig.primaryColor), width: 2),
      ),
      child: Text(
        word.text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

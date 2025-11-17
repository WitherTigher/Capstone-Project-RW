import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/models/word.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:readright/providers/teacherProvider.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';

class TeacherWordListDetailsPage extends StatefulWidget {
  final WordListItem listItem;

  const TeacherWordListDetailsPage({super.key, required this.listItem});

  @override
  State<TeacherWordListDetailsPage> createState() =>
      _TeacherWordListDetailsPageState();
}

class _TeacherWordListDetailsPageState
    extends State<TeacherWordListDetailsPage> {
  bool _loading = true;
  String? _error;

  List<Word> _words = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final supabase = Supabase.instance.client;

    try {
      final wordData = await supabase
          .from('words')
          .select('id, text, type, sentences')
          .eq('list_id', widget.listItem.id)
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
      setState(() {
        _loading = false;
        _error = 'Failed to load words.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherBaseScaffold(
      currentIndex: 1,
      pageTitle: widget.listItem.title,
      pageIcon: Icons.library_books,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            : _buildWordListUI(),
      ),
    );
  }

  Widget _buildWordListUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      widget.listItem.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: _words.map((w) => _buildWordChip(w)).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWordChip(Word word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Color(AppConfig.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(AppConfig.primaryColor),
          width: 2,
        ),
      ),
      child: Text(
        word.text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
      ),
    );
  }
}

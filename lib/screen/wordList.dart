import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/providers/mock_provider.dart';
import 'package:readright/widgets/base_scaffold.dart';
import 'package:readright/models/word.dart';

class WordListPage extends StatefulWidget {
  const WordListPage({super.key});
  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  final _provider = MockProvider();
  late Future<List<Word>> _wordListFuture;

  @override
  void initState() {
    super.initState();
    _wordListFuture = _provider.fetchWordList();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 2,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section (keep all of this)
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Color(AppConfig.primaryColor),
                child: const Row(
                  children: [
                    Icon(Icons.feedback, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Word List',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.wordpress,
                              color: Color(AppConfig.secondaryColor),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Provided Words',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        FutureBuilder<List<Word>>(
                          future: _wordListFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Text('No words found.');
                            }

                            final words = snapshot.data!;
                            return Column(
                              children: words
                                  .map(
                                    (w) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10.0,
                                      ),
                                      child: _buildPhonemeChip(
                                        'Word: ${w.text} Type: ${w.type}',
                                        true,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons (keep as-is)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/practice');
                        },
                        icon: const Icon(Icons.games, size: 22),
                        label: const Text(
                          'Go To Practice',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/teacherDashboard');
                        },
                        icon: const Icon(Icons.list_alt, size: 22),
                        label: const Text(
                          'Go to Teacher Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(AppConfig.secondaryColor),
                          side: BorderSide(
                            color: Color(AppConfig.secondaryColor),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // Keep your chip builder helper
  Widget _buildPhonemeChip(String phoneme, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCorrect
            ? Color(AppConfig.primaryColor).withOpacity(0.1)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? Color(AppConfig.primaryColor)
              : Colors.red.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect
                ? Color(AppConfig.primaryColor)
                : Colors.red.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            phoneme,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isCorrect ? const Color(0xFF2D3748) : Colors.red.shade900,
            ),
          ),
          const Spacer(),
          Text(
            isCorrect ? 'Inuse' : 'Unused',
            style: TextStyle(
              fontSize: 14,
              color: isCorrect
                  ? Color(AppConfig.primaryColor)
                  : Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

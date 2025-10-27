import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/base_scaffold.dart';

class WordListPage extends StatelessWidget {
  const WordListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 2,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Color(AppConfig.primaryColor),
                child: Row(
                  children: const [
                    Icon(Icons.feedback, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Word List ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Header Section with Word and Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),

              // Phoneme Breakdown Card
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
                        _buildPhonemeChip('Word:Cat Type:Phonic', true),
                        const SizedBox(height: 10),
                        _buildPhonemeChip('Word:Rat Type:Phonic', true),
                        const SizedBox(height: 10),
                        _buildPhonemeChip('Word:Fish Type:Phonic', true),
                        const SizedBox(height: 10),
                        _buildPhonemeChip('Word:Little Type:Dolch', true),
                        const SizedBox(height: 10),
                        _buildPhonemeChip('Word:Round Type:Dolch', true),
                        const SizedBox(height: 10),
                        _buildPhonemeChip('Word:Before Type:Dolch', true),
                        const SizedBox(height: 10),
                        _buildPhonemeChip(
                          'Words fan/van Type:MinimalPairs',
                          true,
                        ),
                        const SizedBox(height: 10),
                        _buildPhonemeChip(
                          'Words boat/moat Type:MinimalPairs',
                          true,
                        ),
                        const SizedBox(height: 10),
                        _buildPhonemeChip(
                          'Words fox/box Type:MinimalPairs',
                          true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Try Again Button
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
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot edit words Right now'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, size: 22),
                        label: const Text(
                          'Edit Word List',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(AppConfig.primaryColor),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Back to Word List Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/teacherDashboard');
                        },
                        icon: const Icon(Icons.list_alt, size: 22),
                        label: const Text(
                          'Go to Teacher DashBoard',
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

              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

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

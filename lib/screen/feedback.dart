import 'package:flutter/material.dart';
import 'package:readright/config/config.dart';
import 'package:readright/widgets/student_base_scaffold.dart';
import 'package:flutter/material.dart';


class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentBaseScaffold(
      currentIndex: 4,
      pageTitle: 'Practice Feedback',
      pageIcon: Icons.feedback,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildScoreCard(),
              const SizedBox(height: 16),
              _buildSoundAnalysisCard(),
              const SizedBox(height: 16),
              _buildTipsCard(),
              const SizedBox(height: 24),
              _buildActionButtons(context),
              const SizedBox(height: 100), // for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ Header Section ------------------
  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(AppConfig.primaryColor).withOpacity(0.2),
              border: Border.all(
                color: Color(AppConfig.primaryColor),
                width: 3,
              ),
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: Color(AppConfig.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'cat',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Excellent pronunciation!',
            style: TextStyle(
              fontSize: 18,
              color: Color(AppConfig.primaryColor),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ Pronunciation Score Card ------------------
  Widget _buildScoreCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Color(AppConfig.primaryColor), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Pronunciation Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: 0.88,
                            minHeight: 14,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(AppConfig.primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accuracy: 88%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(AppConfig.primaryColor).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(AppConfig.primaryColor),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '88',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConfig.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ Sound Analysis Card ------------------
  Widget _buildSoundAnalysisCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.hearing, color: Color(AppConfig.secondaryColor), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Sound Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPhonemeChip('/k/', true),
              const SizedBox(height: 10),
              _buildPhonemeChip('/æ/', true),
              const SizedBox(height: 10),
              _buildPhonemeChip('/t/', true),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ Tips Card ------------------
  Widget _buildTipsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.lightbulb, color: Color(0xFFFBBF24), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Tips for Improvement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTipItem('Keep practicing short vowel sounds'),
              _buildTipItem('Focus on clear consonant endings'),
              _buildTipItem('Try recording yourself and comparing'),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ Action Buttons ------------------
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/practice'),
              icon: const Icon(Icons.replay, size: 22),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConfig.secondaryColor),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    content: Text('Next word feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 22),
              label: const Text(
                'Next Word',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConfig.primaryColor),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/wordlist'),
              icon: const Icon(Icons.list_alt, size: 22),
              label: const Text(
                'Back to Word List',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(AppConfig.secondaryColor),
                side: BorderSide(color: Color(AppConfig.secondaryColor), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ Helper Widgets ------------------
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
            isCorrect ? 'Correct' : 'Try again',
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

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              size: 18, color: Color(AppConfig.primaryColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

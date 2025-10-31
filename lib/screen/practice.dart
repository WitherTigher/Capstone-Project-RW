import 'package:readright/config/config.dart';
import 'package:flutter/material.dart';
import 'package:readright/widgets/base_scaffold.dart';
import 'package:readright/services/databaseHelper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// MOCK FUNCTION TO UPLOAD RECORDING TO SUPABASE STORAGE
// Future<String?> uploadRecording(File file, String userId) async {
//   final supabase = Supabase.instance.client;
//
//   // Generate a unique filename
//   final fileName =
//       'recordings/$userId/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
//
//   // Detect content type (optional)
//   final mimeType = lookupMimeType(file.path) ?? 'audio/wav';
//
//   try {
//     await supabase.storage.from('Uploads').upload(
//       fileName,
//       file,
//       fileOptions: FileOptions(
//         cacheControl: '3600',
//         upsert: false,
//         contentType: mimeType,
//       ),
//     );
//
//     // Get a public URL
//     final publicUrl =
//     supabase.storage.from('Uploads').getPublicUrl(fileName);
//
//     return publicUrl;
//   } catch (e) {
//     print('Upload failed: $e');
//     return null;
//   }
// }
/// THEN STORE THE URL IN THE DATABASE
// final user = Supabase.instance.client.auth.currentUser;
// if (user == null) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(content: Text('Please log in to upload recordings.')),
//   );
//   return;
// }
//
// // Assume 'audioFile' is a File you just recorded
// final url = await uploadRecording(audioFile, user.id);
//
// if (url != null) {
//   // Store this URL in Supabase DB
//   await Supabase.instance.client.from('attempts').insert({
//     'user_id': user.id,
//     'word_id': wordId,
//     'score': analysisScore,
//     'feedback': feedback,
//     'recording_url': url, // <-- this is the url to the uploaded file
//   });
// }




class PracticePage extends StatelessWidget {
  const PracticePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 1,
      pageTitle: 'Practice',
      pageIcon: Icons.school,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                child: Column(
                  children: [
                    // Success Icon
                    Icon(
                      Icons.mic_rounded,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    // Word Practiced
                    const Text(
                      'cat',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement next word logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Next word feature coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle, size: 22),
                        label: const Text(
                          'Record Word',
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
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: Color(AppConfig.primaryColor),
          ),
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

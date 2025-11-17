import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:readright/widgets/teacher_base_scaffold.dart';
import 'package:readright/providers/teacherProvider.dart';
import 'package:readright/screen/teacher/teacherWordListDetailsPage.dart';
import 'package:readright/config/config.dart';

class TeacherWordListsPage extends StatelessWidget {
  const TeacherWordListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WordListsView();
  }
}

class _WordListsView extends StatelessWidget {
  const _WordListsView();

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherProvider>(
      builder: (context, provider, _) {
        return TeacherBaseScaffold(
          currentIndex: 1,
          pageTitle: 'Word Lists',
          pageIcon: Icons.library_books,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: provider.refreshWordLists,
              child: provider.listsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.listsError != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    provider.listsError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : _buildListView(provider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(TeacherProvider provider) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: provider.wordLists.length,
      itemBuilder: (context, index) {
        final item = provider.wordLists[index];
        return _buildListCard(context, item);
      },
    );
  }

  Widget _buildListCard(BuildContext context, WordListItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherWordListDetailsPage(listItem: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                Icons.list_alt,
                color: Color(AppConfig.primaryColor),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Created: ${item.createdAt.toLocal()}'.split('.').first,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

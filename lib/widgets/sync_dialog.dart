import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readright/config/config.dart';
import 'package:readright/providers/word_provider.dart';
import 'package:readright/services/sync_service.dart';

class SyncDialog extends StatefulWidget {
  final WordProvider wordProvider;

  const SyncDialog({Key? key, required this.wordProvider}) : super(key: key);

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog> {
  bool _syncing = false;
  SyncResult? _result;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    setState(() => _syncing = true);
    
    final result = await widget.wordProvider.syncOfflineAttempts();
    
    if (mounted) {
      setState(() {
        _syncing = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _syncing
                ? Icons.sync
                : _result?.success == true
                    ? Icons.check_circle
                    : Icons.error,
            color: _syncing
                ? Color(AppConfig.secondaryColor)
                : _result?.success == true
                    ? Color(AppConfig.primaryColor)
                    : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(_syncing ? 'Syncing...' : 'Sync Complete'),
        ],
      ),
      content: _syncing ? _buildSyncingContent() : _buildResultContent(),
      actions: _syncing
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
    );
  }

  Widget _buildSyncingContent() {
    return Consumer<WordProvider>(
      builder: (context, wordProvider, child) {
        final syncService = wordProvider.syncService;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(AppConfig.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Syncing ${syncService.syncProgress} of ${syncService.syncTotal}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: syncService.syncPercentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppConfig.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultContent() {
    if (_result == null) {
      return const Text('No sync result available');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_result!.message),
        if (_result!.syncedCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Successfully synced: ${_result!.syncedCount}',
            style: TextStyle(color: Color(AppConfig.primaryColor)),
          ),
        ],
        if (_result!.failedCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Failed to sync: ${_result!.failedCount}',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
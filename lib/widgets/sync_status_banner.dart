import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readright/config/config.dart';
import 'package:readright/providers/word_provider.dart';
import 'package:readright/services/sync_service.dart';
import 'package:readright/widgets/sync_dialog.dart';

/// Banner showing sync status and offline queue
class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({Key? key}) : super(key: key);

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  QueueStatus? _queueStatus;

  @override
  void initState() {
    super.initState();
    _loadQueueStatus();
  }

  Future<void> _loadQueueStatus() async {
    final status = await context.read<WordProvider>().getQueueStatus();
    if (mounted) {
      setState(() => _queueStatus = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_queueStatus == null || !_queueStatus!.hasQueuedItems) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _queueStatus!.hasConnection
            ? Color(AppConfig.primaryColor).withOpacity(0.1)
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _queueStatus!.hasConnection
              ? Color(AppConfig.primaryColor)
              : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _queueStatus!.hasConnection
                ? Icons.cloud_upload
                : Icons.cloud_off,
            color: _queueStatus!.hasConnection
                ? Color(AppConfig.primaryColor)
                : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _queueStatus!.hasConnection
                      ? 'Ready to sync'
                      : 'Offline mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _queueStatus!.hasConnection
                        ? Color(AppConfig.primaryColor)
                        : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_queueStatus!.queuedCount} practice ${_queueStatus!.queuedCount == 1 ? 'attempt' : 'attempts'} pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (_queueStatus!.needsSync)
            TextButton(
              onPressed: () => _showSyncDialog(),
              child: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }

  Future<void> _showSyncDialog() async {
    final wordProvider = context.read<WordProvider>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncDialog(wordProvider: wordProvider),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readright/config/config.dart';
import 'package:readright/providers/word_provider.dart';
import 'package:readright/services/sync_service.dart';
import 'package:intl/intl.dart';
import 'package:readright/widgets/sync_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  QueueStatus? _queueStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQueueStatus();
  }

  Future<void> _loadQueueStatus() async {
    final status = await context.read<WordProvider>().getQueueStatus();
    if (mounted) {
      setState(() {
        _queueStatus = status;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Color(AppConfig.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSyncSection(),
                  const SizedBox(height: 16),
                  _buildConnectionStatus(),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                    Icons.sync,
                    color: Color(AppConfig.primaryColor),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sync Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Queue count
              _buildStatusRow(
                'Pending Attempts',
                '${_queueStatus?.queuedCount ?? 0}',
                _queueStatus?.hasQueuedItems == true
                    ? Colors.orange
                    : Color(AppConfig.primaryColor),
              ),
              
              const SizedBox(height: 12),
              
              // Last sync time
              _buildStatusRow(
                'Last Sync',
                _queueStatus?.lastSyncTime != null
                    ? DateFormat('MMM dd, yyyy • HH:mm')
                        .format(_queueStatus!.lastSyncTime!)
                    : 'Never',
                Colors.grey.shade600,
              ),
              
              const SizedBox(height: 12),
              
              // Connection status
              _buildStatusRow(
                'Connection',
                _queueStatus?.hasConnection == true ? 'Online' : 'Offline',
                _queueStatus?.hasConnection == true
                    ? Color(AppConfig.primaryColor)
                    : Colors.red,
              ),
              
              const SizedBox(height: 20),
              
              // Sync button
              if (_queueStatus?.needsSync == true)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleSync,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(AppConfig.primaryColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
              else if (_queueStatus?.hasConnection == false)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attempts will sync automatically when online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(AppConfig.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(AppConfig.primaryColor),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'All attempts are synced!',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                    Icons.wifi,
                    color: Color(AppConfig.secondaryColor),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Offline Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Practice sessions are saved locally when offline and automatically synced when you reconnect to the internet.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSync() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncDialog(
        wordProvider: context.read<WordProvider>(),
      ),
    );

    // Reload status after sync
    await Future.delayed(const Duration(milliseconds: 500));
    _loadQueueStatus();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/admin_provider.dart';
import '../../domain/models/audit_log.dart';

class AuditLogList extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final bool showHeader;
  final bool enableSelection;
  final Function(List<AuditLog>)? onBulkAction;
  final VoidCallback? onRefresh;
  final bool compact;

  const AuditLogList({
    Key? key,
    required this.logs,
    this.showHeader = true,
    this.enableSelection = false,
    this.onBulkAction,
    this.onRefresh,
    this.compact = false,
  }) : super(key: key);

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Invalid date';
      }
      
      return DateFormat('MMM d, y h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'login':
        return Colors.purple;
      case 'grant_admin':
        return Colors.amber;
      case 'revoke_admin':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'login':
        return Icons.login;
      case 'grant_admin':
        return Icons.admin_panel_settings;
      case 'revoke_admin':
        return Icons.no_accounts;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No logs to display'),
            if (onRefresh != null)
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                onPressed: onRefresh,
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Activity Logs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              final String action = log['action'] ?? 'unknown';
              final String userId = log['userId'] ?? 'system';
              final String details = log['details'] ?? 'No details provided';
              final timestamp = log['timestamp'];
              final String resourceType = log['resourceType'] ?? '';
              final String resourceId = log['resourceId'] ?? '';
              
              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0, 
                  vertical: compact ? 4.0 : 8.0,
                ),
                leading: CircleAvatar(
                  backgroundColor: _getActionColor(action).withOpacity(0.2),
                  child: Icon(
                    _getActionIcon(action),
                    color: _getActionColor(action),
                    size: compact ? 18 : 24,
                  ),
                ),
                title: Text(
                  compact 
                    ? '$action ${resourceType.isNotEmpty ? "- $resourceType" : ""}'
                    : action.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 14 : 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!compact) 
                      Text('By: $userId'),
                    Text(
                      details, 
                      maxLines: compact ? 1 : 2, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: compact ? 12 : 14),
                    ),
                  ],
                ),
                trailing: Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(fontSize: compact ? 10 : 12),
                ),
                isThreeLine: !compact,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('${action.toUpperCase()} Log Details'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Time: ${_formatTimestamp(timestamp)}'),
                            const SizedBox(height: 8),
                            Text('By: $userId'),
                            if (resourceType.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Resource Type: $resourceType'),
                            ],
                            if (resourceId.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Resource ID: $resourceId'),
                            ],
                            const SizedBox(height: 8),
                            Text('Details: $details'),
                            const SizedBox(height: 8),
                            ...log.entries
                                .where((e) => !['action', 'userId', 'details', 'timestamp', 'resourceType', 'resourceId'].contains(e.key))
                                .map((e) => Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text('${e.key}: ${e.value}'),
                                    )),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

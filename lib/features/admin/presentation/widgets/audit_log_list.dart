import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../models/audit_log.dart';

class AuditLogList extends StatelessWidget {
  final List<AuditLog> logs;
  final bool showHeader;
  final bool enableSelection;
  final Function(List<AuditLog>)? onBulkAction;
  final VoidCallback? onRefresh; // Add this parameter
  
  const AuditLogList({
    Key? key,
    required this.logs,
    this.showHeader = true,
    this.enableSelection = false,
    this.onBulkAction,
    this.onRefresh, // Add onRefresh parameter with default value
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No logs to display'),
            if (onRefresh != null) // Optional refresh button
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                onPressed: onRefresh,
              ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) {
          onRefresh!();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            _buildHeader(context),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogItem(context, log);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Activity Logs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final adminProvider = Provider.of<AdminProvider>(context, listen: false);
              adminProvider.loadActivityLogs();
            },
            tooltip: 'Refresh logs',
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogItem(BuildContext context, AuditLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        leading: _getLogIcon(log.action),
        title: Text(log.readableAction),
        subtitle: Text(
          '${log.formattedTimestamp} • ${_truncateUserId(log.userId)}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('User ID', log.userId),
                _buildDetailRow('IP Address', log.ipAddress),
                _buildDetailRow('Device', _getDeviceInfo(log.deviceInfo)),
                _buildDetailRow('Platform', log.deviceInfo['platform'] ?? 'Unknown'),
                _buildDetailRow('Action', log.action),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _getLogIcon(String action) {
    IconData iconData;
    Color iconColor;
    
    switch (action) {
      case 'login':
        iconData = Icons.login;
        iconColor = Colors.blue;
        break;
      case '2fa_verification':
        iconData = Icons.security;
        iconColor = Colors.green;
        break;
      case 'property_create':
        iconData = Icons.add_home;
        iconColor = Colors.purple;
        break;
      case 'property_update':
        iconData = Icons.edit;
        iconColor = Colors.orange;
        break;
      case 'property_delete':
        iconData = Icons.delete;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.info;
        iconColor = Colors.grey;
    }
    
    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }
  
  String _getDeviceInfo(Map<String, dynamic> deviceInfo) {
    if (deviceInfo['model'] != null) {
      return deviceInfo['model'];
    }
    return 'Unknown device';
  }
  
  String _truncateUserId(String userId) {
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 4)}...${userId.substring(userId.length - 4)}';
  }
}

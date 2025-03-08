import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/admin_user.dart';

class UserDataTable extends StatefulWidget {
  final List<AdminUser> users;
  final Function(AdminUser user, bool isAdmin) onRoleChanged;
  
  const UserDataTable({
    Key? key,
    required this.users,
    required this.onRoleChanged,
  }) : super(key: key);

  @override
  State<UserDataTable> createState() => _UserDataTableState();
}

class _UserDataTableState extends State<UserDataTable> {
  List<bool> _selected = [];
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  List<AdminUser> _sortedUsers = [];
  
  @override
  void initState() {
    super.initState();
    _selected = List.generate(widget.users.length, (index) => false);
    _sortedUsers = List.from(widget.users);
    _sortUsers();
  }
  
  @override
  void didUpdateWidget(UserDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users.length != widget.users.length) {
      _selected = List.generate(widget.users.length, (index) => false);
      _sortedUsers = List.from(widget.users);
      _sortUsers();
    }
  }
  
  bool get _hasSelection => _selected.contains(true);
  
  void _toggleAll(bool? value) {
    if (value == null) return;
    setState(() {
      _selected = List.generate(widget.users.length, (index) => value);
    });
  }
  
  void _sortUsers() {
    _sortedUsers.sort((a, b) {
      switch (_sortColumnIndex) {
        case 0: // Name
          return _sortAscending
              ? a.displayName.compareTo(b.displayName)
              : b.displayName.compareTo(a.displayName);
        case 1: // Email
          return _sortAscending
              ? a.email.compareTo(b.email)
              : b.email.compareTo(a.email);
        case 2: // Last Active
          if (a.lastActive == null) return _sortAscending ? 1 : -1;
          if (b.lastActive == null) return _sortAscending ? -1 : 1;
          return _sortAscending
              ? a.lastActive!.compareTo(b.lastActive!)
              : b.lastActive!.compareTo(a.lastActive!);
        case 3: // Admin
          return _sortAscending
              ? (a.isAdmin ? 1 : 0).compareTo(b.isAdmin ? 1 : 0)
              : (b.isAdmin ? 1 : 0).compareTo(a.isAdmin ? 1 : 0);
        default:
          return 0;
      }
    });
  }

  void _sort<T>(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortUsers();
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    try {
      final dateTime = timestamp.toDate();
      return DateFormat('MMM d, y h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasSelection)
          _buildSelectionActions()
        else
          _buildTableHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: Card(
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  columnSpacing: 24,
                  dataRowMinHeight: 60,
                  columns: _buildColumns(),
                  rows: _buildRows(),
                  showCheckboxColumn: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTableHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Users (${widget.users.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            Provider.of<AdminProvider>(context, listen: false).loadUsers();
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }
  
  Widget _buildSelectionActions() {
    final selectedCount = _selected.where((s) => s).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightColorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              final selectedUsers = _getSelectedUsers();
              _showRoleBulkUpdateDialog(selectedUsers);
            },
            child: const Text('Change Role'),
          ),
          TextButton(
            onPressed: () {
              final selectedUsers = _getSelectedUsers();
              _showExportDialog(selectedUsers);
            },
            child: const Text('Export'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selected = List.generate(widget.users.length, (index) => false);
              });
            },
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }
  
  List<DataColumn> _buildColumns() {
    return [
      DataColumn(
        label: Checkbox(
          value: _selected.every((element) => element),
          tristate: _selected.contains(true) && _selected.contains(false),
          onChanged: _toggleAll,
        ),
      ),
      DataColumn(
        label: const Text('Name'),
        onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Email'),
        onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Last Active'),
        onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
      ),
      DataColumn(
        label: const Text('Admin'),
        onSort: (columnIndex, ascending) => _sort(columnIndex, ascending),
      ),
      const DataColumn(label: Text('Status')),
      const DataColumn(label: Text('Join Date')),
      const DataColumn(label: Text('Actions')),
    ];
  }
  
  List<DataRow> _buildRows() {
    return List.generate(
      _sortedUsers.length,
      (index) {
        final user = _sortedUsers[index];
        
        return DataRow(
          selected: _selected[index],
          onSelectChanged: (selected) {
            if (selected != null) {
              setState(() {
                _selected[index] = selected;
              });
            }
          },
          cells: [
            DataCell(
              Checkbox(
                value: _selected[index],
                onChanged: (selected) {
                  if (selected != null) {
                    setState(() {
                      _selected[index] = selected;
                    });
                  }
                },
              ),
            ),
            DataCell(
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?')
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : 'No Name',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(Text(user.email)),
            DataCell(Text(_formatTimestamp(user.lastActive))),
            DataCell(
              user.isAdmin
                  ? const Chip(
                      label: Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                    )
                  : const Text('User'),
            ),
            DataCell(_buildStatusBadge(user.status)),
            DataCell(Text(user.joinDate)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      _showUserDetailsDialog(user);
                    },
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(
                      user.status == 'active' ? Icons.block : Icons.check_circle,
                      size: 18,
                      color: user.status == 'active' ? Colors.red : Colors.green,
                    ),
                    onPressed: () {
                      _toggleUserStatus(user);
                    },
                    tooltip: user.status == 'active' ? 'Disable' : 'Enable',
                  ),
                  Switch(
                    value: user.isAdmin,
                    onChanged: (value) {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(value ? 'Grant Admin Access' : 'Revoke Admin Access'),
                          content: Text(
                            value
                                ? 'Are you sure you want to grant admin access to ${user.displayName}?'
                                : 'Are you sure you want to revoke admin access from ${user.displayName}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onRoleChanged(user, value);
                              },
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'disabled':
        color = Colors.red;
        label = 'Disabled';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
  
  List<AdminUser> _getSelectedUsers() {
    final List<AdminUser> selectedUsers = [];
    
    for (int i = 0; i < widget.users.length; i++) {
      if (_selected[i]) {
        selectedUsers.add(widget.users[i]);
      }
    }
    
    return selectedUsers;
  }
  
  void _showUserDetailsDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User: ${user.displayName ?? user.email}'),
        content: const Text('User editing functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _toggleUserStatus(AdminUser user) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final newStatus = user.status == 'active' ? 'disabled' : 'active';
    
    adminProvider.updateUserStatus(user.uid, newStatus);
  }
  
  void _showRoleBulkUpdateDialog(List<AdminUser> users) {
    bool makeAdmin = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update User Roles'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selected users: ${users.length}'),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Make Users Admins'),
                  subtitle: const Text('Grant admin privileges'),
                  value: makeAdmin,
                  onChanged: (value) {
                    setState(() {
                      makeAdmin = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                  adminProvider.bulkUpdateUserRoles(users, makeAdmin);
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showExportDialog(List<AdminUser> users) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ready to export ${users.length} users'),
            const SizedBox(height: 16),
            const Text('Format:'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.description),
                  label: const Text('CSV'),
                  onPressed: () {
                    Provider.of<AdminProvider>(context, listen: false)
                        .exportUsersToCSV(users);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.code),
                  label: const Text('JSON'),
                  onPressed: () {
                    Provider.of<AdminProvider>(context, listen: false)
                        .exportUsersToJSON(users);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

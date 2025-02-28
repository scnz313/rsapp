import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_data_table.dart';
import '../widgets/audit_log_list.dart';
import '../../models/admin_user.dart'; // Add this import
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<AdminUser> _filteredUsers = []; // Now AdminUser is properly imported
  final List<String> _selectedPropertyIds = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await Future.wait([
        adminProvider.loadDashboardStats(),
        adminProvider.loadUsers(),
        adminProvider.loadActivityLogs(),
        adminProvider.loadFlaggedProperties(),
      ]);
      
      _updateFilteredUsers();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _updateFilteredUsers() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      _filteredUsers = List.from(adminProvider.users);
    } else {
      _filteredUsers = adminProvider.users.where((user) {
        return user.email.toLowerCase().contains(query) || 
               (user.displayName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    setState(() {});
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: AppColors.lightColorScheme.primary,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Analytics'),
                Tab(text: 'Users'),
                Tab(text: 'Content Moderation'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnalyticsTab(provider),
                    _buildUsersTab(provider),
                    _buildContentModerationTab(provider),
                  ],
                ),
        );
      },
    );
  }
  
  Widget _buildAnalyticsTab(AdminProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Analytics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          // Summary cards row
          Row(
            children: [
              _buildSummaryCard(
                'Properties',
                provider.stats.totalProperties.toString(),
                Icons.home,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Active Users',
                provider.stats.activeUsers.toString(),
                Icons.people,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Pending Reviews',
                provider.stats.pendingReviews.toString(),
                Icons.rate_review,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Charts - Line Chart for Property Views & Leads
          _buildChartCard(
            title: 'Property Views & Leads (Last 30 Days)',
            child: SizedBox(
              height: 300,
              child: _buildLineChart(provider),
            ),
          ),
          const SizedBox(height: 32),
          
          // Charts - Bar Chart for User Growth
          _buildChartCard(
            title: 'New User Registrations (Monthly)',
            child: SizedBox(
              height: 300,
              child: _buildBarChart(provider),
            ),
          ),
          const SizedBox(height: 32),
          
          // Charts - Pie Chart for Revenue
          _buildChartCard(
            title: 'Revenue Breakdown',
            child: SizedBox(
              height: 300,
              child: _buildPieChart(provider),
            ),
          ),
          const SizedBox(height: 24),
          
          // Recent activity section
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: AuditLogList(
              logs: provider.activityLogs,
              showHeader: false,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    icon,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildChartCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    _showChartInfoDialog(title, 'Information about this chart');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
  
  Widget _buildLineChart(AdminProvider provider) {
    // Line chart implementation would go here using fl_chart
    return const Center(child: Text('Line Chart Placeholder'));
  }
  
  Widget _buildBarChart(AdminProvider provider) {
    // Bar chart implementation would go here using fl_chart
    return const Center(child: Text('Bar Chart Placeholder'));
  }
  
  Widget _buildPieChart(AdminProvider provider) {
    // Pie chart implementation would go here using fl_chart
    return const Center(child: Text('Pie Chart Placeholder'));
  }
  
  Widget _buildUsersTab(AdminProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          AppTextField(
            controller: _searchController,
            hintText: 'Search users by name or email',
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) {
              _updateFilteredUsers();
            },
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _updateFilteredUsers();
                    },
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // User table
          Expanded(
            child: UserDataTable(
              users: _filteredUsers,
              onRoleChanged: (user, isAdmin) {
                provider.toggleUserRole(user, isAdmin);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentModerationTab(AdminProvider provider) {
    final flaggedProperties = provider.flaggedProperties;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModerationHeader(flaggedProperties.length),
          const SizedBox(height: 16),
          
          Expanded(
            child: flaggedProperties.isEmpty
                ? const Center(child: Text('No flagged content to review'))
                : ListView.builder(
                    itemCount: flaggedProperties.length,
                    itemBuilder: (context, index) {
                      final property = flaggedProperties[index];
                      final isSelected = _selectedPropertyIds.contains(property['id']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelected ? Colors.green : null,
                          ),
                          title: Text(property['title']),
                          subtitle: Text('Flagged by: ${property['flaggedBy']}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Reason: ${property['flagReason']}'),
                                  const SizedBox(height: 8),
                                  Text('Description: ${property['description']}'),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedPropertyIds.remove(property['id']);
                                            } else {
                                              _selectedPropertyIds.add(property['id']);
                                            }
                                          });
                                        },
                                        child: Text(isSelected ? 'Deselect' : 'Select'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Handle content moderation action
                                        },
                                        child: const Text('Take Action'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModerationHeader(int flaggedCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Flagged Content ($flaggedCount)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        ElevatedButton(
          onPressed: _selectedPropertyIds.isEmpty
              ? null
              : () {
                  // Handle bulk action on selected properties
                },
          child: const Text('Bulk Action'),
        ),
      ],
    );
  }
  
  void _showChartInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

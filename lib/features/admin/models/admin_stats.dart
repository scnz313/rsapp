import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStats {
  final int totalProperties;
  final int activeUsers;
  final int pendingReviews;
  final double totalRevenue;
  final DateTime lastUpdated;
  final Map<String, int> propertiesViewsByDay;
  final Map<String, int> leadsGeneratedByDay;
  final Map<String, int> userGrowthByMonth;
  final Map<String, double> revenueByCategory;

  AdminStats({
    this.totalProperties = 0,
    this.activeUsers = 0,
    this.pendingReviews = 0,
    this.totalRevenue = 0.0,
    DateTime? lastUpdated,
    required this.propertiesViewsByDay,
    required this.leadsGeneratedByDay,
    required this.userGrowthByMonth,
    required this.revenueByCategory,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalProperties: json['totalProperties'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      pendingReviews: json['pendingReviews'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      lastUpdated: (json['lastUpdated'] as Timestamp?)?.toDate(),
      propertiesViewsByDay: Map<String, int>.from(json['propertiesViewsByDay'] ?? {}),
      leadsGeneratedByDay: Map<String, int>.from(json['leadsGeneratedByDay'] ?? {}),
      userGrowthByMonth: Map<String, int>.from(json['userGrowthByMonth'] ?? {}),
      revenueByCategory: Map<String, double>.from(json['revenueByCategory'] ?? {}),
    );
  }

  factory AdminStats.empty() {
    return AdminStats(
      totalProperties: 0,
      activeUsers: 0,
      pendingReviews: 0,
      totalRevenue: 0.0,
      propertiesViewsByDay: {},
      leadsGeneratedByDay: {},
      userGrowthByMonth: {},
      revenueByCategory: {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalProperties': totalProperties,
      'activeUsers': activeUsers,
      'pendingReviews': pendingReviews,
      'totalRevenue': totalRevenue,
      'lastUpdated': lastUpdated,
      'propertiesViewsByDay': propertiesViewsByDay,
      'leadsGeneratedByDay': leadsGeneratedByDay,
      'userGrowthByMonth': userGrowthByMonth,
      'revenueByCategory': revenueByCategory,
    };
  }

  // Generate mock data for development
  static AdminStats generateMockData() {
    // Create date-based views/leads data for line chart (last 30 days)
    final Map<String, int> mockViews = {};
    final Map<String, int> mockLeads = {};
    final DateTime now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Generate semi-random view counts (100-500)
      mockViews[dateString] = 100 + (date.day * 7) % 400;

      // Generate lead counts as ~10% of views
      mockLeads[dateString] = (mockViews[dateString]! * 0.1).round();
    }

    // Create monthly user growth data for bar chart (last 12 months)
    final Map<String, int> mockUserGrowth = {};

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i);
      final monthString = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      // Generate semi-random user growth (20-100 new users per month)
      mockUserGrowth[monthString] = 20 + (date.month * 5) % 80;
    }

    // Create revenue by category data for pie chart
    final Map<String, double> mockRevenue = {
      'Premium Listings': 5750.0,
      'Featured Properties': 3200.0,
      'Subscription Fees': 8500.0,
    };

    return AdminStats(
      totalProperties: 0,
      activeUsers: 0,
      pendingReviews: 0,
      totalRevenue: 0.0,
      propertiesViewsByDay: mockViews,
      leadsGeneratedByDay: mockLeads,
      userGrowthByMonth: mockUserGrowth,
      revenueByCategory: mockRevenue,
    );
  }
}

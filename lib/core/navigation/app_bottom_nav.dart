import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/domain/services/admin_service.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _barHeightAnimation;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Define animation for the nav bar height
    _barHeightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start the animation when the widget is built
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Check if the user is admin
  void _checkAdminStatus(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final isAdmin = AdminService.isUserAdmin(authProvider.user);
      if (isAdmin != _isAdmin) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check admin status on each build to ensure it's current
    _checkAdminStatus(context);
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Get admin status from auth provider
        final isAdmin = authProvider.user != null ? 
            AdminService.isUserAdmin(authProvider.user) : false;
        
        // Define navigation items based on admin status
        final List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Post',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_outlined),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
        
        // Animated builder for the nav bar
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              // Slide up animation
              offset: Offset(0, 56 * (1 - _barHeightAnimation.value)),
              child: BottomNavigationBar(
                items: navItems,
                currentIndex: _getAdjustedIndex(widget.currentIndex, isAdmin),
                onTap: (index) => widget.onTap(_convertIndexForNavigation(index, isAdmin)),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                elevation: 8,
              ),
            );
          },
        );
      },
    );
  }
  
  // Helper to adjust the index based on admin status
  int _getAdjustedIndex(int index, bool isAdmin) {
    // For display purposes - converts the app index to navbar index
    if (!isAdmin && index >= 2) {
      return index - 1;
    }
    return index;
  }
  
  // New helper to convert tapped index to navigation index
  int _convertIndexForNavigation(int tappedIndex, bool isAdmin) {
    // For navigation purposes - converts the navbar index to app index
    if (!isAdmin && tappedIndex >= 2) {
      return tappedIndex + 1;
    }
    return tappedIndex;
  }
}

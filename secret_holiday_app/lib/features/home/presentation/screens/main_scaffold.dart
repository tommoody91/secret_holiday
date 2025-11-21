import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secret_holiday_app/core/theme/app_colors.dart';
import 'package:secret_holiday_app/features/home/presentation/widgets/app_drawer.dart';
import 'package:secret_holiday_app/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:secret_holiday_app/features/map/presentation/screens/map_screen.dart';
import 'package:secret_holiday_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:secret_holiday_app/features/planning/presentation/screens/planning_screen.dart';
import 'package:secret_holiday_app/features/profile/presentation/screens/profile_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TimelineScreen(),
    MapScreen(),
    ChatScreen(),
    PlanningScreen(),
    ProfileScreen(),
  ];

  final List<_NavigationItem> _navItems = const [
    _NavigationItem(
      icon: Icons.timeline,
      activeIcon: Icons.timeline,
      label: 'Timeline',
    ),
    _NavigationItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
      label: 'Map',
    ),
    _NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    _NavigationItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'Planning',
    ),
    _NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_currentIndex].label),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              _showSettingsComingSoon(context);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          items: _navItems.map((item) {
            final index = _navItems.indexOf(item);
            final isSelected = _currentIndex == index;
            
            return BottomNavigationBarItem(
              icon: Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 24,
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSettingsComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Settings'),
          ],
        ),
        content: const Text(
          'App and group settings will be available soon. You can manage basic preferences and group details here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

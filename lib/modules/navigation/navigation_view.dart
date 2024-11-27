import 'package:flutter/material.dart';
import 'package:gamers_gram/modules/arena/view/arena_view.dart';
import 'package:gamers_gram/modules/chat/view/chat_view.dart';
import 'package:gamers_gram/modules/home/view/home_view.dart';
import 'package:gamers_gram/modules/marketplace/view/marketplace_view.dart';
import 'package:gamers_gram/modules/profile/view/profile_view.dart';
import 'package:gamers_gram/modules/tournamnets_page/view/tournament_view.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const HomePage(),
    const TournamentView(),
    const ArenaView(),
    const MarketView(),
    const ChatScreen(),
    const ProfileView(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
        children: _pages, // Disable swiping
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          height: 65,
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
              _pageController.jumpToPage(index);
            });
          },
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Colors.blue),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_esports_outlined),
              selectedIcon: Icon(Icons.sports_esports, color: Colors.blue),
              label: 'TOUR',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_esports_outlined),
              selectedIcon: Icon(Icons.sports_esports, color: Colors.blue),
              label: 'Arena',
            ),
            NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store, color: Colors.blue),
              label: 'Market',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat, color: Colors.blue),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Colors.blue),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// You can keep the same page implementations as before
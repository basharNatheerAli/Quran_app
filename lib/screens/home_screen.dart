import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'quran_screen.dart';
import 'azkar_categories_screen.dart';
import 'hadith_screen.dart';
import 'tasbeeh_screen.dart';
// import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const QuranScreen(),
    const AzkarCategoriesScreen(),
    const HadithScreen(),
    const TasbeehScreen(),
  ];

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
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'القرآن',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism),
            label: 'الأذكار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'الأحاديث',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'المسبحة',
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 1, end: 0, duration: 500.ms),
    );
  }
}

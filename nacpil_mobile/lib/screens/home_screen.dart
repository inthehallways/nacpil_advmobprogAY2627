import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'product_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  String _profileTitle = 'Profile';

  @override
  void initState() {
    super.initState();
    _loadProfileTitle();
  }

  Future<void> _loadProfileTitle() async {
    final userData = await UserService().getUserData();
    final firstName = (userData['firstName'] as String? ?? '').trim();
    final username = (userData['username'] as String? ?? '').trim();

    if (!mounted) return;

    setState(() {
      _profileTitle = firstName.isNotEmpty
          ? firstName
          : username.isNotEmpty
              ? username
              : 'Profile';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: (_selectedIndex == 0)
            ? Image.asset('assets/images/nubdexchange_logo.png', scale: 11.sp)
            : CustomText(
                text: (_selectedIndex == 1) ? 'Cart' : _profileTitle,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: const <Widget>[
            ProductScreen(),
            CartScreen(),
            ProfileScreen(),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false, //selected item
          showUnselectedLabels: false, //unselected item
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            // enhancement 1: cart screen is added as a main navigation page.
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
        // enhancement 2: chat is moved from bottom navigation to a floating action button.
        floatingActionButton: (_selectedIndex == 1)
            ? null
            : FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const _ChatScreen(),
                    ),
                  );
                },
                tooltip: 'Chat',
                child: Icon(Icons.chat, size: 24.sp),
              ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}

class _ChatScreen extends StatelessWidget {
  const _ChatScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Chat',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Center(
        child: CustomText(
          text: 'Chat',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

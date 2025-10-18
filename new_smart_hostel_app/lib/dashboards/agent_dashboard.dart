import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_smart_hostel_app/screens/welcome_screen.dart';

class AgentDashboard extends StatefulWidget {
  final String? initialToken; // optional token from previous session
  final String role; // required

  const AgentDashboard({super.key, this.initialToken, this.role = "agent"});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late String _token;

  final List<Widget> _pages = const [
    Center(child: Text("Orders Page", style: TextStyle(fontSize: 22))),
    Center(child: Text("Performance Page", style: TextStyle(fontSize: 22))),
    Center(child: Text("Profile Page", style: TextStyle(fontSize: 22))),
  ];

  final List<double> _iconScaleFactors = [0.09, 0.085, 0.085];

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _token = widget.initialToken ?? "";
    if (_token.isEmpty) {
      _loadToken(); // Load token from SharedPreferences if not provided
    }
  }

  /// Load token from SharedPreferences with 30-day session check
  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final isLoggedOut = prefs.getBool('isLoggedOut') ?? false;
    final logoutTime = prefs.getInt('logoutTime');
    final now = DateTime.now().millisecondsSinceEpoch;

    if (isLoggedOut && logoutTime != null) {
      final thirtyDaysMillis = 30 * 24 * 60 * 60 * 1000;
      if (now - logoutTime <= thirtyDaysMillis) {
        _token = prefs.getString('token') ?? "";
        if (_token.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showContinueDialog();
          });
        }
        return;
      }
    }

    setState(() {
      _token = prefs.getString('token') ?? "";
    });
  }

  /// Prompt to continue previous session
  Future<void> _showContinueDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? "";
    final name = prefs.getString('name') ?? "";

    final continuePrev = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Continue Previous Session?"),
        content: Text("Logged in as $name ($role). Continue?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text("Yes"),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (continuePrev == true) {
      setState(() {
        _token = prefs.getString('token') ?? "";
      });
    } else {
      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('name');
      setState(() {
        _token = "";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildNavIcon(String assetPath, int index) {
    bool isActive = _selectedIndex == index;
    double screenWidth = MediaQuery.of(context).size.width;
    double iconSize = _iconScaleFactors.length > index
        ? screenWidth * _iconScaleFactors[index]
        : screenWidth * 0.07;

    return AnimatedScale(
      scale: isActive ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Center(
        child: SizedBox(
          height: iconSize,
          width: iconSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SvgPicture.asset(
              assetPath,
              colorFilter: ColorFilter.mode(
                isActive ? Colors.amber : Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Logout with 30-day session preservation
  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');
      final role = prefs.getString('role');
      final name = prefs.getString('name');

      if (token != null && role != null && name != null) {
        await prefs.setBool('isLoggedOut', true);
        await prefs.setInt('logoutTime', DateTime.now().millisecondsSinceEpoch);
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_token.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Dashboard"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: GNav(
          backgroundColor: Colors.black,
          color: Colors.white,
          activeColor: Colors.white,
          tabBackgroundColor: Colors.grey.shade900,
          gap: 12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          tabs: [
            GButton(
              icon: Icons.circle,
              leading: _buildNavIcon("assets/svgs/orders.svg", 0),
              text: "Orders",
            ),
            GButton(
              icon: Icons.circle,
              leading: _buildNavIcon("assets/svgs/performance.svg", 1),
              text: "Performance",
            ),
            GButton(
              icon: Icons.circle,
              leading: _buildNavIcon("assets/svgs/profile.svg", 2),
              text: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

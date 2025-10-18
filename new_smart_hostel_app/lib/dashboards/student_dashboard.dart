import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:new_smart_hostel_app/widgets/delivery_page.dart';
import 'package:new_smart_hostel_app/widgets/expense_stats_page.dart';
import 'package:new_smart_hostel_app/widgets/requests_page.dart';
import 'package:new_smart_hostel_app/screens/welcome_screen.dart';
import 'package:new_smart_hostel_app/models/delivery_models.dart';
import 'package:new_smart_hostel_app/animations/fade_slide_transition.dart';

class StudentDashboard extends StatefulWidget {
  final String? initialToken;
  final String role;
  final String? studentName;

  const StudentDashboard({
    super.key,
    this.initialToken,
    this.role = "student",
    this.studentName,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  String _token = "";
  String _studentName = "Student";

  late AnimationController _controller;
  List<DeliveryRequest> _deliveries = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _initializeTokenAndName();
  }

  Future<void> _initializeTokenAndName() async {
    final prefs = await SharedPreferences.getInstance();

    final token = widget.initialToken?.isNotEmpty == true
        ? widget.initialToken!
        : (prefs.getString('token') ?? "");

    final storedName = prefs.getString('studentName');
    final name = (storedName != null && storedName.trim().isNotEmpty)
        ? storedName
        : (widget.studentName ?? "Student");

    await prefs.setString('studentName', name);

    setState(() {
      _token = token;
      _studentName = name;
    });

    if (_token.isEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        title: const Text(
          "Logout",
          style: TextStyle(color: Color(0xFFBFDBFE), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF93C5FD))),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text("Logout", style: TextStyle(color: Color(0xFFFCA5A5))),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedOut', true);
      await prefs.remove('token');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (_) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildNavIcon(String assetPath, bool isActive) {
    return AnimatedScale(
      scale: isActive ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: SvgPicture.asset(
        assetPath,
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFFFFC107) : Colors.white70,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DeliveryPage(
        token: _token, // only token is required now
      ),
      const ExpenseStatsPage(),
      const RequestsPage(),
      const Center(
        child: Text("Profile Page", style: TextStyle(fontSize: 22, color: Colors.white70)),
      ),
    ];
    final navItems = [
      {"label": "Delivery", "icon": "assets/svgs/delivery.svg"},
      {"label": "Expenses", "icon": "assets/svgs/expense.svg"},
      {"label": "Requests", "icon": "assets/svgs/request.svg"},
      {"label": "Profile", "icon": "assets/svgs/profile.svg"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          "Hello, $_studentName !",
          style: const TextStyle(
            color: Color(0xFF93C5FD),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: FadeSlideTransition(
        direction: _selectedIndex >= _previousIndex
            ? AxisDirection.right
            : AxisDirection.left,
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF000000),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFFBAE6FD),
            unselectedItemColor: Colors.white60,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _previousIndex = _selectedIndex;
                _selectedIndex = index;
              });
            },
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: navItems
                .asMap()
                .entries
                .map(
                  (entry) => BottomNavigationBarItem(
                icon: _buildNavIcon(entry.value["icon"]!, _selectedIndex == entry.key),
                label: entry.value["label"],
              ),
            )
                .toList(),
          ),
        ),
      ),
    );
  }
}

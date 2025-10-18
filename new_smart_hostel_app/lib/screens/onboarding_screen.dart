import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:new_smart_hostel_app/screens/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "lottie": "assets/animations/delivery.json",
      "title": "Track Your Deliveries",
      "subtitle": "From gate to room, your parcels are never out of sight.",
    },
    {
      "lottie": "assets/animations/expense.json",
      "title": "Smart Expense Tracking",
      "subtitle": "Track every chai, charger, and midnight snack—without losing your budget.",
    },
    {
      "lottie": "assets/animations/secure.json",
      "title": "Safe & Reliable",
      "subtitle": "Security that’s faster than your hostel Wi-Fi.",
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("seenOnboarding", true);
    await prefs.reload(); // Ensures value is written immediately
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  void _skip() => _completeOnboarding();

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  final isActive = _currentPage == index;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSlide(
                          offset: isActive ? Offset.zero : const Offset(0, 0.2),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          child: AnimatedOpacity(
                            opacity: isActive ? 1 : 0,
                            duration: const Duration(milliseconds: 500),
                            child: Lottie.asset(
                              data["lottie"]!,
                              height: height * 0.45,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.05),
                        AnimatedOpacity(
                          opacity: isActive ? 1 : 0,
                          duration: const Duration(milliseconds: 600),
                          child: Text(
                            data["title"]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: width * 0.07,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.02),
                        AnimatedOpacity(
                          opacity: isActive ? 1 : 0,
                          duration: const Duration(milliseconds: 700),
                          child: Text(
                            data["subtitle"]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: width * 0.045,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.06,
                vertical: height * 0.02,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip / Explore Later (fade out on last page)
                  AnimatedOpacity(
                    opacity: _currentPage == onboardingData.length - 1 ? 0 : 1,
                    duration: const Duration(milliseconds: 400),
                    child: IgnorePointer(
                      ignoring: _currentPage == onboardingData.length - 1,
                      child: TextButton(
                        onPressed: _skip,
                        child: Text(
                          "Explore Later",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: width * 0.04,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bouncing Dots indicator
                  Row(
                    children: List.generate(
                      onboardingData.length,
                          (index) {
                        bool isActive = index == _currentPage;
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 1.0,
                            end: isActive ? 1.2 : 1.0,
                          ),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) {
                            return Container(
                              margin:
                              EdgeInsets.symmetric(horizontal: width * 0.01),
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  height: height * 0.012,
                                  width: isActive ? width * 0.045 : width * 0.02,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.amber
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Next / Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.all(width * 0.04),
                    ),
                    child: Icon(
                      _currentPage == onboardingData.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                      color: Colors.black,
                      size: width * 0.06,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

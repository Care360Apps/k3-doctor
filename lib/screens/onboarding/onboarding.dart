import 'package:flutter/material.dart';

import '../../constant/color_constant.dart';
import '../../constant/prefConstatnt.dart';
import '../../constant/preferences.dart';
import '../auth/SignIn.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      imagePath: 'assets/images/onboarding1.png',
      title: 'Connect With Patients Online',
      subtitle: 'Chat with patients and manage your appointments in one place.',
    ),
    _OnboardingPageData(
      imagePath: 'assets/images/onboarding2.png',
      title: 'Earn Money with Your Expertise',
      subtitle: 'Set your own schedule and earn money by providing consultations and treatments.',
    ),
    _OnboardingPageData(
      imagePath: 'assets/images/onboarding3.png',
      title: 'Manage Your Schedule Effortlessly',
      subtitle: 'Book appointments and manage visits in a single platform.',
    ),
  ];

  void _finishOnboarding(BuildContext context) async {
    await SharedPreferenceHelper.setBoolean(Preferences.onboarding_seen, true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SignIn()),
    );
  }

  void _nextOrFinish(BuildContext context) {
    if (_currentIndex == _pages.length - 1) {
      _finishOnboarding(context);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _finishOnboarding(context),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    children: [
                      SizedBox(
                        height: size.height * 0.45,
                        child: Center(
                          child: Image.asset(
                            page.imagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
                        child: _buildBottomCard(context, page),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard(BuildContext context, _OnboardingPageData page) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildPageIndicators(),
              const Spacer(),
              SizedBox(
                width: 56,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _nextOrFinish(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: loginButton,
                    elevation: 0,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      children: List.generate(
        _pages.length,
        (index) {
          final isActive = index == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 6),
            height: 6,
            width: isActive ? 24 : 8,
            decoration: BoxDecoration(
              color: isActive ? loginButton : loginButton.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingPageData {
  final String imagePath;
  final String title;
  final String subtitle;

  const _OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}


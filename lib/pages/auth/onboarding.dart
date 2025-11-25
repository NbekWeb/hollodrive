import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../colors.dart';
import 'register_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/onboarding-1.png',
      title: 'Welcome to Hollodrive',
      description: 'Get ready for a smarter, safer, and more flexible way to move around the city.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding-2.png',
      title: 'Personalize Your Ride',
      description: 'Adjust preferences like temperature, chat level, and even request a woman driver — it’s all up to you.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding-3.png',
      title: 'Manage the price',
      description: 'Offer the price you’re comfortable with — drivers choose if they accept. Total control over your ride budget.',
    ),
    OnboardingData(
      image: 'assets/images/onboarding-4.png',
      title: 'Security Features',
      description: 'Built-in voice recording, ride sharing, driver ratings, and more — all designed to keep you safe.',
    ),
     OnboardingData(
      image: 'assets/images/onboarding-5.png',
      title: 'Book in Seconds',
      description: 'Request a ride, get matched instantly, and enjoy a seamless trip from start to finish.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to register page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterPage()),
      );
    }
  }

  void _skipOnboarding() {
    // Navigate to register page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getPrimaryColor(Theme.of(context).brightness), // #262626
      body: SafeArea(
        child: Column(
          children: [
            // Logo at top
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SvgPicture.asset(
                'assets/svg/logo.svg',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            // Pagination dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDot(index == _currentPage),
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: _currentPage == _pages.length - 1
                  ? SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkError, // #E52A00
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // Skip button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _skipOnboarding,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.getSurfaceColor(Theme.of(context).brightness), // #262626
                                side: BorderSide(color: AppColors.getSurfaceColor(Theme.of(context).brightness)),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Next button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkError, // #E52A00
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: Image.asset(
                  data.image,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: 250,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      'Image not found',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // const SizedBox(height: 20),
          // Title
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            data.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}


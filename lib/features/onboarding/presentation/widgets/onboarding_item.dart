import 'package:flutter/material.dart';

class OnboardingItemData {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingItemData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingItem extends StatelessWidget {
  final OnboardingItemData data;

  const OnboardingItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Placeholder (Icon for now, easy to swap for images)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.brown.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 100, color: Colors.brown.shade600),
          ),
          const SizedBox(height: 50),

          // Title
          Text(
            data.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade900,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            data.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.brown.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

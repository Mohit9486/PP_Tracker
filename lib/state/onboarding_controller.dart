import 'package:flutter/material.dart';
import 'package:pp_tracker/models/onboarding/onboarding_models.dart';

class OnboardingController extends ChangeNotifier {
  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  bool _shouldShowTour = true;
  bool get shouldShowTour => _shouldShowTour;

  final List<OnboardingStep> _steps = [
    const OnboardingStep(
      id: 'welcome',
      title: 'Welcome to Petal',
      description: 'Your companion for cycle tracking and holistic wellness. Understand your body\'s natural rhythms.',
      imageUrl: 'assets/phases/Follicular.png',
      buttonText: 'Get Started',
    ),
    const OnboardingStep(
      id: 'library',
      title: 'Verified Health Library',
      description: 'Access professionally written articles, verified by experts, to help you navigate every phase of your cycle.',
      imageUrl: 'assets/phases/Fertile.png',
      buttonText: 'Next',
    ),
    const OnboardingStep(
      id: 'insights',
      title: 'Actionable Insights',
      description: 'Get personalized recommendations based on your unique cycle data. Sync your life with your hormones.',
      imageUrl: 'assets/phases/Luteal.png',
      buttonText: 'Start Your Journey',
    ),
  ];

  List<OnboardingStep> get steps => _steps;

  void completeOnboarding({bool skipTour = false}) {
    _isCompleted = true;
    if (skipTour) _shouldShowTour = false;
    notifyListeners();
  }

  void dismissTour() {
    _shouldShowTour = false;
    notifyListeners();
  }
}

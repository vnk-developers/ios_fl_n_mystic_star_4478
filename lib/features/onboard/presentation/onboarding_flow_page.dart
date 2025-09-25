import 'package:flutter/material.dart';
import 'package:mystic_star_journey/features/onboard/presentation/screens/onboarding_screens.dart';

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});
  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final _ctrl = PageController();
  int _index = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _ctrl,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          OnboardingScreen1(controller: _ctrl),
          OnboardingScreen2(controller: _ctrl),
          OnboardingScreen3(controller: _ctrl),
          OnboardingScreen4(controller: _ctrl),
        ],
      ),
    );
  }
}

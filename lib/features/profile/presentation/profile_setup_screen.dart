import 'package:careconnect_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.person_add_alt_1_rounded,
            size: 54,
            color: AppColors.primary,
          ),
          const SizedBox(height: 22),
          Text(
            'One last step',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'Your Auth0 sign-in succeeded${email == null ? '' : ' for $email'}, but a CareConnect profile does not exist yet.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Profile creation is temporarily unavailable while the backend identity mapping is corrected.',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

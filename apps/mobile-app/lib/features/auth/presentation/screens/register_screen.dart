import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: MaliappLogo(size: 60)),
              const SizedBox(height: 60),

              const Text(
                'Create Your Business',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Join thousands of businesses managing with Mali Up',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Business Name
              const Text(
                'Business Name',
                style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'e.g. Neuraltale Tech',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // Phone Number
              const Text(
                'Mobile Number',
                style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '7xx xxx xxx',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🇹🇿', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 4),
                        Text('+255', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: () => context.go(AppRouter.dashboardPath),
                child: const Text('Create Account'),
              ),

              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

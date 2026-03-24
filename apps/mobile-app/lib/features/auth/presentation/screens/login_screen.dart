import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../config/routing.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Base
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  Color(0xFF1E1B4B), // Indigo 950
                  AppColors.background,
                ],
              ),
            ),
          ),
          
          // Background Accents
          Positioned(
            top: -100,
            right: -100,
            child: _BlurredCircle(
              size: 300, 
              color: AppColors.primary.withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _BlurredCircle(
              size: 250, 
              color: AppColors.secondary.withOpacity(0.04),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  const MaliappLogo(size: 80),
                  const SizedBox(height: 60),
                  
                  // Glassmorphic Login Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Sign in to manage your business',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            const TextField(
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            const TextField(
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: Icon(Icons.visibility_off_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: AppColors.primaryLight),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            ElevatedButton(
                              onPressed: () => context.go(AppRouter.dashboardPath),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Footer info
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'Empowering SMBs across Africa',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Built by Neuraltale Engineering',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurredCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurredCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

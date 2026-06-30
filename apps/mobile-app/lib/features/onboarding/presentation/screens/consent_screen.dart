import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Consent Screen - PDPA Compliance
/// Users must accept privacy policy before signup (PDPA requirement)
/// Allows granular consent for analytics and notifications

class ConsentScreen extends ConsumerStatefulWidget {
  final VoidCallback onConsentAccepted;

  const ConsentScreen({
    required this.onConsentAccepted,
    super.key,
  });

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen>
    with SingleTickerProviderStateMixin {
  bool privacyAccepted = false;
  bool analyticsOptIn = true;
  bool notificationsOptIn = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _proceedToSignup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy preferences saved')),
    );
    widget.onConsentAccepted();
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            _getPrivacyPolicyText(),
            style: GoogleFonts.dmSans(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topHeight = MediaQuery.of(context).size.height * 0.35;

    final headingStyle = GoogleFonts.dmSans(
      fontSize: 28,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.5,
    );
    final subtitleStyle = GoogleFonts.dmSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Header image
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topHeight,
            child: ClipRect(
              child: Image.asset(
                'assets/Picture/sign_up.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // Top navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content sheet
          DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.68,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (overscroll) {
                    overscroll.disallowIndicator();
                    return true;
                  },
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle bar
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Title
                            Center(
                              child: Text(
                                'Your Privacy & Permissions',
                                textAlign: TextAlign.center,
                                style: headingStyle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Mali Up respects your privacy. Please review our privacy policy and consent preferences.',
                                textAlign: TextAlign.center,
                                style: subtitleStyle,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Privacy Policy (required)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: privacyAccepted
                                      ? AppColors.success.withValues(alpha: 0.4)
                                      : AppColors.border,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                color: privacyAccepted
                                    ? AppColors.successBg
                                    : AppColors.surface,
                              ),
                              child: CheckboxListTile(
                                title: const Text(
                                  'I accept the Privacy Policy',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navyPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: GestureDetector(
                                  onTap: () => _showPrivacyPolicy(context),
                                  child: const Text(
                                    'Read full policy',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.navyPrimary,
                                      decoration: TextDecoration.underline,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                value: privacyAccepted,
                                onChanged: (val) =>
                                    setState(() => privacyAccepted = val!),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: AppColors.navyPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Analytics (optional)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(14),
                                color: AppColors.surface,
                              ),
                              child: CheckboxListTile(
                                title: const Text(
                                  'Help improve Mali Up',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navyPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Send usage analytics (non-financial)',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textMuted),
                                ),
                                value: analyticsOptIn,
                                onChanged: (val) =>
                                    setState(() => analyticsOptIn = val!),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: AppColors.navyPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Notifications (optional)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(14),
                                color: AppColors.surface,
                              ),
                              child: CheckboxListTile(
                                title: const Text(
                                  'Enable notifications',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navyPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Get updates about invoices, expenses, and important events',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textMuted),
                                ),
                                value: notificationsOptIn,
                                onChanged: (val) =>
                                    setState(() => notificationsOptIn = val!),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: AppColors.navyPrimary,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // CTA
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.navyPrimary,
                                  elevation: 4,
                                  shadowColor:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  disabledBackgroundColor:
                                      AppColors.disabled,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    privacyAccepted ? _proceedToSignup : null,
                                child: Text(
                                  'Continue to Signup',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Data rights info box
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.navyPrimary
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.navyPrimary
                                      .withValues(alpha: 0.12),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.shield_outlined,
                                          size: 16,
                                          color: AppColors.navyPrimary),
                                      SizedBox(width: 8),
                                      Text(
                                        'Your Data Rights (PDPA)',
                                        style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navyPrimary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    '• You own all your business data\n'
                                    '• Download it anytime as JSON/CSV\n'
                                    '• Delete it permanently with one click\n'
                                    '• Your financial data is never sold',
                                    style: GoogleFonts.dmSans(
                                      height: 1.6,
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getPrivacyPolicyText() {
    return '''MALI UP PRIVACY POLICY

Last Updated: 2026-05-24

1. DATA OWNERSHIP
Your business data belongs to you. Mali Up facilitates and records your transactions but does not own your data.

2. DATA RESIDENCY
All your data is stored in Tanzania/Africa region. We do not transfer data outside Tanzania without your consent.

3. ENCRYPTION
Your data is encrypted in transit (TLS 1.3) and at rest using Google Cloud encryption.

4. YOUR RIGHTS (PDPA)
• Right to Access: View all data Mali Up holds
• Right to Export: Download as JSON or CSV
• Right to Delete: Permanently delete all data
• Right to Correct: Update incorrect information
• Right to Withdraw Consent: Change preferences anytime

5. THIRD PARTIES
Mali Up does not sell your data to third parties. We only share data when necessary:
- Google Cloud: Infrastructure hosting
- BRELA: Business registration verification (you consent)
- M-Pesa Daraja: Transaction import (you consent)

6. FINANCIAL DATA
Your financial records are NEVER:
- Logged to analytics services
- Shared with marketers
- Used for profiling
- Sold to any party

7. BREACH NOTIFICATION
If your data is compromised, we notify you within 72 hours (PDPA requirement).

8. CHANGES TO POLICY
Significant policy changes require email notification and 30-day notice.

For questions: privacy@maliup.co.tz''';
  }
}

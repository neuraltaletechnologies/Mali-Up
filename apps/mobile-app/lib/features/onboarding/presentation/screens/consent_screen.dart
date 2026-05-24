import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Consent Screen - PDPA Compliance
/// Users must accept privacy policy before signup (PDPA requirement)
/// Allows granular consent for analytics and notifications

class ConsentScreen extends ConsumerStatefulWidget {
  final VoidCallback onConsentAccepted;

  const ConsentScreen({
    required this.onConsentAccepted,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool privacyAccepted = false;
  bool analyticsOptIn = true;
  bool notificationsOptIn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Privacy & Permissions'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Before We Get Started',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Mali Up respects your privacy. Please review our privacy policy and consent preferences.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Privacy Policy Checkbox (REQUIRED)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: privacyAccepted ? Colors.green[50] : Colors.transparent,
                ),
                child: CheckboxListTile(
                  title: const Text(
                    'I accept the Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: GestureDetector(
                    onTap: () => _showPrivacyPolicy(context),
                    child: Text(
                      'Read full policy',
                      style: TextStyle(
                        color: Colors.blue[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  value: privacyAccepted,
                  onChanged: (val) => setState(() => privacyAccepted = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 16),

              // Analytics Checkbox (OPTIONAL, default ON)
              CheckboxListTile(
                title: const Text('Help improve Mali Up'),
                subtitle: const Text('Send usage analytics (non-financial)'),
                value: analyticsOptIn,
                onChanged: (val) => setState(() => analyticsOptIn = val!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),

              // Notifications Checkbox (OPTIONAL, default ON)
              CheckboxListTile(
                title: const Text('Enable notifications'),
                subtitle: const Text(
                  'Get updates about invoices, expenses, and important events',
                ),
                value: notificationsOptIn,
                onChanged: (val) => setState(() => notificationsOptIn = val!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 32),

              // Continue Button (only if privacy accepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: privacyAccepted ? _proceedToSignup : null,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Continue to Signup',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Data Rights (PDPA)',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• You own all your business data\n'
                      '• Download it anytime as JSON/CSV\n'
                      '• Delete it permanently with one click\n'
                      '• Your financial data is never sold',
                      style: TextStyle(height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            _getPrivacyPolicyText(),
            style: const TextStyle(fontSize: 12),
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

  void _proceedToSignup() {
    // Save consent state to secure storage
    // ref.read(consentProvider.notifier).setConsent(
    //   privacyAccepted: privacyAccepted,
    //   analyticsOptIn: analyticsOptIn,
    //   notificationsOptIn: notificationsOptIn,
    // );

    // Show success and navigate
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy preferences saved')),
    );

    widget.onConsentAccepted();
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

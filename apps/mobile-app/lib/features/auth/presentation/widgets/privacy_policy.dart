import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Introduction',
              content:
                  'MaliUp ("we," "us," or "our") operates the MaliUp mobile and web application. This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our Service and the choices you have associated with that data.',
            ),
            _buildSection(
              title: '1. Information Collection and Use',
              content:
                  'We collect several different types of information for various purposes to provide and improve our Service to you.\n\n'
                  'Types of Data Collected:\n'
                  '• Personal Data: Phone number, email address, name, account type (business or personal)\n'
                  '• Usage Data: Information about how the Service is accessed and used\n'
                  '• Device Data: Device type, operating system, unique device identifiers\n'
                  '• Business Data: Business information, financial records, inventory data, sales data (for business accounts)\n'
                  '• Personal Account Data: Personal wealth tracking, debts, assets, creditors (for personal accounts)',
            ),
            _buildSection(
              title: '2. Security of Data',
              content:
                  'The security of your data is important to us, but remember that no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal data, we cannot guarantee its absolute security.',
            ),
            _buildSection(
              title: '3. Data Storage',
              content:
                  'Your data is stored securely using Firebase services and encrypted connections. All data transmission is protected using SSL/TLS encryption. We implement appropriate technical and organizational measures to maintain the security of your information.',
            ),
            _buildSection(
              title: '4. Use of Data',
              content:
                  'MaliUp uses the collected data for various purposes:\n\n'
                  '• To provide and maintain our Service\n'
                  '• To notify you about changes to our Service\n'
                  '• To allow you to participate in interactive features of our Service\n'
                  '• To provide customer care and support\n'
                  '• To gather analysis or valuable information so we can improve our Service\n'
                  '• To monitor the usage of our Service\n'
                  '• To detect, prevent and address technical issues',
            ),
            _buildSection(
              title: '5. Third-Party Services',
              content:
                  'We use third-party services for authentication and data storage (Firebase, Google Cloud). These service providers are contractually obligated to use your information only as necessary to provide services to us. The Privacy Policy of Firebase is available at: https://firebase.google.com/terms/analytics',
            ),
            _buildSection(
              title: '6. Privacy for Children',
              content:
                  'Our Service is not intended for use by anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13. If we become aware that we have collected personal data from children under 13 without parental consent, we take steps to delete such information and terminate the child\'s account.',
            ),
            _buildSection(
              title: '7. Changes to This Privacy Policy',
              content:
                  'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date at the bottom of this page.',
            ),
            _buildSection(
              title: '8. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                  'Email: contact@maliup.com\n'
                  'Address: Tanzania\n\n'
                  'We will respond to your request within 30 days.',
            ),
            _buildSection(
              title: '9. Data Retention',
              content:
                  'We will retain your personal data for as long as necessary to provide our Service and fulfill the purposes outlined in this Privacy Policy. You may request deletion of your account and data at any time by contacting us through the support channels in the app.',
            ),
            _buildSection(
              title: '10. Your Rights',
              content:
                  'Depending on your location, you may have the following rights:\n\n'
                  '• Right to Access: You can request information about what data we hold about you\n'
                  '• Right to Rectification: You can request correction of inaccurate data\n'
                  '• Right to Erasure: You can request deletion of your data\n'
                  '• Right to Data Portability: You can request a copy of your data in a portable format\n\n'
                  'To exercise any of these rights, please contact us using the details provided above.',
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Last Updated: ${_getLastUpdatedDate()}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _getLastUpdatedDate() {
    return 'April 1, 2026';
  }
}

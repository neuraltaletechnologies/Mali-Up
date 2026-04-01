import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '1. Agreement to Terms',
              content:
                  'By accessing and using the MaliUp platform (the "Service"), you agree to be bound by these Terms and Conditions. If you do not agree to abide by the above, please do not use this service.',
            ),
            _buildSection(
              title: '2. Use License',
              content:
                  'Permission is granted to temporarily download one copy of the materials (information or software) on MaliUp\'s Service for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                  '• Modify or copy the materials\n'
                  '• Use the materials for any commercial purpose or for any public display\n'
                  '• Attempt to decompile or reverse engineer any software contained on the Service\n'
                  '• Remove any copyright or other proprietary notations from the materials\n'
                  '• Transfer the materials to another person or "mirror" the materials on any other server',
            ),
            _buildSection(
              title: '3. Disclaimer',
              content:
                  'The materials on MaliUp\'s Service are provided on an "as is" basis. MaliUp makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
            ),
            _buildSection(
              title: '4. Limitations',
              content:
                  'In no event shall MaliUp or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on the Service, even if MaliUp or an authorized representative has been notified orally or in writing of the possibility of such damage.',
            ),
            _buildSection(
              title: '5. Accuracy of Materials',
              content:
                  'The materials appearing on the Service could include technical, typographical, or photographic errors. MaliUp does not warrant that any of the materials on the Service are accurate, complete, or current. MaliUp may make changes to the materials contained on the Service at any time without notice.',
            ),
            _buildSection(
              title: '6. Links',
              content:
                  'MaliUp has not reviewed all of the sites linked to its website and is not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by MaliUp of the site. Use of any such linked website is at the user\'s own risk.',
            ),
            _buildSection(
              title: '7. Modifications',
              content:
                  'MaliUp may revise these Terms and Conditions for the Service at any time without notice. By using this Service, you are agreeing to be bound by the then current version of these Terms and Conditions.',
            ),
            _buildSection(
              title: '8. Governing Law',
              content:
                  'These conditions and terms and any related agreements or documents which they incorporate by reference constitute the entire agreement and understanding between you and MaliUp and govern your use of the Service, superseding any prior negotiations, representations or agreements, either written or oral.',
            ),
            _buildSection(
              title: '9. User Accounts',
              content:
                  'If you create an account on the Service, you are responsible for maintaining the confidentiality of your account and password and for restricting access to your computer. You agree to accept responsibility for all activities that occur under your account or password. You must notify MaliUp immediately of any unauthorized uses of your account or any other breaches of security.',
            ),
            _buildSection(
              title: '10. User Conduct',
              content:
                  'You agree that you will not use the Service to post, upload, or transmit any unlawful, threatening, abusive, harassing, defamatory, vulgar, obscene, or otherwise objectionable material of any kind, including any material that infringes upon the rights of others or violates any applicable law.',
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Last Updated: ${_getLastUpdatedDate()}',
                style: const TextStyle(
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
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

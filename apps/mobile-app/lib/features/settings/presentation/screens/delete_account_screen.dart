import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';

/// Delete Account Screen - PDPA Right to Deletion
/// Implements Article 19 of Tanzania's Personal Data Protection Act
/// Users can permanently delete their account and all data
/// Includes 30-day grace period for cancellation

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool understandCheckbox = false;
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Delete Account', 'Futa Akaunti')),
        backgroundColor: Colors.red[50],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Text(
                          _t('Permanent Action', 'Hatua ya Kudumu'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      _t(
                        'Deleting your account will permanently remove all your business data. '
                        'This action can be undone within 30 days of requesting deletion.',
                        'Kufuta akaunti yako kutaondoa kabisa taarifa zote za biashara yako. '
                        'Hatua hii inaweza kughairiwa ndani ya siku 30 baada ya kuomba kufutwa.',
                      ),
                      style: GoogleFonts.dmSans(color: Colors.red[900]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // What Will Be Deleted
              Text(
                _t('What will be deleted:', 'Vitakavyofutwa:'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _t(
                    '• All invoices and payment records\n'
                    '• All customer information\n'
                    '• All expense records\n'
                    '• Inventory and stock data\n'
                    '• Account settings and preferences\n'
                    '• Your Mali Up login account\n\n'
                    'Note: Audit logs of your activities may be retained for compliance.',
                    '• Ankara zote na kumbukumbu za malipo\n'
                    '• Taarifa zote za wateja\n'
                    '• Kumbukumbu zote za matumizi\n'
                    '• Taarifa za stoo na bidhaa\n'
                    '• Mipangilio na mapendeleo ya akaunti\n'
                    '• Akaunti yako ya kuingia Mali Up\n\n'
                    'Kumbuka: Kumbukumbu za ukaguzi wa shughuli zako zinaweza kuhifadhiwa '
                    'kwa madhumuni ya uzingatiaji wa sheria.',
                  ),
                  style: GoogleFonts.dmSans(height: 1.8),
                ),
              ),
              const SizedBox(height: 24),

              // Confirmation Checkbox
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CheckboxListTile(
                  title: Text(
                    _t('I understand this is permanent',
                        'Naelewa hii ni ya kudumu'),
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                  value: understandCheckbox,
                  onChanged: isDeleting ? null : (val) => setState(() => understandCheckbox = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 24),

              // Delete Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: (understandCheckbox && !isDeleting) ? _initiateDelete : null,
                  child: isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _t('Delete My Account', 'Futa Akaunti Yangu'),
                          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Before You Delete
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Before you proceed:', 'Kabla hujaendelea:'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _t(
                        '1. Export your data first (for your records)\n'
                        '2. Settle any outstanding payments\n'
                        '3. Notify your customers if needed',
                        '1. Hamisha taarifa zako kwanza (kwa ajili ya kumbukumbu zako)\n'
                        '2. Kamilisha malipo yoyote yaliyobaki\n'
                        '3. Wajulishe wateja wako ikiwa inahitajika',
                      ),
                      style: GoogleFonts.dmSans(height: 1.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // PDPA Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('PDPA Right to Deletion', 'Haki ya Kufutwa (PDPA)'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _t(
                        'This implements Article 19 of Tanzania\'s Personal Data Protection Act, which gives you the right to deletion.\n\n'
                        'You have 30 days to cancel the deletion. After 30 days, your account and all data will be permanently deleted and cannot be recovered.',
                        'Hii inatekeleza Kifungu cha 19 cha Sheria ya Ulinzi wa Taarifa Binafsi ya Tanzania, '
                        'kinachokupa haki ya kufutwa kwa taarifa zako.\n\n'
                        'Una siku 30 kughairi ufutaji huo. Baada ya siku 30, akaunti yako na taarifa zote '
                        'zitafutwa kabisa na haziwezi kurejeshwa.',
                      ),
                      style: GoogleFonts.dmSans(height: 1.6),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initiateDelete() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_t('Delete account?', 'Futa akaunti?')),
        content: Text(
          _t(
            'Your account and all data will be marked for deletion. '
            'You have 30 days to cancel.\n\n'
            'Are you absolutely sure?',
            'Akaunti yako na taarifa zote zitawekwa alama ya kufutwa. '
            'Una siku 30 kughairi.\n\n'
            'Una uhakika kabisa?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600],
            ),
            child: Text(_t('Yes, Delete Account', 'Ndiyo, Futa Akaunti')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isDeleting = true);

    try {
      // In real implementation:
      // await userService.initiateAccountDeletion();

      await Future.delayed(const Duration(seconds: 2));

      setState(() => isDeleting = false);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(_t('Deletion Scheduled', 'Ufutaji Umepangwa')),
            content: Text(
              _t(
                'Your account deletion has been scheduled.\n\n'
                'You have 30 days to cancel in account settings.\n\n'
                'After 30 days, all data will be permanently deleted.',
                'Ufutaji wa akaunti yako umepangwa.\n\n'
                'Una siku 30 kughairi kupitia mipangilio ya akaunti.\n\n'
                'Baada ya siku 30, taarifa zote zitafutwa kabisa.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(_t('OK', 'Sawa')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => isDeleting = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_t("Error", "Hitilafu")}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


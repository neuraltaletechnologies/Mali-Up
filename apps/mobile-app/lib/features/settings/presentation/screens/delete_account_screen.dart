import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/routing.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_notification.dart';
import '../../../onboarding/providers/onboarding_notifier.dart';

/// Delete Account Screen - PDPA Right to Deletion
/// Users can permanently delete their account and associated data.

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
                    const SizedBox(height: 12),
                    Text(
                      _t(
                        'Deleting your account permanently removes your Mali Up login and data. '
                        'This action cannot be undone.',
                        'Kufuta akaunti yako kutaondoa kabisa akaunti yako ya Mali Up na taarifa zako. '
                        'Hatua hii haiwezi kughairiwa.',
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
              const SizedBox(height: 12),
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
                    'If you are a team member, records that belong to your employer\'s business '
                    'may be retained for bookkeeping, fraud prevention, or legal obligations.',
                    '• Ankara zote na kumbukumbu za malipo\n'
                    '• Taarifa zote za wateja\n'
                    '• Kumbukumbu zote za matumizi\n'
                    '• Taarifa za stoo na bidhaa\n'
                    '• Mipangilio na mapendeleo ya akaunti\n'
                    '• Akaunti yako ya kuingia Mali Up\n\n'
                    'Ikiwa wewe ni mfanyakazi wa timu, rekodi za biashara ya mwajiri wako '
                    'zinaweza kuhifadhiwa kwa uhasibu, kuzuia udanganyifu, au kutimiza wajibu wa kisheria.',
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
                    const SizedBox(height: 8),
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

              // Privacy information
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
                      _t('Your deletion right', 'Haki yako ya kufutwa'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _t(
                        'Your request is processed immediately. You must be online and signed in. '
                        'For help when you cannot sign in, email support@neuraltale.com.',
                        'Ombi lako linashughulikiwa mara moja. Lazima uwe mtandaoni na umeingia kwenye akaunti. '
                        'Kwa msaada usipoweza kuingia, tuma barua pepe kwa support@neuraltale.com.',
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
            'Your account and associated data will be permanently deleted now.\n\n'
            'Are you absolutely sure?',
            'Akaunti yako na taarifa zinazohusiana nayo zitafutwa kabisa sasa.\n\n'
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
    final database = ref.read(appDatabaseProvider);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable(
        'deleteAccountData',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
      );
      await callable.call<Map<String, dynamic>>();

      // Remote deletion succeeded. Remove account data cached on this device
      // before returning to onboarding.
      await database.clearAccountData();
      await SecurityService.disableAppLock();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ref.read(onboardingNotifierProvider.notifier).reset();
      context.go(AppRoutes.welcome);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => isDeleting = false);

      if (!mounted) return;
      AppNotification.error(
        context,
        e.code == 'unauthenticated'
            ? _t(
                'Please sign in again before deleting your account.',
                'Tafadhali ingia tena kabla ya kufuta akaunti yako.',
              )
            : _t(
                'Account deletion could not be completed. Check your connection and try again.',
                'Ufutaji wa akaunti haujakamilika. Angalia mtandao kisha ujaribu tena.',
              ),
      );
    } catch (_) {
      if (mounted) setState(() => isDeleting = false);
      if (!mounted) return;
      AppNotification.error(
        context,
        _t(
          'Account deletion could not be completed. Please try again.',
          'Ufutaji wa akaunti haujakamilika. Tafadhali jaribu tena.',
        ),
      );
    }
  }
}


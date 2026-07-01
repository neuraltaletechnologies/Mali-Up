import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

/// Delete Account Screen - PDPA Right to Deletion
/// Implements Article 19 of Tanzania's Personal Data Protection Act
/// Users can permanently delete their account and all data
/// Includes 30-day grace period for cancellation

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
        title: const Text('Delete Account'),
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
                          'Permanent Action',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Deleting your account will permanently remove all your business data. '
                      'This action can be undone within 30 days of requesting deletion.',
                      style: GoogleFonts.dmSans(color: Colors.red[900]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // What Will Be Deleted
              Text(
                'What will be deleted:',
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
                  '• All invoices and payment records\n'
                  '• All customer information\n'
                  '• All expense records\n'
                  '• Inventory and stock data\n'
                  '• Account settings and preferences\n'
                  '• Your Mali Up login account\n\n'
                  'Note: Audit logs of your activities may be retained for compliance.',
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
                    'I understand this is permanent',
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
                          'Delete My Account',
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
                      'Before you proceed:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Export your data first (for your records)\n'
                      '2. Settle any outstanding payments\n'
                      '3. Notify your customers if needed',
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
                      'PDPA Right to Deletion',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This implements Article 19 of Tanzania\'s Personal Data Protection Act, which gives you the right to deletion.\n\n'
                      'You have 30 days to cancel the deletion. After 30 days, your account and all data will be permanently deleted and cannot be recovered.',
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
        title: const Text('Delete account?'),
        content: const Text(
          'Your account and all data will be marked for deletion. '
          'You have 30 days to cancel.\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600],
            ),
            child: const Text('Yes, Delete Account'),
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
            title: const Text('Deletion Scheduled'),
            content: const Text(
              'Your account deletion has been scheduled.\n\n'
              'You have 30 days to cancel in account settings.\n\n'
              'After 30 days, all data will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
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
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


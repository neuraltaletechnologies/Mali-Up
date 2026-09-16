import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/localization_service.dart';
import '../../core/theme/app_colors.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Three buttons — WhatsApp, SMS, and PDF reminders — for sending a debt
/// reminder. Shared across the Debt detail sheet, the customer detail
/// screen's Balance card, the Record-Debt-Payment sheet, and the customer
/// list's quick info sheet, so every place a reminder can be sent from
/// offers the exact same three channels — one screen quietly keeping only a
/// plain-text WhatsApp button is what caused this to drift out of sync
/// before it was pulled out into a single shared widget.
class ReminderShareRow extends StatelessWidget {
  final VoidCallback? onWhatsApp;
  final VoidCallback? onSms;
  final VoidCallback? onPdf;

  const ReminderShareRow({
    super.key,
    required this.onWhatsApp,
    required this.onSms,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReminderShareBtn(
            label: _tr('WhatsApp Reminder', 'Ukumbusho wa WhatsApp'),
            icon: Icons.chat_outlined,
            color: AppColors.success,
            onTap: onWhatsApp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ReminderShareBtn(
            label: _tr('SMS Reminder', 'Ukumbusho wa SMS'),
            icon: Icons.sms_outlined,
            color: AppColors.warning,
            onTap: onSms,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ReminderShareBtn(
            label: _tr('PDF Reminder', 'Ukumbusho wa PDF'),
            icon: Icons.picture_as_pdf_outlined,
            color: AppColors.tealAccent,
            onTap: onPdf,
          ),
        ),
      ],
    );
  }
}

class _ReminderShareBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ReminderShareBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

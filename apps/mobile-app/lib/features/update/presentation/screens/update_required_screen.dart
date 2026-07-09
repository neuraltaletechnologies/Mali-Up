import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/services/version_gate_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Unbypassable full-screen blocker shown when [VersionGateStatus.tier] is
/// [VersionGateTier.hardBlock]. Styled to match [PinLockScreen] since both
/// are "standalone, on top of everything" states rendered directly in
/// main.dart rather than through the router.
class UpdateRequiredScreen extends StatefulWidget {
  final VersionGateStatus status;

  const UpdateRequiredScreen({super.key, required this.status});

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  bool _opening = false;

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  Future<void> _openStore() async {
    final url = Platform.isIOS
        ? widget.status.updateUrlIOS
        : widget.status.updateUrlAndroid;
    if (url.isEmpty) return;

    setState(() => _opening = true);
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) {
    final message = LocalizationService.languageNotifier.value.code == 'sw'
        ? widget.status.messageSw
        : widget.status.messageEn;

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.statusBarLightIcons,
        child: Scaffold(
          backgroundColor: AppColors.navyPrimary,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  // ── Branding ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.yellowBrand,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'M',
                            style: GoogleFonts.dmSans(
                              color: AppColors.navyPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'MALI UP',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: AppColors.yellowBrand,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _tr('Update required', 'Sasisho linahitajika'),
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.isNotEmpty
                        ? message
                        : _tr(
                            'A new version of Mali Up is required to continue. Please update the app.',
                            'Toleo jipya la Mali Up linahitajika kuendelea. Tafadhali sasisha programu.',
                          ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _opening ? null : _openStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellowBrand,
                        foregroundColor: AppColors.navyPrimary,
                        disabledBackgroundColor:
                            AppColors.yellowBrand.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _tr('Update Now', 'Sasisha Sasa'),
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

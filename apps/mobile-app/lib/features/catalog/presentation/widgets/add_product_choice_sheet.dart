import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/catalog_search_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

/// Bottom sheet shown when the user taps the "Add Product" FAB.
/// Gives a clear choice between browsing the catalog or creating from scratch.
class AddProductChoiceSheet extends StatelessWidget {
  /// Called when the user picks "Create Custom Product".
  final VoidCallback onCreateCustom;

  const AddProductChoiceSheet({super.key, required this.onCreateCustom});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            _tr('Add Product', 'Ongeza Bidhaa'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navyPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tr(
              'Choose how you want to add a product.',
              'Chagua jinsi ya kuongeza bidhaa.',
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Search Catalog option
          _ChoiceCard(
            icon: Icons.search_rounded,
            iconColor: AppColors.tealAccent,
            iconBg: const Color(0xFFE0F2F7),
            title: _tr('Search Product Catalog', 'Tafuta Bidhaa kwenye Katalogi'),
            subtitle: _tr(
              'Browse prebuilt products for your industry and import in one tap.',
              'Pata bidhaa za tasnia yako na zilete kwa kubonyeza mara moja.',
            ),
            badge: _tr('Recommended', 'Inapendekezwa'),
            onTap: () {
              Navigator.of(context).pop();
              _openCatalog(context);
            },
          ),

          const SizedBox(height: 12),

          // Create custom option
          _ChoiceCard(
            icon: Icons.add_circle_outline_rounded,
            iconColor: AppColors.navyPrimary,
            iconBg: const Color(0xFFEFF3FB),
            title: _tr('Create Custom Product', 'Unda Bidhaa ya Kipekee'),
            subtitle: _tr(
              'Manually enter all product details from scratch.',
              'Ingiza maelezo yote ya bidhaa mwenyewe.',
            ),
            onTap: () {
              Navigator.of(context).pop();
              onCreateCustom();
            },
          ),
        ],
      ),
    );
  }

  void _openCatalog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CatalogSearchScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.yellowBrand,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

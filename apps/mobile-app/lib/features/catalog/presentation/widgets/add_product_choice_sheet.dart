import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../screens/catalog_search_screen.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class AddProductChoiceSheet extends StatelessWidget {
  final VoidCallback onCreateCustom;
  final VoidCallback? onCreateReturn;
  final VoidCallback? onCreateManufactured;

  const AddProductChoiceSheet({
    super.key,
    required this.onCreateCustom,
    this.onCreateReturn,
    this.onCreateManufactured,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 12),
          Text(
            _tr('Add Product', 'Ongeza Bidhaa'),
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navyPrimary,
            ),
          ),
          const SizedBox(height: 14),

          _Tile(
            icon: Icons.search_rounded,
            label: _tr('Search Catalog', 'Chagua kwenye Katalogi'),
            badge: _tr('Best', 'Bora'),
            onTap: () {
              final nav = Navigator.of(context, rootNavigator: true);
              Navigator.of(context).pop();
              nav.push(MaterialPageRoute<void>(
                builder: (_) => const CatalogSearchScreen(),
                fullscreenDialog: true,
              ));
            },
          ),
          const SizedBox(height: 8),

          _Tile(
            icon: Icons.add_circle_outline_rounded,
            label: _tr('Create Custom', 'Unda Mwenyewe'),
            onTap: () {
              Navigator.of(context).pop();
              onCreateCustom();
            },
          ),
          const SizedBox(height: 8),

          _Tile(
            icon: Icons.precision_manufacturing_outlined,
            label: _tr('I Manufacture It', 'Ninatengeneza'),
            onTap: () {
              Navigator.of(context).pop();
              onCreateManufactured?.call();
            },
          ),
          const SizedBox(height: 8),

          _Tile(
            icon: Icons.assignment_return_outlined,
            label: _tr('Customer Return', 'Bidhaa Iliyorudishwa'),
            onTap: () {
              Navigator.of(context).pop();
              onCreateReturn?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.tealAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navyPrimary),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.yellowBrand, borderRadius: BorderRadius.circular(20)),
                child: Text(badge!, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.navyPrimary)),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 18),
          ],
        ),
      ),
    );
  }
}

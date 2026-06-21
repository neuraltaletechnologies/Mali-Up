import 'package:flutter/material.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../core/theme/app_colors.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class LegalComplianceScreen extends StatelessWidget {
  const LegalComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _tr('Legal & Compliance', 'Kisheria na Uzingatiaji'),
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Platform notice ──────────────────────────────────────────────
          _InfoBanner(
            icon: Icons.shield_outlined,
            title: _tr(
              'Mali Up is a business record-keeping platform',
              'Mali Up ni jukwaa la kuhifadhi rekodi za biashara',
            ),
            body: _tr(
              'Mali Up records and organises your financial transactions. '
              'We do not hold, transfer, or process funds. '
              'We are not a payment institution or bank.',
              'Mali Up inarekodia na kupanga miamala ya fedha yako. '
              'Hatushiki, kuhamisha, wala kusindika fedha. '
              'Sisi si taasisi ya malipo au benki.',
            ),
          ),
          const SizedBox(height: 20),

          // ── Regulatory framework ─────────────────────────────────────────
          _SectionHeader(label: _tr('Regulatory Framework', 'Mfumo wa Kisheria')),
          const SizedBox(height: 10),
          _RegCard(
            items: [
              _RegItem(
                icon: Icons.business_center_outlined,
                acronym: 'BRELA',
                title: _tr(
                  'Business Registrations and Licensing Agency',
                  'Wakala wa Usajili na Leseni za Biashara',
                ),
                body: _tr(
                  'Mali Up supports BRELA-registered businesses. '
                  'Phase 2 will include BRELA registration number validation '
                  'so your business credentials are verified automatically.',
                  'Mali Up inasaidia biashara zilizosajiliwa na BRELA. '
                  'Awamu ya 2 itajumuisha uthibitisho wa nambari ya usajili wa BRELA '
                  'ili vitambulisho vya biashara yako vithibitishwe kiotomatiki.',
                ),
              ),
              _RegItem(
                icon: Icons.receipt_long_outlined,
                acronym: 'TRA',
                title: _tr(
                  'Tanzania Revenue Authority',
                  'Mamlaka ya Mapato Tanzania',
                ),
                body: _tr(
                  'Mali Up tracks VAT at 18% and provides VAT summaries '
                  'aligned with TRA reporting requirements. '
                  'EFD (Electronic Fiscal Device) integration is planned for Phase 2. '
                  'CSV and PDF exports are structured for TRA-compliant filings.',
                  'Mali Up inafuatilia VAT kwa 18% na kutoa muhtasari wa VAT '
                  'unaooana na mahitaji ya kuripoti ya TRA. '
                  'Ujumuishaji wa EFD umepangwa kwa Awamu ya 2. '
                  'Maudhui ya CSV na PDF yamepangwa kwa uwasilishaji unaokidhi TRA.',
                ),
              ),
              _RegItem(
                icon: Icons.account_balance_outlined,
                acronym: 'BoT',
                title: _tr(
                  'Bank of Tanzania',
                  'Benki Kuu ya Tanzania',
                ),
                body: _tr(
                  'Because Mali Up does not hold or move money, '
                  'we operate outside the scope of BoT payment institution licensing. '
                  'We are a software record-keeping tool, not a financial institution.',
                  'Kwa sababu Mali Up haishiki wala kuhamisha fedha, '
                  'tunafanya kazi nje ya wigo wa leseni za taasisi za malipo za BoT. '
                  'Sisi ni chombo cha programu cha kuhifadhi rekodi, sio taasisi ya fedha.',
                ),
              ),
              _RegItem(
                icon: Icons.cell_tower_outlined,
                acronym: 'TCRA',
                title: _tr(
                  'Tanzania Communications Regulatory Authority',
                  'Mamlaka ya Udhibiti wa Mawasiliano Tanzania',
                ),
                body: _tr(
                  'Mali Up complies with TCRA digital service requirements '
                  'including TLS 1.3 encrypted data transmission, '
                  'data residency in Africa GCP region, '
                  'and user data transparency under the Personal Data Protection Act (PDPA).',
                  'Mali Up inazingatia mahitaji ya huduma za kidijitali za TCRA '
                  'ikiwa ni pamoja na usafirishaji wa data uliosimbwa TLS 1.3, '
                  'makazi ya data katika eneo la Afrika la GCP, '
                  'na uwazi wa data ya mtumiaji chini ya Sheria ya Kulinda Data Binafsi (PDPA).',
                ),
              ),
              _RegItem(
                icon: Icons.phone_android_outlined,
                acronym: 'M-Pesa',
                title: _tr(
                  'Safaricom/Vodacom Daraja API',
                  'Safaricom/Vodacom Daraja API',
                ),
                body: _tr(
                  'Phase 2 will include M-Pesa Daraja API integration '
                  'for automatic transaction import. '
                  'Mali Up will register as an approved Daraja API partner. '
                  'No M-Pesa funds will be held or processed by Mali Up.',
                  'Awamu ya 2 itajumuisha ujumuishaji wa M-Pesa Daraja API '
                  'kwa uingizaji wa miamala kiotomatiki. '
                  'Mali Up itajisajili kama mshirika wa Daraja API aliyeidhinishwa. '
                  'Hakuna fedha za M-Pesa zitakazoshikiliwa au kusindikwa na Mali Up.',
                ),
              ),
              _RegItem(
                icon: Icons.calculate_outlined,
                acronym: 'NBAA',
                title: _tr(
                  'National Board of Accountants and Auditors',
                  'Bodi ya Taifa ya Wahasibu na Wakaguzi',
                ),
                body: _tr(
                  'Financial reports in Mali Up — Profit & Loss, Balance Sheet, '
                  'and Cash Flow — are structured to align with NBAA SME '
                  'accounting standards for proper professional review.',
                  'Ripoti za fedha katika Mali Up — Faida na Hasara, Mizania, '
                  'na Mtiririko wa Fedha — zimepangwa kulingana na viwango vya '
                  'uhasibu wa NBAA kwa SME kwa mapitio sahihi ya kitaalamu.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Data protection ──────────────────────────────────────────────
          _SectionHeader(label: _tr('Data Protection', 'Ulinzi wa Data')),
          const SizedBox(height: 10),
          _InfoCard(
            children: [
              _BulletPoint(
                icon: Icons.lock_outline_rounded,
                text: _tr(
                  'All data is transmitted over TLS 1.3 encrypted connections.',
                  'Data yote inapitishwa kupitia miunganiko iliyosimbwa TLS 1.3.',
                ),
              ),
              _BulletPoint(
                icon: Icons.storage_outlined,
                text: _tr(
                  'Data is stored in Google Cloud Platform Africa region (Johannesburg).',
                  'Data inahifadhiwa katika eneo la Afrika la Google Cloud Platform (Johannesburg).',
                ),
              ),
              _BulletPoint(
                icon: Icons.analytics_outlined,
                text: _tr(
                  'Financial amounts are never sent to analytics or crash reporting tools.',
                  'Kiasi cha fedha hakitumwi kamwe kwa zana za uchanganuzi au ripoti za ajali.',
                ),
              ),
              _BulletPoint(
                icon: Icons.share_outlined,
                text: _tr(
                  'Your data is never sold or shared with third parties for marketing.',
                  'Data yako haiuzwi wala kushirikiwa na watu wengine kwa masoko.',
                ),
              ),
              _BulletPoint(
                icon: Icons.person_outline_rounded,
                text: _tr(
                  'Each business\'s data is isolated — other tenants cannot access it.',
                  'Data ya kila biashara imetengwa — wapangaji wengine hawawezi kuifikia.',
                ),
              ),
              _BulletPoint(
                icon: Icons.download_outlined,
                text: _tr(
                  'You can export or delete your data at any time from Settings.',
                  'Unaweza kuhamisha au kufuta data yako wakati wowote kutoka Mipangilio.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── VAT & Tax ────────────────────────────────────────────────────
          _SectionHeader(label: _tr('VAT & Tax Information', 'Taarifa za VAT na Kodi')),
          const SizedBox(height: 10),
          _InfoCard(
            children: [
              _BulletPoint(
                icon: Icons.percent_rounded,
                text: _tr(
                  'Mali Up applies the standard Tanzania VAT rate of 18% where enabled.',
                  'Mali Up inatumia kiwango cha kawaida cha VAT cha Tanzania cha 18% inapowezesha.',
                ),
              ),
              _BulletPoint(
                icon: Icons.summarize_outlined,
                text: _tr(
                  'VAT summaries are available in the Financial Reports section.',
                  'Muhtasari wa VAT unapatikana katika sehemu ya Ripoti za Fedha.',
                ),
              ),
              _BulletPoint(
                icon: Icons.file_download_outlined,
                text: _tr(
                  'CSV and PDF exports are structured to support TRA VAT filings.',
                  'Maudhui ya CSV na PDF yamepangwa kusaidia uwasilishaji wa VAT wa TRA.',
                ),
              ),
              _BulletPoint(
                icon: Icons.devices_outlined,
                text: _tr(
                  'EFD (Electronic Fiscal Device) integration is planned for Phase 2.',
                  'Ujumuishaji wa EFD (Kifaa cha Fedha cha Kielektroniki) umepangwa kwa Awamu ya 2.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── User rights ──────────────────────────────────────────────────
          _SectionHeader(label: _tr('Your Rights', 'Haki Zako')),
          const SizedBox(height: 10),
          _ActionCard(
            items: [
              _ActionItem(
                icon: Icons.privacy_tip_outlined,
                label: _tr('Privacy Policy', 'Sera ya Faragha'),
                onTap: () => _openSheet(
                  context,
                  title: _tr('Privacy Policy', 'Sera ya Faragha'),
                  content: _privacySummary(),
                ),
              ),
              _ActionItem(
                icon: Icons.gavel_outlined,
                label: _tr('Terms & Conditions', 'Sheria na Masharti'),
                onTap: () => _openSheet(
                  context,
                  title: _tr('Terms & Conditions', 'Sheria na Masharti'),
                  content: _termsSummary(),
                ),
              ),
              _ActionItem(
                icon: Icons.download_rounded,
                label: _tr('Export My Data', 'Hamisha Data Yangu'),
                onTap: () => Navigator.pushNamed(context, '/data-export'),
              ),
              _ActionItem(
                icon: Icons.delete_forever_outlined,
                label: _tr('Delete My Account', 'Futa Akaunti Yangu'),
                labelColor: AppColors.error,
                onTap: () => Navigator.pushNamed(context, '/delete-account'),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              _tr(
                'Mali Up — Built for Tanzanian businesses',
                'Mali Up — Imejengwa kwa biashara za Tanzania',
              ),
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _openSheet(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showAppSheet<void>(
      context,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.8,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _privacySummary() => _tr(
        'Mali Up ("we", "our", "us") collects only the information necessary '
        'to provide business management services to you.\n\n'
        '1. Data we collect: business transactions, customer names and phone numbers, '
        'expense records, inventory data, and account credentials.\n\n'
        '2. How we use it: to power Mali Up features, generate reports, '
        'and improve the app. We never sell your data.\n\n'
        '3. Data storage: all data is stored on Google Cloud Platform in the '
        'Africa region (Johannesburg, South Africa) with TLS 1.3 encryption.\n\n'
        '4. Your rights: you may export or delete all your data at any time '
        'from Settings → Legal & Compliance.\n\n'
        '5. Third parties: we use Firebase (Google) for authentication and '
        'database services. No financial data is shared with third-party analytics.\n\n'
        'For questions, contact: privacy@maliup.co.tz',
        'Mali Up ("sisi", "yetu") inakusanya taarifa zinazohitajika tu '
        'kutoa huduma za usimamizi wa biashara kwako.\n\n'
        '1. Data tunayokusanya: miamala ya biashara, majina na nambari za simu za wateja, '
        'rekodi za gharama, data ya bidhaa, na vitambulisho vya akaunti.\n\n'
        '2. Jinsi tunavyoitumia: kuendesha vipengele vya Mali Up, kuzalisha ripoti, '
        'na kuboresha programu. Hatuuzi data yako kamwe.\n\n'
        '3. Uhifadhi wa data: data yote inahifadhiwa kwenye Google Cloud Platform katika eneo '
        'la Afrika (Johannesburg, Afrika Kusini) kwa usimbaji fiche wa TLS 1.3.\n\n'
        '4. Haki zako: unaweza kuhamisha au kufuta data yako yote wakati wowote '
        'kutoka Mipangilio → Kisheria na Uzingatiaji.\n\n'
        '5. Watu wa tatu: tunatumia Firebase (Google) kwa huduma za uthibitishaji na hifadhidata. '
        'Hakuna data ya fedha inayoshirikiwa na uchanganuzi wa watu wengine.\n\n'
        'Kwa maswali, wasiliana: privacy@maliup.co.tz',
      );

  String _termsSummary() => _tr(
        'By using Mali Up, you agree to the following:\n\n'
        '1. Eligibility: you must be 18 years or older and operate a legitimate business.\n\n'
        '2. Account responsibility: you are responsible for keeping your PIN and '
        'login credentials secure. Mali Up is not liable for unauthorised access '
        'due to shared credentials.\n\n'
        '3. Acceptable use: Mali Up is for lawful business record-keeping only. '
        'Fraudulent, illegal, or deceptive use is strictly prohibited.\n\n'
        '4. Data accuracy: you are responsible for the accuracy of data you enter. '
        'Mali Up reports are based on the data you provide.\n\n'
        '5. Service availability: we aim for 99.9% uptime but do not guarantee '
        'uninterrupted service. Planned maintenance will be communicated in advance.\n\n'
        '6. Limitation of liability: Mali Up is not liable for financial decisions '
        'made based on app data.\n\n'
        '7. Governing law: these terms are governed by the laws of Tanzania.\n\n'
        'Contact: legal@maliup.co.tz',
        'Kwa kutumia Mali Up, unakubaliana na yafuatayo:\n\n'
        '1. Kustahili: lazima uwe na umri wa miaka 18 au zaidi na uendeshe biashara halali.\n\n'
        '2. Jukumu la akaunti: unajibika kwa kuweka PIN na vitambulisho vyako vya kuingia salama. '
        'Mali Up haiwajibiki kwa ufikiaji usioidhinishwa kutokana na vitambulisho vilivyoshirikiwa.\n\n'
        '3. Matumizi yanayokubalika: Mali Up ni kwa kuhifadhi rekodi za biashara halali tu. '
        'Matumizi ya udanganyifu, haramu, au ya udanganyifu yamepigwa marufuku kabisa.\n\n'
        '4. Usahihi wa data: unajibika kwa usahihi wa data unayoingiza. '
        'Ripoti za Mali Up zinategemea data unayotoa.\n\n'
        '5. Upatikanaji wa huduma: tunalenga muda wa kuendesha wa 99.9% lakini hatuhakikishi '
        'huduma isiyokatizwa. Matengenezo yaliyopangwa yatawasilishwa mapema.\n\n'
        '6. Ukomo wa dhima: Mali Up haiwajibiki kwa maamuzi ya kifedha '
        'yaliyofanywa kulingana na data ya programu.\n\n'
        '7. Sheria inayotumika: masharti haya yanasimamiwa na sheria za Tanzania.\n\n'
        'Wasiliana: legal@maliup.co.tz',
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoBanner(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.secondary)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegCard extends StatelessWidget {
  final List<_RegItem> items;
  const _RegCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RegTile(item: item),
              ))
          .toList(),
    );
  }
}

class _RegItem {
  final IconData icon;
  final String acronym;
  final String title;
  final String body;
  const _RegItem(
      {required this.icon,
      required this.acronym,
      required this.title,
      required this.body});
}

class _RegTile extends StatefulWidget {
  final _RegItem item;
  const _RegTile({required this.item});

  @override
  State<_RegTile> createState() => _RegTileState();
}

class _RegTileState extends State<_RegTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _expanded
            ? AppColors.secondary.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.secondary.withValues(alpha: 0.18)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.item.icon,
                        color: AppColors.secondary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.item.acronym,
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                widget.item.body,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BulletPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.tealAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final List<_ActionItem> items;
  const _ActionCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              _ActionTile(item: e.value),
              if (!isLast)
                const Divider(
                    height: 1, indent: 16, endIndent: 16, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;
  const _ActionItem(
      {required this.icon,
      required this.label,
      this.labelColor,
      required this.onTap});
}

class _ActionTile extends StatelessWidget {
  final _ActionItem item;
  const _ActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.labelColor ?? AppColors.textPrimary;
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: item.labelColor ?? AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

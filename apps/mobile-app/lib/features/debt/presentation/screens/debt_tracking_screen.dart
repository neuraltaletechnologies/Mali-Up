import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/emotional_design.dart';
import '../../data/debt_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class DebtTrackingScreen extends ConsumerStatefulWidget {
  const DebtTrackingScreen({super.key});

  @override
  ConsumerState<DebtTrackingScreen> createState() => _DebtTrackingScreenState();
}

class _DebtTrackingScreenState extends ConsumerState<DebtTrackingScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtListProvider);
    final allDebtItems = debts.maybeWhen(data: (items) => items, orElse: () => const []);

    // Filter debts based on search
    final filteredDebtItems = _searchController.text.isEmpty
        ? allDebtItems
        : allDebtItems
            .where((debt) =>
                debt.partyName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                debt.status.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Control debt exposure', 'Dhibiti mzigo wa madeni'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tr(
                            'See what you owe and what is owed to you, with clear status tracking.',
                            'Ona unachodaiwa na unachodai, kwa ufuatiliaji wa hali ulio wazi.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const EmotionalLottieSpot(
                    scene: EmotionalLottieScene.celebrate,
                    size: 62,
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _DebtOverviewBoard(),
            ),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _tr('Search by party name or status...', 'Tafuta kwa jina au hali...'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                _tr('Recent Debt Movements', 'Mienendo ya Madeni ya Karibuni'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
          
          if (filteredDebtItems.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _tr('No debts found', 'Hakuna madeni yaliofumanwa'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final debt = filteredDebtItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DebtCard(debt: debt),
                    );
                  },
                  childCount: filteredDebtItems.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.error,
        child: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
      ),
    );
  }
}

class _DebtOverviewBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.background.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                _tr('Debt Exposure Summary', 'Muhtasari wa Mzigo wa Madeni'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _BigStat(label: _tr('You Owe', 'Unadaiwa'), value: '4.2M', color: AppColors.error),
              ),
              Container(width: 1, height: 40, color: AppColors.glassBorder),
              Expanded(
                child: _BigStat(label: _tr('Owed to You', 'Unachodai'), value: '1.8M', color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BigStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  final dynamic debt;
  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    final bool isPayable = debt.type == 'Payable';
    final Color statusColor = debt.status == 'Overdue' ? AppColors.error : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPayable ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isPayable ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPayable ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
              color: isPayable ? AppColors.error : AppColors.success,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.partyName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isPayable ? _tr('To Supplier', 'Kwa Muuzaji') : _tr('From Customer', 'Kutoka kwa Mteja'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                debt.amount,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  debt.status.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

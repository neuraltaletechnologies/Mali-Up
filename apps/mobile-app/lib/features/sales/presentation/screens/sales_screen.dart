import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/page_intro_header.dart';
import '../../data/sales_providers.dart';

String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesInvoiceListProvider);

    return Scaffold(
      body: Column(
        children: [
          PageIntroHeader(
            title: _tr('Track sales momentum', 'Fuatilia kasi ya mauzo'),
            subtitle: _tr(
              'Monitor invoices, pending collections, and paid revenue in one place.',
              'Fuatilia ankara, makusanyo yanayosubiri, na mapato yaliyolipwa sehemu moja.',
            ),
            scene: EmotionalLottieScene.dashboard,
          ),
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  _tr('Unable to load sales right now.', 'Imeshindikana kupakia mauzo kwa sasa.'),
                ),
              ),
              data: (items) {
                final paid = items.where((item) => readInvoiceStatus(item).toLowerCase() == 'paid').toList();
                final pending = items.where((item) => readInvoiceStatus(item).toLowerCase() != 'paid').toList();
                final totalSales = items.fold<double>(0, (sum, item) => sum + parseNumericAmount(item['amount']));
                final paidSales = paid.fold<double>(0, (sum, item) => sum + parseNumericAmount(item['amount']));
                final pendingSales = pending.fold<double>(0, (sum, item) => sum + parseNumericAmount(item['amount']));

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _OverviewStat(label: _tr('Total Sales', 'Jumla ya Mauzo'), value: _fmtAmount(totalSales), color: AppColors.primaryLight),
                          _OverviewStat(label: _tr('Pending', 'Inasubiri'), value: _fmtAmount(pendingSales), color: AppColors.secondary),
                          _OverviewStat(label: _tr('Paid', 'Imelipwa'), value: _fmtAmount(paidSales), color: AppColors.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Text(_tr('No sales invoices yet.', 'Bado hakuna ankara za mauzo.')),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: items.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final status = readInvoiceStatus(item);
                                final amount = parseNumericAmount(item['amount']);
                                final id = (item['invoiceNumber'] ?? item['id'] ?? '').toString();
                                final customer = (item['customerName'] ?? item['customer'] ?? item['partyName'] ?? _tr('Unknown customer', 'Mteja hajulikani')).toString();
                                final date = readTimestamp(item['createdAt'] ?? item['date']);

                                return _InvoiceListItem(
                                  id: id.isEmpty ? '#${index + 1}' : '#$id',
                                  customer: customer,
                                  amount: _fmtAmount(amount),
                                  status: status,
                                  date: _fmtDate(date),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtAmount(double amount) {
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'TSh ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'TSh ${amount.toStringAsFixed(0)}';
  }

  static String _fmtDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _InvoiceListItem extends StatelessWidget {
  final String id;
  final String customer;
  final String amount;
  final String status;
  final String date;

  const _InvoiceListItem({required this.id, required this.customer, required this.amount, required this.status, required this.date});

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase();
    Color statusColor;
    if (statusLower == 'paid') {
      statusColor = AppColors.success;
    } else if (statusLower == 'pending') {
      statusColor = AppColors.secondary;
    } else {
      statusColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.article_outlined, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(id, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 12)),
                    Text(date, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(customer, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(amount, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

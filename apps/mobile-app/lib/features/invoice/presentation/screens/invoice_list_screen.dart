import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/invoice_provider.dart';
import '../../domain/models/invoice.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';

// Global invoice provider instance
final _invoiceProviderInstance = InvoiceProvider();

// Wrapper provider that exposes the notifier
final invoiceChangeNotifierProvider = Provider<InvoiceProvider>((ref) {
  return _invoiceProviderInstance;
});

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceChangeNotifierProvider).fetchInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = ref.watch(invoiceChangeNotifierProvider);
    final invoices = invoiceProvider.invoices;
    final isLoading = invoiceProvider.isLoading;
    final error = invoiceProvider.error;

    // Filter invoices based on search and filter
    List<Invoice> filteredInvoices = invoices;
    
    if (_searchController.text.isNotEmpty) {
      filteredInvoices = invoiceProvider.searchInvoices(_searchController.text);
    }
    
    if (_selectedFilter != 'all') {
      filteredInvoices = invoiceProvider.getInvoicesByStatus(_selectedFilter);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          LocalizationService.tr(
            en: AppStrings.get('invoices'),
            sw: AppStrings.get('invoices', isSwahili: true),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.read(invoiceChangeNotifierProvider).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Column(
            children: [
              AppSearchBar(
                controller: _searchController,
                hintText: LocalizationService.tr(
                  en: 'Search invoices...',
                  sw: 'Tafuta ankara...',
                ),
                onChanged: (_) => setState(() {}),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              ),
              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    AppFilterChip(
                      label: LocalizationService.tr(en: 'All', sw: 'Zote'),
                      selected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: LocalizationService.tr(en: 'Pending', sw: 'Zinasubiri'),
                      selected: _selectedFilter == 'pending',
                      onTap: () => setState(() => _selectedFilter = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: LocalizationService.tr(en: 'Paid', sw: 'Zilizolipwa'),
                      selected: _selectedFilter == 'paid',
                      onTap: () => setState(() => _selectedFilter = 'paid'),
                    ),
                    const SizedBox(width: 8),
                    AppFilterChip(
                      label: LocalizationService.tr(en: 'Overdue', sw: 'Zilizochelewa'),
                      selected: _selectedFilter == 'overdue',
                      onTap: () => setState(() => _selectedFilter = 'overdue'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          
          // Summary cards
          if (invoices.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Today Sales',
                      invoiceProvider.getTodaySales(),
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Outstanding',
                      invoiceProvider.getTotalOutstanding(),
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          
          // Invoice list
          Expanded(
            child: _buildInvoiceList(filteredInvoices, isLoading, error),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateInvoice(),
        backgroundColor: AppColors.yellowBrand,
        foregroundColor: AppColors.navyPrimary,
        elevation: 3,
        icon: const Icon(Icons.description_rounded, size: 20),
        label: Text(
          LocalizationService.tr(en: 'New Invoice', sw: 'Ankara Mpya'),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowCard, blurRadius: 6, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TZS ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navyPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(List<Invoice> invoices, bool isLoading, String? error) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SkeletonList(),
      );
    }

    if (error != null) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: LocalizationService.tr(en: 'Could not load invoices', sw: 'Imeshindwa kupakia ankara'),
        subtitle: LocalizationService.tr(en: 'Check your connection and try again.', sw: 'Angalia muunganiko wako na ujaribu tena.'),
        actionLabel: LocalizationService.tr(en: 'Retry', sw: 'Jaribu tena'),
        onAction: () => ref.read(invoiceChangeNotifierProvider).refresh(),
      );
    }

    if (invoices.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_rounded,
        title: LocalizationService.tr(en: 'No invoices found', sw: 'Hakuna ankara zilizopatikana'),
        subtitle: _searchController.text.isNotEmpty
            ? LocalizationService.tr(en: 'Try adjusting your search or filters.', sw: 'Jaribu kubadilisha utafutaji au vichujio vyako.')
            : LocalizationService.tr(en: 'Create your first invoice to get started.', sw: 'Unda ankara yako ya kwanza kuanza.'),
        actionLabel: _searchController.text.isEmpty
            ? LocalizationService.tr(en: 'Create Invoice', sw: 'Unda Ankara')
            : null,
        onAction: _searchController.text.isEmpty ? _navigateToCreateInvoice : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(invoiceChangeNotifierProvider).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return InvoiceCard(
            invoice: invoice,
            onTap: () => _showInvoiceDetails(invoice),
            onShare: () => _shareInvoice(invoice),
            onMarkPaid: invoice.status == 'pending'
                ? () => _markAsPaid(invoice)
                : null,
          );
        },
      ),
    );
  }

  void _navigateToCreateInvoice() {
    Navigator.pushNamed(context, '/create-invoice');
  }

  void _showInvoiceDetails(Invoice invoice) {
    showAppSheet(
      context,
      builder: (context) => _buildInvoiceDetailsSheet(invoice),
    );
  }

  Widget _buildInvoiceDetailsSheet(Invoice invoice) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.8,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          color: AppColors.background,
        ),
        child: Column(
          children: [
            const SheetHandle(),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Invoice ${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PaymentStatusChip(status: invoice.status),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer info
                  _buildDetailRow('Customer', invoice.customerName),
                  _buildDetailRow('Date', invoice.date),
                  _buildDetailRow('Due Date', invoice.dueDate),
                  const Divider(),
                  
                  // Items
                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...invoice.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (item.description.isNotEmpty)
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.total.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const Divider(),
                  
                  // Totals
                  _buildTotalRow('Subtotal', invoice.subtotal),
                  _buildTotalRow('Tax (18%)', invoice.tax),
                  _buildTotalRow('Total', invoice.total, isBold: true),
                  
                  if (invoice.note.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      'Note',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(invoice.note),
                  ],
                ],
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareInvoice(invoice),
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (invoice.status == 'pending')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsPaid(invoice),
                        icon: const Icon(Icons.check),
                        label: const Text('Mark Paid'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'TZS ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }



  void _shareInvoice(Invoice invoice) async {
    final whatsappText = ref.read(invoiceChangeNotifierProvider).generateWhatsAppReceipt(invoice.id);
    final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(whatsappText)}';
    
    try {
      await launchUrl(Uri.parse(whatsappUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.tr(
              en: 'Could not open WhatsApp. Make sure it\'s installed.',
              sw: 'Imeshindwa kufungua WhatsApp. Hakikisha imesakinishwa.',
            )),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _markAsPaid(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text('Mark invoice ${invoice.invoiceNumber} as paid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(invoiceChangeNotifierProvider).markAsPaid(invoice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? LocalizationService.tr(en: 'Invoice marked as paid', sw: 'Ankara imewekwa kama imelipwa')
                : LocalizationService.tr(en: 'Could not update invoice. Please try again.', sw: 'Imeshindwa kusasisha ankara. Jaribu tena.')),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}


class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback? onShare;
  final VoidCallback? onMarkPaid;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
    this.onShare,
    this.onMarkPaid,
  });

  Color get _stripeColor {
    switch (invoice.status) {
      case 'paid':    return AppColors.success;
      case 'overdue': return AppColors.error;
      default:        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(color: AppColors.shadowCard, blurRadius: 6, offset: Offset(0, 1)),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _stripeColor,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _stripeColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.receipt_long_rounded, size: 20, color: _stripeColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      invoice.invoiceNumber,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PaymentStatusChip(status: invoice.status),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                invoice.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Due: ${invoice.dueDate}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'TZS ${invoice.total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (onShare != null || onMarkPaid != null) ...[
                          const SizedBox(width: 4),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (onShare != null)
                                IconButton(
                                  icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.textMuted),
                                  onPressed: onShare,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              if (onMarkPaid != null)
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
                                  onPressed: onMarkPaid,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


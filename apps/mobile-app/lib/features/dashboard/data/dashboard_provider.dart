import 'package:flutter/foundation.dart';
import '../../../core/services/firestore_service.dart';
import '../../customer/data/customer_provider.dart';
import '../../invoice/data/invoice_provider.dart';
import '../../finance/data/expense_provider.dart';
import '../../inventory/data/inventory_provider.dart';

class DashboardProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final CustomerProvider _customerProvider;
  final InvoiceProvider _invoiceProvider;
  final ExpenseProvider _expenseProvider;
  final InventoryProvider _inventoryProvider;

  // Dashboard data
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = false;
  String? _error;
  DateTime _lastRefresh = DateTime.now();

  DashboardProvider({
    FirestoreService? firestoreService,
    CustomerProvider? customerProvider,
    InvoiceProvider? invoiceProvider,
    ExpenseProvider? expenseProvider,
    InventoryProvider? inventoryProvider,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _customerProvider = customerProvider ?? CustomerProvider(),
        _invoiceProvider = invoiceProvider ?? InvoiceProvider(),
        _expenseProvider = expenseProvider ?? ExpenseProvider(),
        _inventoryProvider = inventoryProvider ?? InventoryProvider();

  // Getters
  Map<String, dynamic> get dashboardStats => Map.unmodifiable(_dashboardStats);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  DateTime get lastRefresh => _lastRefresh;

  // Dashboard metrics getters
  double get todaySales => (_dashboardStats['todaySales'] as num?)?.toDouble() ?? 0.0;
  double get monthSales => (_dashboardStats['monthSales'] as num?)?.toDouble() ?? 0.0;
  double get totalExpenses => (_dashboardStats['totalExpenses'] as num?)?.toDouble() ?? 0.0;
  double get totalDebts => (_dashboardStats['totalDebts'] as num?)?.toDouble() ?? 0.0;
  int get lowStockCount => (_dashboardStats['lowStockCount'] as int?) ?? 0;
  List<dynamic> get lowStockItems => (_dashboardStats['lowStockItems'] as List?) ?? [];

  // Computed metrics
  double get netProfit => monthSales - totalExpenses;
  double get profitMargin => monthSales > 0 ? (netProfit / monthSales * 100) : 0;
  double get debtToSalesRatio => monthSales > 0 ? (totalDebts / monthSales * 100) : 0;

  // Refresh dashboard data
  Future<void> refreshDashboard() async {
    _setLoading(true);
    try {
      // Fetch all provider data
      await Future.wait([
        _customerProvider.fetchCustomers(),
        _invoiceProvider.fetchInvoices(),
        _expenseProvider.fetchExpenses(),
        _inventoryProvider.fetchInventoryItems(),
      ]);

      // Get dashboard stats from Firestore
      final stats = await _firestoreService.getDashboardStats();
      
      // Combine Firestore stats with provider data
      _dashboardStats = {
        ...stats,
        'customerCount': _customerProvider.customerCount,
        'invoiceCount': _invoiceProvider.invoiceCount,
        'expenseCount': _expenseProvider.expenseCount,
        'inventoryCount': _inventoryProvider.itemCount,
        'pendingInvoices': _invoiceProvider.getPendingInvoices().length,
        'overdueInvoices': _invoiceProvider.getOverdueInvoices().length,
        'totalOutstanding': _invoiceProvider.getTotalOutstanding(),
        'todayExpenses': _expenseProvider.getTodayTotal(),
        'monthExpenses': _expenseProvider.getMonthTotal(),
        'inventoryValue': _inventoryProvider.getTotalInventoryValue(),
        'stockStats': _inventoryProvider.getStockStatistics(),
        'lastRefresh': DateTime.now().toIso8601String(),
      };

      _lastRefresh = DateTime.now();
      _clearError();
    } catch (e) {
      _setError('Failed to refresh dashboard: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get greeting based on time of day
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Habari za asubuhi';
    if (hour >= 12 && hour < 17) return 'Habari za mchana';
    if (hour >= 17 && hour < 21) return 'Habari za jioni';
    return 'Habari za usiku';
  }

  // Get user name (placeholder - would come from user profile)
  String getUserName() {
    // TODO: Get actual user name from profile
    return 'Mteja';
  }

  // Get formatted currency values
  String formatCurrency(double amount) {
    return ' ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  // Get percentage value
  String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // Get sales trend (last 7 days)
  List<Map<String, dynamic>> getSalesTrend() {
    final trend = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Calculate sales for this date
      final daySales = _invoiceProvider.invoices
          .where((invoice) => invoice.date == dateString && (invoice.status == 'paid' || invoice.status == 'pending'))
          .fold<double>(0, (sum, invoice) => sum + invoice.total);
      
      trend.add({
        'date': dateString,
        'sales': daySales,
        'dayName': _getDayName(date.weekday),
      });
    }
    
    return trend;
  }

  // Get expense trend (last 7 days)
  List<Map<String, dynamic>> getExpenseTrend() {
    return _expenseProvider.getWeeklyExpenseTrends().entries.map((entry) => {
      'date': entry.key,
      'expenses': entry.value,
      'dayName': _getDayName(DateTime.parse(entry.key).weekday),
    }).toList();
  }

  // Get top customers by debt
  List<Map<String, dynamic>> getTopCustomersByDebt({int limit = 5}) {
    final customersWithDebt = _customerProvider.getCustomersWithDebt();
    customersWithDebt.sort((a, b) {
      final debtA = double.tryParse(a.balance) ?? 0;
      final debtB = double.tryParse(b.balance) ?? 0;
      return debtA.compareTo(debtB);
    });
    
    return customersWithDebt.take(limit).map((customer) => {
      'customer': customer,
      'debt': (double.tryParse(customer.balance) ?? 0).abs(),
    }).toList();
  }

  // Get top expense categories
  List<Map<String, dynamic>> getTopExpenseCategories({int limit = 5}) {
    return _expenseProvider.getTopExpenseCategories(limit: limit).map((entry) => {
      'category': entry.key,
      'amount': entry.value,
      'percentage': _expenseProvider.getMonthTotal() > 0 
          ? (entry.value / _expenseProvider.getMonthTotal() * 100).roundToDouble()
          : 0,
    }).toList();
  }

  // Get inventory alerts
  List<Map<String, dynamic>> getInventoryAlerts() {
    final alerts = <Map<String, dynamic>>[];
    
    // Low stock alerts
    final lowStockItems = _inventoryProvider.getLowStockItems();
    for (final item in lowStockItems.take(5)) {
      alerts.add({
        'type': 'low_stock',
        'item': item,
        'message': '${item.name} - Stock: ${item.currentStock} ${item.unit}',
        'severity': item.isOutOfStock ? 'high' : 'medium',
      });
    }
    
    // Out of stock alerts
    final outOfStockItems = _inventoryProvider.getOutOfStockItems();
    for (final item in outOfStockItems.take(3)) {
      alerts.add({
        'type': 'out_of_stock',
        'item': item,
        'message': '${item.name} - Out of stock',
        'severity': 'high',
      });
    }
    
    return alerts;
  }

  // Get recent activities
  List<Map<String, dynamic>> getRecentActivities({int limit = 10}) {
    final activities = <Map<String, dynamic>>[];
    
    // Recent invoices
    final recentInvoices = _invoiceProvider.invoices.take(limit ~/ 3);
    for (final invoice in recentInvoices) {
      activities.add({
        'type': 'invoice',
        'title': 'Invoice ${invoice.invoiceNumber}',
        'description': '${invoice.customerName} - ${formatCurrency(invoice.total)}',
        'date': invoice.date,
        'status': invoice.status,
      });
    }
    
    // Recent expenses
    final recentExpenses = _expenseProvider.expenses.take(limit ~/ 3);
    for (final expense in recentExpenses) {
      activities.add({
        'type': 'expense',
        'title': expense.category,
        'description': formatCurrency(double.tryParse(expense.amount) ?? 0),
        'date': expense.date,
        'note': expense.note,
      });
    }
    
    // Sort by date
    activities.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    
    return activities.take(limit).toList();
  }

  // Get business health indicators
  Map<String, dynamic> getBusinessHealth() {
    final healthScore = _calculateHealthScore();
    final healthStatus = _getHealthStatus(healthScore);
    
    return {
      'score': healthScore,
      'status': healthStatus,
      'indicators': {
        'sales': monthSales > 0,
        'profitability': netProfit > 0,
        'debtManagement': totalDebts < monthSales * 0.3,
        'inventory': lowStockCount < _inventoryProvider.itemCount * 0.2,
        'cashFlow': monthSales > totalExpenses,
      },
    };
  }

  // Calculate overall business health score (0-100)
  double _calculateHealthScore() {
    double score = 50; // Base score
    
    // Sales performance (20 points)
    if (monthSales > 0) score += 20;
    
    // Profitability (20 points)
    if (netProfit > 0) {
      score += 20;
    } else if (netProfit > -monthSales * 0.1) score += 10;
    
    // Debt management (15 points)
    if (totalDebts < monthSales * 0.2) {
      score += 15;
    } else if (totalDebts < monthSales * 0.4) score += 10;
    else if (totalDebts < monthSales * 0.6) score += 5;
    
    // Inventory management (15 points)
    final lowStockRatio = _inventoryProvider.itemCount > 0 
        ? lowStockCount / _inventoryProvider.itemCount 
        : 0;
    if (lowStockRatio < 0.1) {
      score += 15;
    } else if (lowStockRatio < 0.2) score += 10;
    else if (lowStockRatio < 0.3) score += 5;
    
    // Cash flow (15 points)
    if (monthSales > totalExpenses) {
      score += 15;
    } else if (monthSales > totalExpenses * 0.8) score += 10;
    else if (monthSales > totalExpenses * 0.6) score += 5;
    
    return score.clamp(0.0, 100.0);
  }

  String _getHealthStatus(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}

import 'customer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerListProvider = StateProvider<List<Customer>>((ref) {
  return [
    Customer(
      id: '1',
      name: 'Michael Jordan',
      phone: '+255 712 345 678',
      email: 'mj@bulls.com',
      balance: 'TSh 1.2M',
      lastTransactionDate: 'Today, 10:45 AM',
      tags: ['VIP', 'Regular'],
    ),
    Customer(
      id: '2',
      name: 'Serena Williams',
      phone: '+255 714 555 111',
      email: 'thegoat@tennis.com',
      balance: 'TSh 450K',
      lastTransactionDate: 'Yesterday',
      tags: ['Premium'],
    ),
    Customer(
      id: '3',
      name: 'LeBron James',
      phone: '+255 766 888 999',
      email: 'king@james.com',
      balance: 'TSh 0',
      lastTransactionDate: 'Oct 20, 2026',
      tags: ['New'],
    ),
  ];
});

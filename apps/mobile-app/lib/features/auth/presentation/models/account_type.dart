enum AccountType {
  business,
}

extension AccountTypeX on AccountType {
  String get value => 'business';
  String get label => 'Business';
  String get icon => '🏢';
}

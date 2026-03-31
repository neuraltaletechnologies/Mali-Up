enum AccountType {
  business,
  personal,
}

extension AccountTypeX on AccountType {
  String get value => this == AccountType.business ? 'business' : 'personal';

  String get label => this == AccountType.business ? 'Business' : 'Personal';

  String get icon => this == AccountType.business ? '🏢' : '👤';
}

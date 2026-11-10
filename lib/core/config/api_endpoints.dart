class ApiEndpoints {
  static String get baseUrl => 'https://varakhata.jabedinternational.com/';
  static String get apiBaseUrl => 'https://varakhata.jabedinternational.com/api/';

  // 📦 Auth
  String get registerUser => 'auth/register';
  String get loginUser => 'auth/login';
  String get forgotPasswordSendPin => 'forgot-password';
  String get forgotPasswordVerifyPin => 'verify-reset-pin';
  String get forgotPasswordSetNewPassword => 'reset-password';

  // 📦 Dashboard
  String get dashboard => 'dashboard';

  // 📦 Properties & Units
  String get properties => 'properties';
  String get detailedProperties => 'detailed/properties';
  String propertyDetail(int id) => 'properties/$id';
  String get units => 'units';
  String unitDetail(int id) => 'units/$id';

  // 📦 Tenants
  String get tenants => 'tenants';
  String tenantDetail(int id) => 'tenants/$id';
  String tenantEndLease(int id) => 'tenants/$id/end-lease';

  // 📦 Bills
  String get bills => 'bills';
  String billDetail(int id) => 'bills/$id';

  // 📦 Expenses
  String get expenses => 'expenses';
  String expenseDetail(int id) => 'expenses/$id';

  // 📦 Finance — Rent Collections
  String get rentCollections => 'rent-collections';

  // 📦 Finance — Transactions
  String get transactions => 'transactions';
  String transactionDetail(int id) => 'transactions/$id';

  // 📦 Avatar
  String avatar(String path) => 'https://vcard.vaccinehomebd.com/storage/app/public/$path';

  // 📦 Subscription
  String get subscriptionMe => 'subscription/me';

  // 📦 Reports
  String get incomeExpenseReport => 'reports/income-expense';
}

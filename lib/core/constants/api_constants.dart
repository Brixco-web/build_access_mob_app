/// API Endpoints and Network Constants
abstract class ApiConstants {
  // Replace with your Vercel deployment URL or local IP
  static const String baseUrl = 'https://building-accessories-management.vercel.app/api';

  // Auth
  static const String login = '/auth/login';
  static const String passwordChange = '/settings/password';
  static const String profile = '/settings/profile';

  // Dashboard & Metrics
  static const String dashboard = '/dashboard';

  // Inventory & Categories
  static const String items = '/items';
  static const String categories = '/categories';

  // Sales & Stock Out
  static const String stockOut = '/stock-out';

  // Stock In & Deliveries
  static const String stockIn = '/stock-in';

  // Purchase Orders
  static const String orders = '/orders';

  // Financial & Reports
  static const String financialSummary = '/financial/summary';
  static const String customReport = '/reports/custom';
  static const String monthlyReport = '/reports/monthly';
  static const String otherExpenses = '/other-expenses';

  // Suppliers & Debt Payment
  static const String suppliers = '/suppliers';

  // Users & Activity Logs
  static const String users = '/users';
  static const String activityLogs = '/activity-logs';
}

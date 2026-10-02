/// Admin/calendar endpoints added for the back-office screens
/// (`api_constants.dart` is shared, so these live in the feature).
class AdminEndpoints {
  static const dashboard = '/admin/dashboard';
  static const teams = '/admin/teams';
  static const competitions = '/admin/competitions';
  static const fields = '/admin/fields';
  static const plansAll = '/admin/plans';
  static const plans = '/plans';
  static String planImage(int id) => '/plans/$id/image';
  static const calendar = '/calendar';
}

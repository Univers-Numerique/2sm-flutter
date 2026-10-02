class ApiConstants {
  // Adresse de l'API, choisie à la compilation :
  //   production (par défaut)  : https://2sm.fun/api
  //   développement local      : flutter run --dart-define=API_BASE_URL=http://127.0.0.1:9000/api
  //   (10.0.2.2 au lieu de 127.0.0.1 pour l'émulateur Android, l'IP du PC pour un téléphone)
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://2sm.fun/api');

  /// Host serving uploaded files (`php artisan storage:link` exposes
  /// `storage/app/public` under `/storage`). The API returns relative paths
  /// such as `avatars/admin.jpg` — see `mediaUrl()` in shared/utils.
  static String get mediaBaseUrl => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  static const int connectionTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String currentUser = '/auth/user';
  static const String resendOtp = '/auth/resend-otp';
  static const String verifyPhone = '/auth/verify-phone';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String requestContactChange = '/auth/request-contact-change';
  static const String confirmContactChange = '/auth/confirm-contact-change';

  // Users
  static const String users = '/users';
  static String userById(int id) => '/users/$id';
  static String userAvatar(int id) => '/users/$id/avatar';
  static String userChangePassword(int id) => '/users/$id/change-password';
  static String userPositions(int id) => '/users/$id/positions';
  static String userPerformances(int id) => '/users/$id/performances';
  static String userStatistics(int id) => '/users/$id/statistics';

  // Teams
  static const String teams = '/teams';
  static String teamById(int id) => '/teams/$id';
  static String teamMembers(int id) => '/teams/$id/members';
  static String teamStatistics(int id) => '/teams/$id/statistics';
  static String teamLogo(int id) => '/teams/$id/logo';

  // Competitions
  static const String competitions = '/competitions';
  static String competitionById(int id) => '/competitions/$id';
  static String competitionRegister(int id) => '/competitions/$id/register';
  static String competitionRankings(int id) => '/competitions/$id/rankings';
  static String competitionGenerateFixtures(int id) => '/competitions/$id/generate-fixtures';
  static String competitionClearMatches(int id) => '/competitions/$id/matches';
  static String competitionTeamSelection(int competitionId, int teamId) =>
      '/competitions/$competitionId/teams/$teamId/selection';
  static String competitionPhoto(int id) => '/competitions/$id/photo';

  // Matches
  static const String matches = '/matches';
  static const String liveMatches = '/matches/live';
  static String matchById(int id) => '/matches/$id';
  static String matchStart(int id) => '/matches/$id/start';
  static String matchEnd(int id) => '/matches/$id/end';
  static String matchEvents(int id) => '/matches/$id/events';
  static String matchEventById(int matchId, int eventId) => '/matches/$matchId/events/$eventId';

  // News
  static const String news = '/news';
  static String newsById(int id) => '/news/$id';
  static String newsLike(int id) => '/news/$id/like';
  static String newsComments(int id) => '/news/$id/comments';

  // Messages / conversations
  static const String messages = '/messages';
  static String messageById(int id) => '/messages/$id';
  static String messageRead(int id) => '/messages/$id/read';
  static const String conversations = '/conversations';
  static String conversationById(int id) => '/conversations/$id';
  static String conversationUsers(int id) => '/conversations/$id/users';
  static String conversationMessages(int id) => '/conversations/$id/messages';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationById(int id) => '/notifications/$id';
  static String notificationRead(int id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  // Activities
  static const String activities = '/activities';
  static const String myActivities = '/activities/my';
  static String activityById(int id) => '/activities/$id';
  static String activityJoin(int id) => '/activities/$id/join';
  static String activityAttendance(int id) => '/activities/$id/attendance';
  static String activityTasks(int id) => '/activities/$id/tasks';
  static String taskById(int id) => '/tasks/$id';
  static String taskStatus(int id) => '/tasks/$id/status';

  // Fields
  static const String fields = '/fields';
  static const String fieldsNearby = '/fields/nearby';
  static const String fieldsDefault = '/fields/default';
  static String fieldById(int id) => '/fields/$id';
  static String fieldPhoto(int id) => '/fields/$id/photo';

  // Propositions (match invites)
  static const String propositions = '/propositions';
  static String propositionById(int id) => '/propositions/$id';

  // Follow / subscribe
  static const String follow = '/follow';
  static const String followStatus = '/follow/status';

  // Media
  static const String media = '/media';
  static String mediaLike(int id) => '/media/$id/like';

  // Plans (subscriptions)
  static const String plans = '/plans';

  // Settings
  static const String settings = '/settings';

  // Admin
  static const String adminStats = '/stats';
  static const String adminUsers = '/admin/users';
  static String adminUserStatus(int id) => '/admin/users/$id/status';
  static String adminTeamStatus(int id) => '/admin/teams/$id/status';
  static String adminCompetitionStatus(int id) => '/admin/competitions/$id/status';
  static String adminFieldStatus(int id) => '/admin/fields/$id/status';
  static const String adminAdmins = '/admin/admins';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String currentUserJson = 'current_user_json';
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
}

class AppConstants {
  static const String appName = '2SM';
  static const String appFullName = 'Sports Space Management';
  static const int defaultPageSize = 20;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 32;
}

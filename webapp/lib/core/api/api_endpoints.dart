class ApiEndpoints {
  // Base paths
  static const String api = '/api';

  // Authentication
  static const String login = '$api/auth/login';
  static const String register = '$api/auth/register';
  static const String logout = '$api/auth/logout';
  static const String refreshToken = '$api/auth/refresh';

  // Devices
  static const String devices = '$api/devices';
  static String device(String id) => '$devices/$id';
  static String deviceCommand(String id) => '$devices/$id/command';
  static String deviceSettings(String id) => '$devices/$id/settings';
  static String deviceShare(String id) => '$devices/$id/share';
  static String deviceUnshare(String id, String userId) => '$devices/$id/share/$userId';

  // Events
  static const String events = '$api/events';
  static String event(String id) => '$events/$id';
  static String eventsByDevice(String deviceId) => '$events?device_id=$deviceId';
  static String eventMarkRead(String id) => '$events/$id/mark_read';

  // Videos
  static const String videos = '$api/videos';
  static String video(String id) => '$videos/$id';
  static String videoDownload(String id) => '$videos/$id/download';
  static String videosByDevice(String deviceId) => '$videos?device_id=$deviceId';

  // Sensors
  static const String sensorReadings = '$api/sensors/readings';
  static String sensorReadingsByDevice(String deviceId) =>
      '$sensorReadings?device_id=$deviceId';
  static String sensorReadingsExport(String deviceId, String startDate, String endDate) =>
      '$sensorReadings/export?device_id=$deviceId&start_date=$startDate&end_date=$endDate';

  // Analytics
  static const String analytics = '$api/analytics';
  static const String deviceMetrics = '$analytics/device_metrics';
  static String deviceMetricsByDevice(String deviceId) =>
      '$deviceMetrics?device_id=$deviceId';

  // Notifications
  static const String notifications = '$api/notifications';
  static String notification(String id) => '$notifications/$id';
  static const String notificationMarkRead = '$notifications/mark_read';
  static const String notificationMarkAllRead = '$notifications/mark_all_read';

  // Profile
  static const String profile = '$api/users/me';
  static const String updateProfile = '$api/users/me';
  static const String changePassword = '$api/users/me/password';

  // Subscriptions
  static const String subscriptions = '$api/subscriptions';
  static String subscription(String id) => '$subscriptions/$id';
  static const String subscriptionUsage = '$subscriptions/usage';

  // Activity
  static const String activityLogs = '$api/activity_logs';

  // Health check
  static const String health = '/health';
}

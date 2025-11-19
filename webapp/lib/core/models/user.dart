import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? timezone,
    Map<String, dynamic>? preferences,
    required DateTime createdAt,
    DateTime? lastLoginAt,
    Subscription? subscription,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// User preferences
@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    // Notification settings
    @Default(true) bool emailNotifications,
    @Default(true) bool pushNotifications,
    @Default(true) bool motionAlerts,
    @Default(true) bool soundAlerts,
    @Default(true) bool cryAlerts,
    @Default(true) bool systemAlerts,
    @Default(false) bool dailyDigest,

    // Display settings
    @Default('system') String themeMode, // 'light', 'dark', 'system'
    @Default('en') String language,
    @Default('12h') String timeFormat, // '12h', '24h'
    @Default('fahrenheit') String temperatureUnit, // 'celsius', 'fahrenheit'

    // Privacy settings
    @Default(true) bool shareAnalytics,
    @Default(false) bool shareLocationData,

    // Video settings
    @Default(true) bool autoplayVideos,
    @Default('medium') String videoQuality, // 'low', 'medium', 'high', 'auto'
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}

// Subscription model
@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String userId,
    required String tier,
    required String status,
    int? deviceLimit,
    int? storageGb,
    int? retentionDays,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    bool? cancelAtPeriodEnd,
    required DateTime createdAt,
    DateTime? canceledAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);
}

// Subscription tiers
class SubscriptionTiers {
  static const String free = 'free';
  static const String basic = 'basic';
  static const String pro = 'pro';
  static const String family = 'family';

  static List<String> get all => [free, basic, pro, family];

  static String getDisplayName(String tier) {
    switch (tier) {
      case free:
        return 'Free';
      case basic:
        return 'Basic';
      case pro:
        return 'Pro';
      case family:
        return 'Family';
      default:
        return tier;
    }
  }

  static Map<String, dynamic> getFeatures(String tier) {
    switch (tier) {
      case free:
        return {
          'devices': 1,
          'storage': 1, // GB
          'retention': 7, // days
          'features': ['Basic monitoring', 'Live view', '7-day history'],
        };
      case basic:
        return {
          'devices': 2,
          'storage': 10, // GB
          'retention': 30, // days
          'features': [
            'Basic monitoring',
            'Live view',
            '30-day history',
            'Motion detection',
            'Email alerts',
          ],
        };
      case pro:
        return {
          'devices': 5,
          'storage': 50, // GB
          'retention': 90, // days
          'features': [
            'All Basic features',
            'Cry detection',
            'Advanced analytics',
            'Priority support',
            'CSV export',
          ],
        };
      case family:
        return {
          'devices': 10,
          'storage': 200, // GB
          'retention': 365, // days
          'features': [
            'All Pro features',
            'Unlimited users',
            'Family sharing',
            '24/7 support',
            'Custom integrations',
          ],
        };
      default:
        return {};
    }
  }
}

// Subscription status
class SubscriptionStatus {
  static const String active = 'active';
  static const String canceled = 'canceled';
  static const String expired = 'expired';
  static const String trialing = 'trialing';
  static const String pastDue = 'past_due';

  static List<String> get all => [active, canceled, expired, trialing, pastDue];

  static String getDisplayName(String status) {
    switch (status) {
      case active:
        return 'Active';
      case canceled:
        return 'Canceled';
      case expired:
        return 'Expired';
      case trialing:
        return 'Trial';
      case pastDue:
        return 'Past Due';
      default:
        return status;
    }
  }
}

// Usage stats
@freezed
class UsageStats with _$UsageStats {
  const factory UsageStats({
    required int devicesUsed,
    required int deviceLimit,
    required int storageUsedBytes,
    required int storageLimitBytes,
    required int videosCount,
    required int eventsCount,
  }) = _UsageStats;

  const UsageStats._();

  factory UsageStats.fromJson(Map<String, dynamic> json) => _$UsageStatsFromJson(json);

  // Helper methods
  double get storageUsedPercent => (storageUsedBytes / storageLimitBytes) * 100;

  String getFormattedStorageUsed() {
    return _formatBytes(storageUsedBytes);
  }

  String getFormattedStorageLimit() {
    return _formatBytes(storageLimitBytes);
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }
}

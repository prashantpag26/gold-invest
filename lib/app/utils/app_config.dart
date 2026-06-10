/// App-wide environment configuration. Replaces the top-level
/// `kUseCloudFunctions` constant and supports multiple build flavors.
class AppConfig {
  AppConfig._({
    required this.envName,
    required this.useCloudFunctions,
    required this.bypassApproval,
  });

  factory AppConfig.dev() => AppConfig._(
        envName: 'development',
        useCloudFunctions: false,
        bypassApproval: true,
      );

  factory AppConfig.staging() => AppConfig._(
        envName: 'staging',
        useCloudFunctions: true,
        bypassApproval: false,
      );

  factory AppConfig.prod() => AppConfig._(
        envName: 'production',
        useCloudFunctions: true,
        bypassApproval: false,
      );

  final String envName;

  /// When true, admin actions route through callable Cloud Functions (Blaze
  /// plan required). When false, client-side repository writes are used,
  /// guarded by Firestore security rules (works on free Spark plan).
  final bool useCloudFunctions;

  /// When true (dev only), skip the admin-approval gate so any registered
  /// user can access all screens without waiting for admin approval.
  final bool bypassApproval;

  bool get isDev => envName == 'development';
  bool get isProd => envName == 'production';
}

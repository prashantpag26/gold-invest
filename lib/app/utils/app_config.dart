/// App-wide environment configuration. Replaces the top-level
/// `kUseCloudFunctions` constant and supports multiple build flavors.
class AppConfig {
  AppConfig._({
    required this.envName,
    required this.useCloudFunctions,
  });

  factory AppConfig.dev() => AppConfig._(
        envName: 'development',
        useCloudFunctions: false,
      );

  factory AppConfig.staging() => AppConfig._(
        envName: 'staging',
        useCloudFunctions: true,
      );

  factory AppConfig.prod() => AppConfig._(
        envName: 'production',
        useCloudFunctions: true,
      );

  final String envName;

  /// When true, admin actions route through callable Cloud Functions (Blaze
  /// plan required). When false, client-side repository writes are used,
  /// guarded by Firestore security rules (works on free Spark plan).
  final bool useCloudFunctions;

  bool get isDev => envName == 'development';
  bool get isProd => envName == 'production';
}

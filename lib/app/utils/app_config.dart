/// App-wide environment configuration. Replaces the top-level
/// `kUseCloudFunctions` constant and supports multiple build flavors.
class AppConfig {
  AppConfig._({
    required this.envName,
    required this.useCloudFunctions,
    required this.bypassApproval,
    required this.bootstrapAdminEmails,
  });

  factory AppConfig.dev() => AppConfig._(
        envName: 'development',
        useCloudFunctions: false,
        bypassApproval: true,
        // This email is auto-promoted to admin on first login.
        // The app writes role=admin + status=approved to Firestore directly.
        bootstrapAdminEmails: const ['pag.goswami@gmail.com'],
      );

  factory AppConfig.staging() => AppConfig._(
        envName: 'staging',
        useCloudFunctions: true,
        bypassApproval: false,
        bootstrapAdminEmails: const [],
      );

  factory AppConfig.prod() => AppConfig._(
        envName: 'production',
        useCloudFunctions: true,
        bypassApproval: false,
        bootstrapAdminEmails: const [],
      );

  final String envName;

  /// When true, admin actions route through callable Cloud Functions (Blaze
  /// plan required). When false, client-side repository writes are used,
  /// guarded by Firestore security rules (works on free Spark plan).
  final bool useCloudFunctions;

  /// When true (dev only), skip the admin-approval gate so any registered
  /// user can access all screens without waiting for admin approval.
  final bool bypassApproval;

  /// Emails that are auto-promoted to admin role on first login.
  /// The app writes role=admin + status=approved to Firestore directly,
  /// so no CLI or Admin SDK is required.
  /// Keep empty in staging/prod — use set_admin.js for production admins.
  final List<String> bootstrapAdminEmails;

  bool get isDev => envName == 'development';
  bool get isProd => envName == 'production';

  bool isBootstrapAdmin(String? email) =>
      email != null && bootstrapAdminEmails.contains(email.toLowerCase().trim());
}

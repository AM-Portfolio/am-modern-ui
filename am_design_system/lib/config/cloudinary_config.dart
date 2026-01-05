/// Configuration for Cloudinary cloud storage service
class CloudinaryConfig {
  // Optional: For unsigned uploads

  const CloudinaryConfig({required this.cloudName, required this.apiKey, required this.apiSecret, this.uploadPreset});

  /// Load from environment variables
  ///
  /// Set these in your .env file or build configuration:
  /// - CLOUDINARY_CLOUD_NAME
  /// - CLOUDINARY_API_KEY
  /// - CLOUDINARY_API_SECRET
  factory CloudinaryConfig.fromEnv() => const CloudinaryConfig(
    cloudName: String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'demo'),
    apiKey: String.fromEnvironment('CLOUDINARY_API_KEY'),
    apiSecret: String.fromEnvironment('CLOUDINARY_API_SECRET'),
    uploadPreset: String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET'),
  );

  /// For development/testing (replace with your credentials)
  factory CloudinaryConfig.development() =>
      const CloudinaryConfig(cloudName: 'your-cloud-name', apiKey: 'your-api-key', apiSecret: 'your-api-secret');
  final String cloudName;
  final String apiKey;
  final String apiSecret;
  final String? uploadPreset;

  /// Validate configuration
  bool get isValid => cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;
}

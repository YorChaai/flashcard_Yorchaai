import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class FontSizeSettings {
  // PC/Desktop settings
  final double pcMainFontSize;
  final double pcSubFontSize;

  // Mobile/HP settings
  final double mobileMainFontSize;
  final double mobileSubFontSize;

  FontSizeSettings({
    this.pcMainFontSize = 40.0,
    this.pcSubFontSize = 8.0,
    this.mobileMainFontSize = 32.0,
    this.mobileSubFontSize = 10.0,
  });

  /// Detect if current platform is mobile (Android/iOS)
  static bool isMobilePlatform() {
    // Web is not mobile
    if (kIsWeb) return false;

    // Check mobile platforms
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Get current platform label for UI display
  static String getCurrentPlatformLabel() {
    if (isMobilePlatform()) return 'Mobile/HP';
    return 'PC/Desktop';
  }

  /// Get main font size for current platform
  double get currentMainFontSize => isMobilePlatform() ? mobileMainFontSize : pcMainFontSize;

  /// Get sub font size for current platform
  double get currentSubFontSize => isMobilePlatform() ? mobileSubFontSize : pcSubFontSize;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'pcMainFontSize': pcMainFontSize,
      'pcSubFontSize': pcSubFontSize,
      'mobileMainFontSize': mobileMainFontSize,
      'mobileSubFontSize': mobileSubFontSize,
    };
  }

  /// Create from JSON
  factory FontSizeSettings.fromJson(Map<String, dynamic> json) {
    return FontSizeSettings(
      pcMainFontSize: (json['pcMainFontSize'] as num?)?.toDouble() ?? 40.0,
      pcSubFontSize: (json['pcSubFontSize'] as num?)?.toDouble() ?? 8.0,
      mobileMainFontSize: (json['mobileMainFontSize'] as num?)?.toDouble() ?? 32.0,
      mobileSubFontSize: (json['mobileSubFontSize'] as num?)?.toDouble() ?? 10.0,
    );
  }

  /// Create a copy with updated values
  FontSizeSettings copyWith({
    double? pcMainFontSize,
    double? pcSubFontSize,
    double? mobileMainFontSize,
    double? mobileSubFontSize,
  }) {
    return FontSizeSettings(
      pcMainFontSize: pcMainFontSize ?? this.pcMainFontSize,
      pcSubFontSize: pcSubFontSize ?? this.pcSubFontSize,
      mobileMainFontSize: mobileMainFontSize ?? this.mobileMainFontSize,
      mobileSubFontSize: mobileSubFontSize ?? this.mobileSubFontSize,
    );
  }
}

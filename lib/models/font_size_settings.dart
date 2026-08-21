import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class FontSizeSettings {
  // PC/Desktop settings
  final double pcFontSize1;
  final double pcFontSize23;
  final double pcFontSize45;
  final double pcFontSize6;

  // Mobile/HP settings
  final double mobileFontSize1;
  final double mobileFontSize23;
  final double mobileFontSize45;
  final double mobileFontSize6;

  FontSizeSettings({
    this.pcFontSize1 = 40.0,
    this.pcFontSize23 = 16.0,
    this.pcFontSize45 = 12.0,
    this.pcFontSize6 = 12.0,
    this.mobileFontSize1 = 32.0,
    this.mobileFontSize23 = 14.0,
    this.mobileFontSize45 = 10.0,
    this.mobileFontSize6 = 10.0,
  });

  /// Detect if current platform is mobile (Android/iOS)
  static bool isMobilePlatform() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String getCurrentPlatformLabel() {
    if (isMobilePlatform()) return 'Mobile/HP';
    return 'PC/Desktop';
  }

  double get currentFontSize1 => isMobilePlatform() ? mobileFontSize1 : pcFontSize1;
  double get currentFontSize23 => isMobilePlatform() ? mobileFontSize23 : pcFontSize23;
  double get currentFontSize45 => isMobilePlatform() ? mobileFontSize45 : pcFontSize45;
  double get currentFontSize6 => isMobilePlatform() ? mobileFontSize6 : pcFontSize6;

  Map<String, dynamic> toJson() {
    return {
      'pcFontSize1': pcFontSize1,
      'pcFontSize23': pcFontSize23,
      'pcFontSize45': pcFontSize45,
      'pcFontSize6': pcFontSize6,
      'mobileFontSize1': mobileFontSize1,
      'mobileFontSize23': mobileFontSize23,
      'mobileFontSize45': mobileFontSize45,
      'mobileFontSize6': mobileFontSize6,
    };
  }

  factory FontSizeSettings.fromJson(Map<String, dynamic> json) {
    // Also support fallback to old format
    return FontSizeSettings(
      pcFontSize1: (json['pcFontSize1'] ?? json['pcMainFontSize'] as num?)?.toDouble() ?? 40.0,
      pcFontSize23: (json['pcFontSize23'] ?? json['pcSubFontSize'] as num?)?.toDouble() ?? 16.0,
      pcFontSize45: (json['pcFontSize45'] ?? json['pcSubFontSize'] as num?)?.toDouble() ?? 12.0,
      pcFontSize6: (json['pcFontSize6'] ?? json['pcSubFontSize'] as num?)?.toDouble() ?? 12.0,
      mobileFontSize1: (json['mobileFontSize1'] ?? json['mobileMainFontSize'] as num?)?.toDouble() ?? 32.0,
      mobileFontSize23: (json['mobileFontSize23'] ?? json['mobileSubFontSize'] as num?)?.toDouble() ?? 14.0,
      mobileFontSize45: (json['mobileFontSize45'] ?? json['mobileSubFontSize'] as num?)?.toDouble() ?? 10.0,
      mobileFontSize6: (json['mobileFontSize6'] ?? json['mobileSubFontSize'] as num?)?.toDouble() ?? 10.0,
    );
  }

  FontSizeSettings copyWith({
    double? pcFontSize1,
    double? pcFontSize23,
    double? pcFontSize45,
    double? pcFontSize6,
    double? mobileFontSize1,
    double? mobileFontSize23,
    double? mobileFontSize45,
    double? mobileFontSize6,
  }) {
    return FontSizeSettings(
      pcFontSize1: pcFontSize1 ?? this.pcFontSize1,
      pcFontSize23: pcFontSize23 ?? this.pcFontSize23,
      pcFontSize45: pcFontSize45 ?? this.pcFontSize45,
      pcFontSize6: pcFontSize6 ?? this.pcFontSize6,
      mobileFontSize1: mobileFontSize1 ?? this.mobileFontSize1,
      mobileFontSize23: mobileFontSize23 ?? this.mobileFontSize23,
      mobileFontSize45: mobileFontSize45 ?? this.mobileFontSize45,
      mobileFontSize6: mobileFontSize6 ?? this.mobileFontSize6,
    );
  }
}

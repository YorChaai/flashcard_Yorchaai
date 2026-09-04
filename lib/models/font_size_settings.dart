import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class FontSizeSettings {
  // PC/Desktop settings
  final double pcFontSize1;
  final double pcFontSize2_5;
  final double pcFontSize6_9;
  final double pcFontSize10_12;

  // Mobile/HP settings
  final double mobileFontSize1;
  final double mobileFontSize2_5;
  final double mobileFontSize6_9;
  final double mobileFontSize10_12;

  FontSizeSettings({
    this.pcFontSize1 = 40.0,
    this.pcFontSize2_5 = 16.0,
    this.pcFontSize6_9 = 13.0,
    this.pcFontSize10_12 = 11.0,
    this.mobileFontSize1 = 32.0,
    this.mobileFontSize2_5 = 14.0,
    this.mobileFontSize6_9 = 11.0,
    this.mobileFontSize10_12 = 9.5,
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
  double get currentFontSize2_5 => isMobilePlatform() ? mobileFontSize2_5 : pcFontSize2_5;
  double get currentFontSize6_9 => isMobilePlatform() ? mobileFontSize6_9 : pcFontSize6_9;
  double get currentFontSize10_12 => isMobilePlatform() ? mobileFontSize10_12 : pcFontSize10_12;

  // Backward compatibility getters
  double get currentFontSize23 => currentFontSize2_5;
  double get currentFontSize45 => currentFontSize2_5;
  double get currentFontSize6 => currentFontSize6_9;

  Map<String, dynamic> toJson() {
    return {
      'pcFontSize1': pcFontSize1,
      'pcFontSize2_5': pcFontSize2_5,
      'pcFontSize6_9': pcFontSize6_9,
      'pcFontSize10_12': pcFontSize10_12,
      'mobileFontSize1': mobileFontSize1,
      'mobileFontSize2_5': mobileFontSize2_5,
      'mobileFontSize6_9': mobileFontSize6_9,
      'mobileFontSize10_12': mobileFontSize10_12,
    };
  }

  factory FontSizeSettings.fromJson(Map<String, dynamic> json) {
    return FontSizeSettings(
      pcFontSize1: (json['pcFontSize1'] ?? json['pcMainFontSize'] as num?)?.toDouble() ?? 40.0,
      pcFontSize2_5: (json['pcFontSize2_5'] ?? json['pcFontSize23'] ?? json['pcSubFontSize'] as num?)?.toDouble() ?? 16.0,
      pcFontSize6_9: (json['pcFontSize6_9'] ?? json['pcFontSize45'] ?? json['pcSubFontSize'] as num?)?.toDouble() ?? 13.0,
      pcFontSize10_12: (json['pcFontSize10_12'] ?? json['pcFontSize6'] ?? json['pcSubFontSize'] as num?)?.toDouble() ?? 11.0,
      mobileFontSize1: (json['mobileFontSize1'] ?? json['mobileMainFontSize'] as num?)?.toDouble() ?? 32.0,
      mobileFontSize2_5: (json['mobileFontSize2_5'] ?? json['mobileFontSize23'] ?? json['mobileSubFontSize'] as num?)?.toDouble() ?? 14.0,
      mobileFontSize6_9: (json['mobileFontSize6_9'] ?? json['mobileFontSize45'] ?? json['mobileSubFontSize'] as num?)?.toDouble() ?? 11.0,
      mobileFontSize10_12: (json['mobileFontSize10_12'] ?? json['mobileFontSize6'] ?? json['mobileSubFontSize'] as num?)?.toDouble() ?? 9.5,
    );
  }

  FontSizeSettings copyWith({
    double? pcFontSize1,
    double? pcFontSize2_5,
    double? pcFontSize6_9,
    double? pcFontSize10_12,
    double? mobileFontSize1,
    double? mobileFontSize2_5,
    double? mobileFontSize6_9,
    double? mobileFontSize10_12,
  }) {
    return FontSizeSettings(
      pcFontSize1: pcFontSize1 ?? this.pcFontSize1,
      pcFontSize2_5: pcFontSize2_5 ?? this.pcFontSize2_5,
      pcFontSize6_9: pcFontSize6_9 ?? this.pcFontSize6_9,
      pcFontSize10_12: pcFontSize10_12 ?? this.pcFontSize10_12,
      mobileFontSize1: mobileFontSize1 ?? this.mobileFontSize1,
      mobileFontSize2_5: mobileFontSize2_5 ?? this.mobileFontSize2_5,
      mobileFontSize6_9: mobileFontSize6_9 ?? this.mobileFontSize6_9,
      mobileFontSize10_12: mobileFontSize10_12 ?? this.mobileFontSize10_12,
    );
  }
}

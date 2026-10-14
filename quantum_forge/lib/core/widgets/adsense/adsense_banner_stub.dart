import 'package:flutter/material.dart';

/// Desktop/Mobile/Test fallback for Google AdSense banner view.
Widget buildPlatformAdSenseBanner({
  required String adClient,
  String? adSlot,
  required String adFormat,
  required bool fullWidthResponsive,
  required String viewIdSuffix,
  void Function(bool isFilled)? onStatusChanged,
}) {
  return const SizedBox.shrink();
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/adsense_config.dart';
import 'adsense/adsense_banner_platform.dart';

/// Reusable Google AdSense banner widget designed for Flutter Web.
///
/// Monetizes unauthenticated / free-tier researchers while strictly preserving
/// responsive mobile and desktop layouts and visual space:
///
/// 1. Authenticated / Pro users (`isProUser: true` or `isSignedIn: true`) see
///    `const SizedBox.shrink()` (zero ads, zero DOM/CPU overhead).
/// 2. Non-web platforms (`kIsWeb == false`) safely fall back to an empty widget.
/// 3. Visual protection:
///    - If the ad is unfilled, rejected, or unconfigured in production, it
///      collapses to `SizedBox.shrink()` so it never blocks or occupies empty
///      visual space.
///    - Includes an integrated dismiss button allowing users to collapse the
///      banner at any time so it never covers visual content.
///    - Placed inside [SafeArea] with responsive height bounds.
class AdSenseBannerWeb extends StatefulWidget {
  /// When true, user has pro/researcher status and ads are completely hidden.
  final bool isProUser;

  /// When true, user is authenticated and ads are completely hidden.
  final bool isSignedIn;

  /// Google AdSense publisher client ID (defaults to [AdSenseConfig.publisherId]).
  final String adClient;

  /// Optional specific AdSense ad unit slot ID.
  final String? adSlot;

  /// Ad layout format (defaults to 'auto').
  final String adFormat;

  /// Full-width responsive AdSense flag.
  final bool fullWidthResponsive;

  /// Placement identifier used to distinguish distinct ad containers.
  final String placement;

  /// Banner height in logical pixels. Defaults to 90.0 (standard leaderboard).
  final double height;

  /// Maximum constrained width. Defaults to 970.0 (IAB standard leaderboard).
  final double maxWidth;

  /// Outer padding for spacing and avoiding floating action buttons or nav bars.
  final EdgeInsetsGeometry padding;

  /// Optional flag to show or hide the subtle "ADVERTISEMENT" badge.
  final bool showSponsoredLabel;

  /// Whether the user can manually dismiss/close the banner.
  final bool dismissible;

  /// When true, renders the container and platform stub even when `!kIsWeb`
  /// (primarily for responsive layout testing on non-web test runners).
  final bool forceRenderInTest;

  const AdSenseBannerWeb({
    super.key,
    this.isProUser = false,
    this.isSignedIn = false,
    this.adClient = AdSenseConfig.publisherId,
    this.adSlot,
    this.adFormat = 'auto',
    this.fullWidthResponsive = true,
    this.placement = 'default',
    this.height = 90.0,
    this.maxWidth = 970.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.showSponsoredLabel = true,
    this.dismissible = true,
    this.forceRenderInTest = false,
  });

  @override
  State<AdSenseBannerWeb> createState() => _AdSenseBannerWebState();
}

class _AdSenseBannerWebState extends State<AdSenseBannerWeb> {
  bool _isDismissed = false;
  bool _isCollapsed = false;

  void _handleAdStatus(bool isFilled) {
    if (!mounted) return;
    setState(() {
      _isCollapsed = !isFilled;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Pro or signed-in researchers see zero ads
    if (widget.isProUser || widget.isSignedIn) {
      return const SizedBox.shrink();
    }

    // 2. User dismissed the ad to free up visual space
    if (_isDismissed || _isCollapsed) {
      return const SizedBox.shrink();
    }

    // 3. Safe empty widget fallback on non-web platforms (unless in tests)
    if (!kIsWeb && !widget.forceRenderInTest) {
      return const SizedBox.shrink();
    }

    // 4. In production web, if publisher ID is unconfigured placeholder,
    // collapse to prevent blocking visuals with empty frames.
    if (kIsWeb && !AdSenseConfig.isConfigured && !widget.forceRenderInTest) {
      return const SizedBox.shrink();
    }

    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final effectiveHeight = isMobile ? widget.height.clamp(50.0, 90.0) : widget.height;

    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: widget.padding,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.maxWidth,
              minHeight: effectiveHeight,
            ),
            child: Container(
              width: double.infinity,
              height: effectiveHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: buildPlatformAdSenseBanner(
                      adClient: widget.adClient,
                      adSlot: widget.adSlot,
                      adFormat: widget.adFormat,
                      fullWidthResponsive: widget.fullWidthResponsive,
                      viewIdSuffix: '${widget.placement}-${widget.adSlot ?? "auto"}',
                      onStatusChanged: _handleAdStatus,
                    ),
                  ),
                  if (widget.showSponsoredLabel)
                    Positioned(
                      top: 4,
                      right: 8,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADVERTISEMENT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.dismissible)
                    Positioned(
                      top: 4,
                      left: 6,
                      child: Tooltip(
                        message: 'Hide ad',
                        child: InkWell(
                          onTap: () => setState(() => _isDismissed = true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

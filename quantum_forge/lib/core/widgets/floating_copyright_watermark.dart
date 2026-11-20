// ============================================================================
// Floating Copyright Watermark & Legal Protection Badge
// Copyright (c) 2026 Dart Nexus Lab <eliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/services/app_route_observer.dart';

/// A floating, non-intrusive copyright watermark positioned at the bottom of the
/// viewport. Wraps its visual tree in [IgnorePointer] so touch, mouse, scroll,
/// and click events pass through unobstructed to underlying widgets.
class FloatingCopyrightWatermark extends StatelessWidget {
  const FloatingCopyrightWatermark({super.key});

  static const String ownerName = 'Dart Nexus Lab';
  static const String ownerEmail = 'eliasgharinnocent@yahoo.com';
  static const String appTitle = 'Quantum Forge';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isMobile = !kIsWeb && media.size.width < 600;
    final currentRoute = AppRouteObserver.lastActiveRoute;
    final isRootDashboard =
        currentRoute == null || currentRoute == '/' || currentRoute == 'null';
    final hasBottomNav = isMobile && isRootDashboard;
    final bottomOffset = hasBottomNav
        ? kBottomNavigationBarHeight + media.padding.bottom + 4.0
        : (media.padding.bottom > 0 ? media.padding.bottom + 4.0 : 6.0);

    return Positioned(
      bottom: bottomOffset,
      right: isMobile ? 8 : 16,
      left: isMobile ? 8 : 16,
      child: IgnorePointer(
        ignoring: true,
        child: Align(
          alignment: Alignment.bottomRight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final String textContent;
              if (width >= 620 && !isMobile) {
                textContent =
                    '$appTitle — A Product of $ownerName · $ownerEmail · DMCA Protected';
              } else if (width >= 400 || !isMobile) {
                textContent = '$appTitle — $ownerName · $ownerEmail';
              } else {
                textContent = '© $ownerName · $ownerEmail';
              }

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 7 : 12,
                  vertical: isMobile ? 2.5 : 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: isMobile ? 0.60 : 0.75),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 9.5,
                      color: Color(0xFF00BFA5),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        textContent,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: isMobile ? 8.5 : 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

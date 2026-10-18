// ============================================================================
// Floating Copyright Watermark & Legal Protection Badge
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';

/// A floating, non-intrusive copyright watermark positioned at the bottom of the
/// viewport. Wraps its visual tree in [IgnorePointer] so touch, mouse, scroll,
/// and click events pass through unobstructed to underlying widgets.
class FloatingCopyrightWatermark extends StatelessWidget {
  const FloatingCopyrightWatermark({super.key});

  static const String ownerName = 'Ali Asghar';
  static const String ownerEmail = 'aliasgharinnocent@yahoo.com';
  static const String appTitle = 'Quantum Forge';

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      left: 12,
      right: 12,
      child: Center(
        child: IgnorePointer(
          ignoring: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final String textContent;
              if (width >= 620) {
                textContent =
                    '$appTitle © $ownerName · $ownerEmail · All Rights Reserved · DMCA Protected';
              } else if (width >= 400) {
                textContent = '$appTitle © $ownerName · $ownerEmail';
              } else {
                textContent = '© $ownerName · $ownerEmail';
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 11,
                      color: Color(0xFF00BFA5),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        textContent,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.25,
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

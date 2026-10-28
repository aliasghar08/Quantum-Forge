// ============================================================================
// Locked Animation Placeholder
//
// Displayed in place of 3D trajectory animations and molecular geometry viewers
// when an unauthenticated guest views a shared reaction link.
// Provides standard Sign In / Register navigation to unlock animations.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/screens/auth_screen.dart';

class LockedAnimationPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? height;
  final bool compact;
  final VoidCallback? onSignInRequested;
  final VoidCallback? onSignInSuccess;

  const LockedAnimationPlaceholder({
    super.key,
    this.title = '3D Trajectory Animation Locked',
    this.subtitle =
        'This reaction was opened via a shared link. Sign in with your researcher credentials to view interactive 3D trajectory playback.',
    this.height,
    this.compact = false,
    this.onSignInRequested,
    this.onSignInSuccess,
  });

  void _handleSignIn(BuildContext context) {
    if (onSignInRequested != null) {
      onSignInRequested!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => AuthScreen(
          redirectMessage:
              'Sign in to unlock interactive 3D trajectory playback and atomic simulations.',
          onLoginSuccess: () {
            Navigator.of(ctx).pop();
            onSignInSuccess?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = compact;

    return Container(
      height: height ?? (isCompact ? 220 : 380),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 28,
        vertical: isCompact ? 14 : 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D121F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with glowing badge
              Container(
                width: isCompact ? 44 : 62,
                height: isCompact ? 44 : 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      blurRadius: isCompact ? 14 : 22,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: isCompact ? 22 : 30,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: isCompact ? 10 : 16),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 14.5 : 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: isCompact ? 6 : 10),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: isCompact ? 11.5 : 13,
                    height: 1.45,
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 14 : 22),

              // Sign In Button
              FilledButton.icon(
                onPressed: () => _handleSignIn(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black87,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 18 : 26,
                    vertical: isCompact ? 10 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.login_rounded, size: 16),
                label: Text(
                  'Sign In / Register',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 12 : 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

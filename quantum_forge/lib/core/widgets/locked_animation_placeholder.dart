// ============================================================================
// Locked Animation Placeholder
//
// Displayed in place of 3D trajectory animations and molecular geometry viewers
// when an unauthenticated guest views a shared reaction link.
// Provides both standard Sign In / Register navigation and 1-Click Demo Ghost
// authentication to immediately unlock animations in-place.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/services/firebase_auth_service.dart';
import 'package:quantum_forge/features/auth/presentation/screens/auth_screen.dart';

class LockedAnimationPlaceholder extends StatefulWidget {
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
        'This reaction was opened via a shared link. Sign in with your researcher credentials or activate the 1-Click Demo account to view interactive 3D trajectory playback.',
    this.height,
    this.compact = false,
    this.onSignInRequested,
    this.onSignInSuccess,
  });

  @override
  State<LockedAnimationPlaceholder> createState() =>
      _LockedAnimationPlaceholderState();
}

class _LockedAnimationPlaceholderState
    extends State<LockedAnimationPlaceholder> {
  bool _isGhostAuthenticating = false;

  Future<void> _handleGhostSignIn() async {
    setState(() => _isGhostAuthenticating = true);
    try {
      final authService = FirebaseAuthService();
      await authService.signInWithGhostAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧪 Demo Researcher connected — 3D animation unlocked!'),
            backgroundColor: Color(0xFF00B0FF),
            duration: Duration(seconds: 3),
          ),
        );
        widget.onSignInSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not activate demo account: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGhostAuthenticating = false);
      }
    }
  }

  void _handleSignIn() {
    if (widget.onSignInRequested != null) {
      widget.onSignInRequested!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => AuthScreen(
          redirectMessage:
              'Sign in to unlock interactive 3D trajectory playback and atomic simulations.',
          onLoginSuccess: () {
            Navigator.of(ctx).pop();
            widget.onSignInSuccess?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.compact;

    return Container(
      height: widget.height ?? (isCompact ? 220 : 380),
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
                widget.title,
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
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: isCompact ? 11.5 : 13,
                    height: 1.45,
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 14 : 22),

              // Actions
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Sign In Button
                  FilledButton.icon(
                    onPressed: _isGhostAuthenticating ? null : _handleSignIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 16 : 22,
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

                  // 1-Click Ghost Demo Button
                  OutlinedButton.icon(
                    onPressed: _isGhostAuthenticating ? null : _handleGhostSignIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00E5FF),
                      side: BorderSide(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      backgroundColor:
                          const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 14 : 18,
                        vertical: isCompact ? 10 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _isGhostAuthenticating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00E5FF),
                            ),
                          )
                        : const Icon(Icons.science_outlined, size: 16),
                    label: Text(
                      _isGhostAuthenticating
                          ? 'Unlocking...'
                          : '🧪 1-Click Demo Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isCompact ? 11.5 : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

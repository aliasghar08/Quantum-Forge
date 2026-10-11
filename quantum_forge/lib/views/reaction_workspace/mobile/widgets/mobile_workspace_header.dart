import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/reaction_workspace_viewmodel.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../../features/auth/presentation/screens/auth_screen.dart';

class MobileWorkspaceHeader extends StatelessWidget implements PreferredSizeWidget {
  const MobileWorkspaceHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReactionWorkspaceViewModel>();
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      // Firebase not initialized in widget test or offline environment
    }
    final isSignedIn = vm.isSignedIn || currentUser != null;

    return AppBar(
      backgroundColor: const Color(0xFF161B22),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white70),
        onPressed: () {
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold != null && scaffold.hasDrawer) {
            scaffold.openDrawer();
          }
        },
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.blur_on, color: Colors.cyanAccent, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vm.reactionTitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Collapsed Sign In action for mobile header clearance
        IconButton(
          icon: Icon(
            isSignedIn ? Icons.account_circle : Icons.login_rounded,
            color: Colors.cyanAccent,
          ),
          tooltip: isSignedIn ? 'Account' : 'Sign In',
          onPressed: () {
            if (currentUser == null) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (ctx) => AuthScreen(
                    onLoginSuccess: () => Navigator.of(ctx).pop(),
                  ),
                ),
              );
            } else {
              vm.toggleSignIn();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.feedback_outlined, size: 20, color: Colors.white70),
          tooltip: 'Feedback',
          onPressed: () => FeedbackService.showFeedbackDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.white70),
          tooltip: 'Settings',
          onPressed: () => Navigator.of(context).push(SettingsScreen.route()),
        ),
      ],
    );
  }
}

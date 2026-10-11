import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/reaction_workspace_viewmodel.dart';
import 'mobile/reaction_workspace_mobile_view.dart';
import 'desktop/reaction_workspace_desktop_view.dart';

class ReactionWorkspaceScreen extends StatelessWidget {
  const ReactionWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReactionWorkspaceViewModel(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Breakpoint: Mobile screens (< 650px) render dedicated mobile tree
          if (constraints.maxWidth < 650) {
            return const ReactionWorkspaceMobileView();
          }
          return const ReactionWorkspaceDesktopView();
        },
      ),
    );
  }
}

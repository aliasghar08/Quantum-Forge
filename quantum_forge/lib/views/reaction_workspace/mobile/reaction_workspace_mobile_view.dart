import 'package:flutter/material.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import '../../../viewmodels/reaction_workspace_viewmodel.dart';
import 'widgets/mobile_workspace_header.dart';
import 'widgets/mobile_vitals_card.dart';
import 'widgets/mobile_export_sheet.dart';
import 'widgets/mobile_arrhenius_chart.dart';
import '../../../../state/dashboard_viewmodel.dart';
import '../../../../features/reaction_runner/presentation/widgets/dashboard_cards/left_nav_rail.dart';

class ReactionWorkspaceMobileView extends StatelessWidget {
  const ReactionWorkspaceMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReactionWorkspaceViewModel>();

    final dashboardVm = Provider.of<DashboardViewModel?>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: const MobileWorkspaceHeader(),
      drawer: dashboardVm != null
          ? ProfessionalDrawer(
              current: dashboardVm.navDest,
              onDestinationSelected: (d) {
                dashboardVm.setNavDestination(d);
                Navigator.pop(context);
              },
              controlsPanelOpen: dashboardVm.controlsPanelOpen,
              onToggleControls: () {
                dashboardVm.toggleControlsPanel();
              },
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: dashboardVm != null
            ? switch (dashboardVm.navDest) {
                NavDestination.library => 0,
                NavDestination.newReaction => 1,
                NavDestination.editor => 2,
                NavDestination.history => 3,
                _ => 1,
              }
            : 1,
        onTap: (index) {
          if (dashboardVm != null) {
            final dest = switch (index) {
              0 => NavDestination.library,
              1 => NavDestination.newReaction,
              2 => NavDestination.editor,
              3 => NavDestination.history,
              _ => NavDestination.newReaction,
            };
            dashboardVm.setNavDestination(dest);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Reaction',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Editor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status & Accuracy Overview Pill Card
            _buildStatusCard(vm),
            const SizedBox(height: 14),

            // Reaction Title Banner
            _buildReactionBanner(vm),
            const SizedBox(height: 14),

            // Execution Action Button
            ElevatedButton.icon(
              onPressed: vm.isCalculating ? null : vm.executeTsSearch,
              icon: Icon(
                vm.isSignedIn ? Icons.science_outlined : Icons.lock_outline,
                size: 18,
              ),
              label: Text(
                vm.isSignedIn ? 'Execute TS Search' : 'Execute TS Search (Sign In)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.shade700,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // Workspace Parameters (Fixed collision between Header and Settings Link)
            const MobileVitalsCard(),
            const SizedBox(height: 16),

            // Compact 2x2 Grid for Export Actions (Resolves long button stack)
            const MobileExportSheet(),
            const SizedBox(height: 18),

            // Arrhenius Plot Card with mobile-tuned tick interval
            const MobileArrheniusChart(),
            const SizedBox(height: 16),

            // Comprehensive Thermodynamic Properties Grid
            _buildThermodynamicsGrid(vm),
            const SizedBox(height: 32),

            // Safe Non-Overlapping Footer
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Quantum Forge © Ali Asghar · aliasgharinnocent@yahoo.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ReactionWorkspaceViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _statusRow(
            Icons.psychology,
            "Surrogate MLIP",
            "tx1-v2 (5x Ensemble)",
            Colors.cyanAccent,
          ),
          const Divider(color: Colors.white10, height: 16),
          _statusRow(
            Icons.bolt,
            "Barrier Accuracy",
            "2.26 kcal/mol MAE",
            Colors.greenAccent,
          ),
          const Divider(color: Colors.white10, height: 16),
          _statusRow(
            Icons.shield_outlined,
            "Calibrated Error",
            "±1σ & ±2σ Bands",
            Colors.purpleAccent,
          ),
          const Divider(color: Colors.white10, height: 16),
          _statusRow(
            Icons.cloud_done_outlined,
            "Backend",
            "Cloud Run us-central1",
            Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _statusRow(IconData icon, String title, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildReactionBanner(ReactionWorkspaceViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vm.reactionTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TEMPLATE',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            vm.reactionSubtitle,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermodynamicsGrid(ReactionWorkspaceViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comprehensive Thermodynamic Properties',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
          ),
          itemCount: vm.thermodynamicMetrics.length,
          itemBuilder: (context, i) {
            final m = vm.thermodynamicMetrics[i];
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    m.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        m.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: m.accentColor,
                        ),
                      ),
                      if (m.uncertainty != null)
                        Text(
                          ' ${m.uncertainty}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      const SizedBox(width: 3),
                      Text(
                        m.unit,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

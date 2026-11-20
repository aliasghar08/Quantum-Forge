// ============================================================================
// WardRounds 3D: Undifferentiated ER/ICU Clinical Reasoning & POCUS Screen
// ----------------------------------------------------------------------------
// Bedside Emergency Training Engine integrating:
// 1. Undifferentiated Rapid Response Triage (Shock, Respiratory Distress, Coma)
// 2. Interactive Bedside POCUS (RUSH / eFAST) 5-Window Ultrasound Simulator
// 3. Differential Diagnosis (DDx) Ranker & Socratic AI Attending Safety Proctor
// 4. Longitudinal USMLE / MBBS Organ-System Mastery Radar & Auto-Remediation
// 5. Cross-Organ Coupling with CardioCath, NeuroLab, NephroLab, and PulmoVent
//
// Strictly Educational Simulation — 7-Pillar SaMD Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import '../features/clinical_core/presentation/widgets/multi_organ_coupling_pill.dart';
import '../features/ward/data/ward_rounds_engine.dart';
import '../features/ward/presentation/widgets/ward_pocus_simulator_panel.dart';
import '../features/ward/presentation/widgets/ward_ddx_proctor_panel.dart';
import '../features/ward/presentation/widgets/student_mastery_radar_panel.dart';

class WardRoundsScreen extends StatefulWidget {
  final int? initialCaseIndex;

  const WardRoundsScreen({super.key, this.initialCaseIndex});

  static Route<void> route({int? initialCaseIndex}) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: initialCaseIndex != null ? '/ward?case=$initialCaseIndex' : '/ward',
      ),
      builder: (_) => WardRoundsScreen(initialCaseIndex: initialCaseIndex),
    );
  }

  @override
  State<WardRoundsScreen> createState() => _WardRoundsScreenState();
}

class _WardRoundsScreenState extends State<WardRoundsScreen> {
  final WardRoundsEngine _engine = WardRoundsEngine.instance;
  int _mobileTab = 1; // 0: Triage & Exam, 1: POCUS, 2: DDx & Orders, 3: Mastery Radar

  @override
  void initState() {
    super.initState();
    if (widget.initialCaseIndex != null) {
      _engine.loadCase(widget.initialCaseIndex!);
    }
  }

  @override
  void dispose() {
    _engine.stopTimer();
    super.dispose();
  }

  void _showSaMdDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF38BDF8)),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 24),
            SizedBox(width: 8),
            Text(
              'SaMD 7-Pillar Regulatory Shield',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WardRounds 3D is strictly an educational in-silico simulation designed for medical students, pharmacy scholars, and critical care residents.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 10),
              Text(
                '• Pillar 1: Non-Diagnostic / Non-Therapeutic Sandbox\n'
                '• Pillar 2: Synthetic Procedural Geometries (Zero Patient Data)\n'
                '• Pillar 3: Educational Socratic Explanations\n'
                '• Pillar 4: Real-time Contraindication Interception\n'
                '• Pillar 5: Peer-Reviewed Medical Guidelines Reference\n'
                '• Pillar 6: Invariance Mathematical Verification\n'
                '• Pillar 7: Multi-Organ Systems Physiology Coupling\n',
                style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('DISMISS', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  void _showMasteryModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StudentMasteryRadarPanel(
            engine: _engine,
            onNavigateRemediation: (route) {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed(route);
            },
          ),
        ),
      ),
    );
  }

  void _navigateRemediation(String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B11),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Permanent Amber SaMD Legal Shield Banner
            _buildSaMdBanner(),

            // 2. Top Navigation & App Bar
            _buildTopBar(),

            // 3. Bedside Patient Vitals Monitor HUD
            _buildBedsideVitalsHud(),

            // 4. Main Body Content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 1050;
                  if (isDesktop) {
                    return _buildDesktopLayout();
                  }
                  return _buildMobileLayout();
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 1050
          ? _buildMobileBottomBar()
          : null,
    );
  }

  Widget _buildSaMdBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: const Color(0xFFF59E0B),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.black),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Educational Simulation Only — Not for Clinical Diagnosis, Prescribing, or Patient Care',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: _showSaMdDialog,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.black),
                SizedBox(width: 4),
                Text(
                  '7-Pillar Shield',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            tooltip: 'Return to Hub',
          ),
          const SizedBox(width: 4),
          const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WardRounds 3D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Undifferentiated ER/ICU Clinical Reasoning & POCUS',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Case Selector Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _engine.currentCaseIndex,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                        items: List.generate(WardRoundsEngine.allCases.length, (idx) {
                          return DropdownMenuItem<int>(
                            value: idx,
                            child: Text('Case ${idx + 1}: ${WardRoundsEngine.allCases[idx].triageId}'),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) _engine.loadCase(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Multi-Organ Coupling Pill
                  MultiOrganCouplingPill(state: _engine.multiOrganState),
                  const SizedBox(width: 8),

                  // Mastery Radar Button
                  OutlinedButton.icon(
                    onPressed: _showMasteryModal,
                    icon: const Icon(Icons.radar_rounded, size: 14, color: Colors.cyanAccent),
                    label: const Text('MASTERY RADAR', style: TextStyle(fontSize: 11, color: Colors.cyanAccent)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedsideVitalsHud() {
    return AnimatedBuilder(
      animation: _engine.multiOrganState,
      builder: (context, _) {
        final cardVitals = _engine.multiOrganState.cardiacVitals;
        final neuroVitals = _engine.multiOrganState.neuroVitals;
        final activeCase = _engine.activeCase;

        final hr = cardVitals.heartRateBpm;
        final sbp = cardVitals.systolicBp;
        final dbp = cardVitals.diastolicBp;
        final map = cardVitals.mapBp;
        final shockIndex = sbp > 0 ? (hr / sbp) : 0.0;
        final spo2 = activeCase.initialSpo2;
        final rr = activeCase.initialRr;
        final gcs = activeCase.initialGcs;
        final icp = neuroVitals.icpMmHg;

        Color hrColor = hr > 110 || hr < 55 ? Colors.redAccent : Colors.greenAccent;
        Color bpColor = sbp < 90 || sbp > 180 ? Colors.redAccent : Colors.cyanAccent;
        Color siColor = shockIndex > 0.9 ? Colors.redAccent : (shockIndex > 0.7 ? Colors.amberAccent : Colors.white70);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF030508),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildVitalBadge('HR', '${hr.toInt()} bpm', hrColor, Icons.favorite_rounded),
                const SizedBox(width: 12),
                _buildVitalBadge('BP', '${sbp.toInt()}/${dbp.toInt()} (${map.toInt()})', bpColor, Icons.speed_rounded),
                const SizedBox(width: 12),
                _buildVitalBadge('SHOCK INDEX', shockIndex.toStringAsFixed(2), siColor, Icons.warning_amber_rounded),
                const SizedBox(width: 12),
                _buildVitalBadge('SpO₂', '${spo2.toInt()}%', spo2 < 92 ? Colors.redAccent : Colors.cyanAccent, Icons.air_rounded),
                const SizedBox(width: 12),
                _buildVitalBadge('RR', '${rr.toInt()}/min', rr > 26 || rr < 8 ? Colors.orangeAccent : Colors.white70, Icons.waves_rounded),
                const SizedBox(width: 12),
                _buildVitalBadge('GCS', '$gcs/15', gcs < 9 ? Colors.redAccent : (gcs < 13 ? Colors.amberAccent : Colors.greenAccent), Icons.psychology_rounded),
                const SizedBox(width: 12),
                _buildVitalBadge('ICP', '${icp.toInt()} mmHg', icp > 20 ? Colors.redAccent : Colors.white70, Icons.compress_rounded),
                const SizedBox(width: 14),
                // ECG Rhythm Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monitor_heart_rounded, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        activeCase.initialEcgRhythm,
                        style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalBadge(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column: Triage Bedside Exam
          SizedBox(
            width: 320,
            child: _buildTriageExamCard(),
          ),
          const SizedBox(width: 12),

          // Center Column: POCUS Simulator
          Expanded(
            flex: 5,
            child: WardPocusSimulatorPanel(engine: _engine),
          ),
          const SizedBox(width: 12),

          // Right Column: DDx Proctor & Orders
          Expanded(
            flex: 4,
            child: WardDdxProctorPanel(
              engine: _engine,
              onRemediate: () => _navigateRemediation(_engine.activeCase.remediationRoute),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    switch (_mobileTab) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: _buildTriageExamCard(),
        );
      case 1:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: WardPocusSimulatorPanel(engine: _engine),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: WardDdxProctorPanel(
            engine: _engine,
            onRemediate: () => _navigateRemediation(_engine.activeCase.remediationRoute),
          ),
        );
      case 3:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: StudentMasteryRadarPanel(
            engine: _engine,
            onNavigateRemediation: _navigateRemediation,
          ),
        );
      default:
        return WardPocusSimulatorPanel(engine: _engine);
    }
  }

  Widget _buildMobileBottomBar() {
    return BottomNavigationBar(
      currentIndex: _mobileTab,
      onTap: (idx) => setState(() => _mobileTab = idx),
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: Colors.cyanAccent,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_information_rounded),
          label: 'Triage',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.radar_rounded),
          label: 'POCUS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grading_rounded),
          label: 'DDx & Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.hub_rounded),
          label: 'Mastery',
        ),
      ],
    );
  }

  Widget _buildTriageExamCard() {
    final activeCase = _engine.activeCase;

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.person_pin_circle_rounded, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'BEDSIDE TRIAGE & EXAM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),

            // Chief Complaint
            const Text(
              'CHIEF COMPLAINT',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              activeCase.chiefComplaint,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),

            // Triage Story
            const Text(
              'TRIAGE NARRATIVE',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              activeCase.triageStory,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
            ),
            const SizedBox(height: 14),

            // Physical Exam
            const Text(
              'TARGETED PHYSICAL EXAM',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                activeCase.physicalExamSummary,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontSize: 11.5, height: 1.4),
              ),
            ),
            const SizedBox(height: 14),

            // Diagnostic Instructions
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_walk_rounded, color: Colors.blueAccent, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'DIAGNOSTIC PROTOCOL',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. Select ultrasound windows in the POCUS simulator.\n'
                    '2. Measure effusion/IVC collapse with calipers.\n'
                    '3. Rank Top 3 DDx & execute life-saving orders.\n'
                    '4. Avoid lethal contraindications!',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

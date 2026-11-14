// ============================================================================
// OSCE Clinical Vignette Sandbox — MBBS, Pharm-D & DVM Timed Simulation
// ----------------------------------------------------------------------------
// Interactive timed emergency medical simulations with 3D target stabilization,
// antidote selection mechanics, and SaMD legal liability protection.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/services/url_service.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/osce/data/osce_scenarios.dart';

class OsceSandboxScreen extends StatefulWidget {
  final String? initialScenarioId;

  const OsceSandboxScreen({super.key, this.initialScenarioId});

  static Route<void> route({String? initialScenarioId}) {
    return MaterialPageRoute<void>(
      builder: (_) => OsceSandboxScreen(initialScenarioId: initialScenarioId),
      settings: RouteSettings(
        name: initialScenarioId != null ? '/osce?scenario=$initialScenarioId' : '/osce',
      ),
    );
  }

  @override
  State<OsceSandboxScreen> createState() => _OsceSandboxScreenState();
}

class _OsceSandboxScreenState extends State<OsceSandboxScreen> {
  int _activeScenarioIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 120;
  bool _isResolved = false;
  bool _isSuccess = false;
  String? _selectedAgent;
  int _score = 0;
  late List<String> _shuffledAgents;

  OsceScenario get _scenario => kOscePresetScenarios[_activeScenarioIndex];

  @override
  void initState() {
    super.initState();
    if (widget.initialScenarioId != null) {
      final idx = kOscePresetScenarios.indexWhere((s) => s.id == widget.initialScenarioId);
      if (idx != -1) {
        _activeScenarioIndex = idx;
      }
    }
    _initScenario();
  }

  void _initScenario() {
    _timer?.cancel();
    _remainingSeconds = _scenario.timeLimitSeconds.toInt();
    _isResolved = false;
    _isSuccess = false;
    _selectedAgent = null;
    _score = 0;

    _shuffledAgents = [
      _scenario.correctRescueAgentName,
      ..._scenario.alternativeDistractors,
    ]..shuffle();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0 && mounted) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        if (!_isResolved && mounted) {
          _resolveFailure('Time expired! Uncontrolled toxic receptor failure.');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleAgentSelection(String agent) {
    if (_isResolved) return;
    _selectedAgent = agent;

    if (agent == _scenario.correctRescueAgentName) {
      _timer?.cancel();
      final timeBonus = (_remainingSeconds * 0.4).toInt();
      setState(() {
        _isResolved = true;
        _isSuccess = true;
        _score = 80 + timeBonus;
      });
    } else {
      _resolveFailure('Incorrect antidote selected: $agent.');
    }
  }

  void _resolveFailure(String reason) {
    _timer?.cancel();
    setState(() {
      _isResolved = true;
      _isSuccess = false;
      _score = 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        backgroundColor: palette.panel,
        title: const Row(
          children: [
            Icon(Icons.medical_services_rounded, color: Color(0xFF00E5FF), size: 22),
            SizedBox(width: 10),
            Text(
              'OSCE Clinical Emergency Simulation Sandbox',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: Color(0xFFFFB300), size: 14),
                SizedBox(width: 6),
                Text(
                  'TIMED OSCE BENCHMARK',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Mandatory Amber SaMD Disclaimer Banner ─────────────────────
                _buildSaMDBanner(),
                const SizedBox(height: 16),

                // ── Scenario Selector Tabs ───────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(kOscePresetScenarios.length, (idx) {
                      final sc = kOscePresetScenarios[idx];
                      final isSel = idx == _activeScenarioIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${sc.discipline.split(' ').first}: ${sc.title.split(' ').take(3).join(' ')}...'),
                          selected: isSel,
                          selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                          backgroundColor: palette.panel,
                          labelStyle: TextStyle(
                            color: isSel ? const Color(0xFF00E5FF) : palette.textMuted,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: isSel ? const Color(0xFF00E5FF) : palette.border,
                          ),
                          onSelected: (selected) {
                            if (selected && idx != _activeScenarioIndex) {
                              setState(() {
                                _activeScenarioIndex = idx;
                                _initScenario();
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Main Simulation Container ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.panel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Timer and Target
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _scenario.discipline.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF00BFA5),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _scenario.title,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _remainingSeconds < 30
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                  : palette.scaffold,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _remainingSeconds < 30
                                    ? const Color(0xFFEF4444)
                                    : palette.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.hourglass_top_rounded,
                                  size: 16,
                                  color: _remainingSeconds < 30
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFFFB300),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: _remainingSeconds < 30
                                        ? const Color(0xFFEF4444)
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Patient Clinical Brief & Emergency Vitals Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.scaffold,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emergency_outlined, color: Color(0xFFEF4444), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'PATIENT EMERGENCY PRESENTATION',
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _scenario.patientBrief,
                              style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.monitor_heart_outlined, color: Color(0xFF00E676), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Vitals: ${_scenario.clinicalVitals}',
                                      style: const TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Molecular Target Crisis
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.scaffold,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isResolved && _isSuccess
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_amber_rounded,
                                  color: _isResolved && _isSuccess
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFFFFB300),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'MOLECULAR TARGET: ${_scenario.targetReceptorName}',
                                  style: TextStyle(
                                    color: _isResolved && _isSuccess
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFFB300),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _scenario.biochemicalCrisis,
                              style: TextStyle(color: palette.textMuted, fontSize: 12.5, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Antidote Selection Tray
                      Text(
                        'DISPATCH RESCUE AGENT INTO 3D WORKSPACE:',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _shuffledAgents.map((agent) {
                          final isSelected = _selectedAgent == agent;
                          final isCorrect = agent == _scenario.correctRescueAgentName;

                          Color buttonColor = palette.scaffold;
                          Color textColor = palette.textPrimary;
                          Color borderColor = palette.border;

                          if (_isResolved && isSelected) {
                            if (_isSuccess) {
                              buttonColor = const Color(0xFF00E676).withValues(alpha: 0.2);
                              textColor = const Color(0xFF00E676);
                              borderColor = const Color(0xFF00E676);
                            } else {
                              buttonColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
                              textColor = const Color(0xFFEF4444);
                              borderColor = const Color(0xFFEF4444);
                            }
                          } else if (_isResolved && isCorrect) {
                            borderColor = const Color(0xFF00E676);
                          }

                          return InkWell(
                            onTap: _isResolved ? null : () => _handleAgentSelection(agent),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: buttonColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.vaccines_rounded,
                                    size: 16,
                                    color: textColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    agent,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Resolution Outcome Box
                      if (_isResolved) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isSuccess
                                ? const Color(0xFF00E676).withValues(alpha: 0.1)
                                : const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isSuccess
                                  ? const Color(0xFF00E676).withValues(alpha: 0.5)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                        color: _isSuccess ? const Color(0xFF00E676) : const Color(0xFFEF4444),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isSuccess ? 'RESCUE SUCCESSFUL' : 'SIMULATION FAILED',
                                        style: TextStyle(
                                          color: _isSuccess ? const Color(0xFF00E676) : const Color(0xFFEF4444),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'OSCE Score: $_score/100',
                                      style: TextStyle(
                                        color: _isSuccess ? const Color(0xFF00E676) : const Color(0xFFEF4444),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isSuccess ? _scenario.mechanismOfRescue : _scenario.contraindicationWarning,
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),

                              // High Yield OSCE Exam Pearls
                              Text(
                                'HIGH-YIELD OSCE CLINICAL PEARLS:',
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              for (final pearl in _scenario.highYieldExamPearls)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: Color(0xFF00E5FF))),
                                      Expanded(
                                        child: Text(
                                          pearl,
                                          style: TextStyle(color: palette.textSecondary, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 10),

                              // Citations & Reset
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () => UrlService.launch('https://doi.org/${_scenario.primaryDoi}'),
                                    child: Text(
                                      'DOI: ${_scenario.primaryDoi} ↗',
                                      style: const TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _initScenario,
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Try Again'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: palette.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaMDBanner() {
    const amberColor = Color(0xFFFFB300);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: amberColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: amberColor.withValues(alpha: 0.4), width: 1.0),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: amberColor, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Educational Simulation Only — Not for Clinical Diagnosis, Prescribing, or Patient Care.',
              style: TextStyle(
                color: amberColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

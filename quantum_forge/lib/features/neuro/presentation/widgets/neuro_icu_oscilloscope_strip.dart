// ============================================================================
// Multi-Channel Neuro-ICU & IONM Telemetry Oscilloscope — NeuroLab 3D
// ----------------------------------------------------------------------------
// 5-Channel synchronized phosphor oscilloscope modeled on ICU/IONM workstations:
// - Ch 1: Scalp EEG Left (Fp1–C3) — Green (#00E676)
// - Ch 2: Scalp EEG Right (Fp2–C4) — Cyan (#38BDF8)
// - Ch 3: SSEP Cortical N20/P25 — Violet (#A78BFA)
// - Ch 4: Transcranial MEP CMAP — Rose (#F43F5E)
// - Ch 5: Invasive ICP & CPP — Amber (#FFB74D)
// Features: Sweep speed toggle, Freeze frame, Electronic Calipers,
// and stacked ICU numeric parameter tiles with CPP = MAP - ICP computation.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/neuro_pathology_models.dart';
import '../../data/neuro_hemodynamics_engine.dart';
import 'neuro_clinical_info_system.dart';

class NeuroIcuOscilloscopeStrip extends StatefulWidget {
  final NeuroScenario scenario;
  final SpinalSyndrome spinalSyndrome;
  final EegPattern eegPattern;
  final ValueChanged<EegPattern>? onEegPatternChanged;
  final bool isThrombectomized;

  const NeuroIcuOscilloscopeStrip({
    super.key,
    required this.scenario,
    this.spinalSyndrome = SpinalSyndrome.normal,
    this.eegPattern = EegPattern.normalAlpha,
    this.onEegPatternChanged,
    this.isThrombectomized = false,
  });

  @override
  State<NeuroIcuOscilloscopeStrip> createState() => _NeuroIcuOscilloscopeStripState();
}

class _NeuroIcuOscilloscopeStripState extends State<NeuroIcuOscilloscopeStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  double _timeSeconds = 0.0;
  bool _isFrozen = false;
  bool _showCalipers = false;
  double _caliper1X = 0.25; // 0.0 to 1.0 fraction of width
  double _caliper2X = 0.65;
  double _sweepSpeedMultiplier = 1.0; // 1.0 = 25 mm/s, 2.0 = 50 mm/s

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    _animCtrl.repeat();
  }

  void _onTick() {
    if (!_isFrozen) {
      setState(() {
        _timeSeconds += 0.016 * _sweepSpeedMultiplier;
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.removeListener(_onTick);
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Current physiological numbers
    final icp = widget.scenario.icpMmHg;
    final map = widget.scenario.mapMmHg;
    final cpp = map - icp;
    final isIcpAlarm = icp > 20.0;
    final isCppLow = cpp < 60.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060911),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Oscilloscope Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                const Icon(Icons.monitor_heart_rounded, color: Color(0xFF00E676), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '5-CHANNEL NEURO-ICU & IONM OSCILLOSCOPE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const NeuroInfoButton(topicId: 'icp_monro_kellie', size: 14),
                const SizedBox(width: 8),

                // Sweep speed toggle
                InkWell(
                  onTap: () => setState(() {
                    _sweepSpeedMultiplier = _sweepSpeedMultiplier == 1.0 ? 2.0 : 1.0;
                  }),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _sweepSpeedMultiplier == 1.0 ? '25 mm/s' : '50 mm/s',
                      style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Caliper toggle
                IconButton(
                  tooltip: _showCalipers ? 'Hide Calipers' : 'Measure with Electronic Calipers',
                  icon: Icon(
                    Icons.straighten_rounded,
                    size: 16,
                    color: _showCalipers ? const Color(0xFFFFD740) : Colors.white60,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _showCalipers ? const Color(0xFF78350F) : const Color(0xFF1E293B),
                    padding: const EdgeInsets.all(5),
                  ),
                  onPressed: () => setState(() => _showCalipers = !_showCalipers),
                ),
                const SizedBox(width: 6),

                // Freeze frame toggle
                IconButton(
                  tooltip: _isFrozen ? 'Resume Live Telemetry' : 'Freeze Trace',
                  icon: Icon(
                    _isFrozen ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 16,
                    color: _isFrozen ? const Color(0xFF00E676) : Colors.white60,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _isFrozen ? const Color(0xFF065F46) : const Color(0xFF1E293B),
                    padding: const EdgeInsets.all(5),
                  ),
                  onPressed: () => setState(() => _isFrozen = !_isFrozen),
                ),
              ],
            ),
          ),

          // Main View: 5 Phosphor Channels (Left) + Numeric Parameter Tiles (Right)
          Expanded(
            child: Row(
              children: [
                // 5 Channels
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onHorizontalDragUpdate: _showCalipers
                            ? (details) {
                                final localX = details.localPosition.dx / constraints.maxWidth;
                                final d1 = (localX - _caliper1X).abs();
                                final d2 = (localX - _caliper2X).abs();
                                setState(() {
                                  if (d1 < d2) {
                                    _caliper1X = localX.clamp(0.02, 0.98);
                                  } else {
                                    _caliper2X = localX.clamp(0.02, 0.98);
                                  }
                                });
                              }
                            : null,
                        child: CustomPaint(
                          painter: _NeuroOscilloscopePainter(
                            timeSeconds: _timeSeconds,
                            scenario: widget.scenario,
                            syndrome: widget.spinalSyndrome,
                            eegPattern: widget.eegPattern,
                            isThrombectomized: widget.isThrombectomized,
                            showCalipers: _showCalipers,
                            caliper1X: _caliper1X,
                            caliper2X: _caliper2X,
                          ),
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                      );
                    },
                  ),
                ),

                // Stacked Numeric Tiles (Right Column)
                Container(
                  width: 140,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0F1D),
                    border: Border(left: BorderSide(color: Color(0xFF1E293B))),
                  ),
                  child: Column(
                    children: [
                      // ICP Tile
                      _buildNumericTile(
                        label: 'ICP mmHg',
                        value: icp.round().toString(),
                        accentColor: isIcpAlarm ? const Color(0xFFEF4444) : const Color(0xFFFFB74D),
                        badgeText: isIcpAlarm ? 'HIGH' : 'NORMAL',
                        badgeColor: isIcpAlarm ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      ),
                      const Divider(height: 1, color: Color(0xFF1E293B)),

                      // CPP Tile
                      _buildNumericTile(
                        label: 'CPP mmHg',
                        value: cpp.round().toString(),
                        accentColor: isCppLow ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                        badgeText: isCppLow ? 'ISCHEMIC' : 'ADEQUATE',
                        badgeColor: isCppLow ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                      ),
                      const Divider(height: 1, color: Color(0xFF1E293B)),

                      // SSEP Tile
                      _buildNumericTile(
                        label: 'SSEP N20',
                        value: widget.spinalSyndrome == SpinalSyndrome.subacuteCombined ? '27.4 ms' : '19.8 ms',
                        accentColor: const Color(0xFFA78BFA),
                        badgeText: widget.spinalSyndrome == SpinalSyndrome.brownSequard ? '-70% AMP' : 'STABLE',
                        badgeColor: widget.spinalSyndrome == SpinalSyndrome.brownSequard
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                      const Divider(height: 1, color: Color(0xFF1E293B)),

                      // MEP Tile
                      _buildNumericTile(
                        label: 'MEP CMAP',
                        value: (widget.spinalSyndrome == SpinalSyndrome.anteriorCord ||
                                widget.spinalSyndrome == SpinalSyndrome.brownSequard)
                            ? 'LOST'
                            : '185 uV',
                        accentColor: const Color(0xFFF43F5E),
                        badgeText: (widget.spinalSyndrome == SpinalSyndrome.anteriorCord) ? 'CRITICAL' : 'ROBUST',
                        badgeColor: (widget.spinalSyndrome == SpinalSyndrome.anteriorCord)
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                      const Divider(height: 1, color: Color(0xFF1E293B)),

                      // EEG Dominant Rhythm Tile
                      _buildNumericTile(
                        label: 'EEG PATTERN',
                        value: widget.eegPattern.shortCode,
                        accentColor: const Color(0xFF00E676),
                        badgeText: widget.eegPattern.shortCode,
                        badgeColor: const Color(0xFF1E293B),
                        isSmallValue: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericTile({
    required String label,
    required String value,
    required Color accentColor,
    required String badgeText,
    required Color badgeColor,
    bool isSmallValue = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallValue ? 14 : 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: accentColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeuroOscilloscopePainter extends CustomPainter {
  final double timeSeconds;
  final NeuroScenario scenario;
  final SpinalSyndrome syndrome;
  final EegPattern eegPattern;
  final bool isThrombectomized;
  final bool showCalipers;
  final double caliper1X;
  final double caliper2X;

  _NeuroOscilloscopePainter({
    required this.timeSeconds,
    required this.scenario,
    required this.syndrome,
    required this.eegPattern,
    required this.isThrombectomized,
    required this.showCalipers,
    required this.caliper1X,
    required this.caliper2X,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final channelHeight = size.height / 5.0;

    // 1. CRT Background Grid (10 mm / 50 mm simulation)
    final gridFinePaint = Paint()
      ..color = const Color(0xFF101B2E).withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    final gridCoarsePaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.8)
      ..strokeWidth = 1.2;

    for (double x = 0; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), (x % 100 == 0) ? gridCoarsePaint : gridFinePaint);
    }
    for (int i = 0; i <= 5; i++) {
      final y = i * channelHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridCoarsePaint);
    }

    // Channel metadata
    final channelConfigs = [
      _ChannelConfig(
        title: 'EEG LEFT (Fp1–C3)',
        color: const Color(0xFF00E676),
        scaleText: '70 uV/cm',
        sampleFn: (t) => NeuroHemodynamicsEngine.computeEegSample(
          timeSeconds: t,
          isLeftHemisphere: true,
          pattern: eegPattern,
          isThrombectomized: isThrombectomized,
        ),
        ampScale: 0.28,
      ),
      _ChannelConfig(
        title: 'EEG RIGHT (Fp2–C4)',
        color: const Color(0xFF38BDF8),
        scaleText: '70 uV/cm',
        sampleFn: (t) => NeuroHemodynamicsEngine.computeEegSample(
          timeSeconds: t,
          isLeftHemisphere: false,
          pattern: eegPattern,
          isThrombectomized: isThrombectomized,
        ),
        ampScale: 0.28,
      ),
      _ChannelConfig(
        title: 'SSEP CORTICAL N20/P25',
        color: const Color(0xFFA78BFA),
        scaleText: '2 uV/div • 5 ms/div',
        sampleFn: (t) => NeuroHemodynamicsEngine.computeSsepSample(
          timeSeconds: t,
          syndrome: syndrome,
        ),
        ampScale: 10.0,
      ),
      _ChannelConfig(
        title: 'MEP TRANSCRANIAL CMAP',
        color: const Color(0xFFF43F5E),
        scaleText: '50 uV/div',
        sampleFn: (t) => NeuroHemodynamicsEngine.computeMepSample(
          timeSeconds: t,
          syndrome: syndrome,
        ),
        ampScale: 0.18,
      ),
      _ChannelConfig(
        title: 'ICP (mmHg) / CPP = MAP - ICP',
        color: const Color(0xFFFFB74D),
        scaleText: '0–50 mmHg',
        sampleFn: (t) => NeuroHemodynamicsEngine.computeIcpSample(
          timeSeconds: t,
          baselineIcp: scenario.icpMmHg,
          mapMmHg: scenario.mapMmHg,
        ),
        ampScale: 1.2,
      ),
    ];

    // Paint each channel waveform
    for (int ch = 0; ch < 5; ch++) {
      final config = channelConfigs[ch];
      final topY = ch * channelHeight;
      final midY = topY + channelHeight * 0.55;

      // Draw Channel Label & Scale
      final textSpan = TextSpan(
        text: '${config.title}  [${config.scaleText}]',
        style: TextStyle(
          color: config.color.withValues(alpha: 0.8),
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(10, topY + 4));

      // Draw Waveform Strip across width
      final wavePath = Path();
      final numPoints = (size.width / 2.0).round();
      final windowDuration = 4.0; // 4 seconds across screen

      for (int i = 0; i < numPoints; i++) {
        final x = (i / (numPoints - 1)) * size.width;
        final sampleTime = timeSeconds - windowDuration * (1.0 - (i / numPoints));
        final val = config.sampleFn(sampleTime);
        final y = (midY - (val * config.ampScale)).clamp(topY + 12.0, topY + channelHeight - 4.0);

        if (i == 0) {
          wavePath.moveTo(x, y);
        } else {
          wavePath.lineTo(x, y);
        }
      }

      // Phosphor glow + core trace
      final glowPaint = Paint()
        ..color = config.color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      final corePaint = Paint()
        ..color = config.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      canvas.drawPath(wavePath, glowPaint);
      canvas.drawPath(wavePath, corePaint);
    }

    // 2. Electronic Calipers if enabled
    if (showCalipers) {
      final c1x = caliper1X * size.width;
      final c2x = caliper2X * size.width;
      final caliperPaint = Paint()
        ..color = const Color(0xFFFFD740)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw vertical lines
      canvas.drawLine(Offset(c1x, 0), Offset(c1x, size.height), caliperPaint);
      canvas.drawLine(Offset(c2x, 0), Offset(c2x, size.height), caliperPaint);

      // Caliper Delta Box
      final deltaPixels = (c2x - c1x).abs();
      final deltaMs = (deltaPixels / size.width) * 4000.0; // 4000 ms screen duration

      final deltaText = 'Δt = ${deltaMs.toStringAsFixed(1)} ms (${(1000.0 / deltaMs).toStringAsFixed(1)} Hz)';
      final span = TextSpan(
        text: deltaText,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          backgroundColor: Color(0xFFFFD740),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      final bannerX = math.min(c1x, c2x) + 6;
      tp.paint(canvas, Offset(bannerX.clamp(10, size.width - 150), 20));
    }
  }

  @override
  bool shouldRepaint(covariant _NeuroOscilloscopePainter oldDelegate) {
    return oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.scenario != scenario ||
        oldDelegate.syndrome != syndrome ||
        oldDelegate.eegPattern != eegPattern ||
        oldDelegate.isThrombectomized != isThrombectomized ||
        oldDelegate.showCalipers != showCalipers ||
        oldDelegate.caliper1X != caliper1X ||
        oldDelegate.caliper2X != caliper2X;
  }
}

class _ChannelConfig {
  final String title;
  final Color color;
  final String scaleText;
  final double Function(double t) sampleFn;
  final double ampScale;

  _ChannelConfig({
    required this.title,
    required this.color,
    required this.scaleText,
    required this.sampleFn,
    required this.ampScale,
  });
}

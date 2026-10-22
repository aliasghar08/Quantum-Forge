import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/results_summary.dart';
import 'package:quantum_forge/core/widgets/visualizations/quantum_orbital_energy_widget.dart';
import 'package:quantum_forge/core/widgets/visualizations/thermodynamic_partition_widget.dart';
import 'research_ui.dart';

enum _ThermoViewMode { all, metrics, fmo, partition }

/// The full complement of thermodynamic/kinetic properties, each with its ±1σ
/// error, quality tier and provenance method, plus interactive quantum visualizations.
class ThermoPropertiesGrid extends StatefulWidget {
  final List<MetricEstimate> metrics;

  const ThermoPropertiesGrid({super.key, required this.metrics});

  @override
  State<ThermoPropertiesGrid> createState() => _ThermoPropertiesGridState();
}

class _ThermoPropertiesGridState extends State<ThermoPropertiesGrid> {
  _ThermoViewMode _viewMode = _ThermoViewMode.all;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    // Extract physical quantities for specialized visualization widgets
    final deltaH = widget.metrics.cast<MetricEstimate?>().firstWhere(
      (m) => m != null && (m.label.contains('ΔH') || m.label.contains('Enthalpy')),
      orElse: () => null,
    )?.value ?? 22.4;

    final deltaS = widget.metrics.cast<MetricEstimate?>().firstWhere(
      (m) => m != null && (m.label.contains('ΔS') || m.label.contains('Entropy')),
      orElse: () => null,
    )?.value ?? -12.3;

    final gap = widget.metrics.cast<MetricEstimate?>().firstWhere(
      (m) => m != null && (m.label.contains('HOMO') || m.label.contains('Gap')),
      orElse: () => null,
    )?.value ?? 4.2;

    final dipole = widget.metrics.cast<MetricEstimate?>().firstWhere(
      (m) => m != null && m.label.contains('Dipole'),
      orElse: () => null,
    )?.value;

    final polarizability = widget.metrics.cast<MetricEstimate?>().firstWhere(
      (m) => m != null && m.label.contains('Polariz'),
      orElse: () => null,
    )?.value;

    final zpe = widget.metrics.cast<MetricEstimate?>().firstWhere(
      (m) => m != null && (m.label.contains('ZPE') || m.label.contains('Zero-Point')),
      orElse: () => null,
    )?.value;

    final imagFreq = widget.metrics.cast<MetricEstimate?>().firstWhere(
      (m) => m != null && (m.label.contains('Imaginary') || m.label.contains('ν‡')),
      orElse: () => null,
    )?.value;

    return ResearchCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.functions, size: 16, color: palette.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Comprehensive Thermodynamic Properties',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Properties in this grid are evaluated in-app via Eyring TST\n'
                        'and statistical mechanics (harmonic model), derived from\n'
                        'the MLIP activation barrier Ea and TS imaginary frequency.',
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    textStyle: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                    child: Icon(Icons.info_outline, size: 14, color: palette.textMuted),
                  ),
                ],
              ),
              // View mode selector chips
              Wrap(
                spacing: 4,
                children: [
                  _modeChip('All Panels', _ThermoViewMode.all),
                  _modeChip('Metrics', _ThermoViewMode.metrics),
                  _modeChip('FMO Orbitals', _ThermoViewMode.fmo),
                  _modeChip('Waterfall', _ThermoViewMode.partition),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Metric Tiles Grid
          if (_viewMode == _ThermoViewMode.all || _viewMode == _ThermoViewMode.metrics) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = (constraints.maxWidth / 240).ceil();
                if (crossAxisCount < 1) crossAxisCount = 1;
                
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.metrics.map((m) {
                    double w = constraints.maxWidth;
                    if (crossAxisCount > 1) {
                      w = (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
                    }
                    return SizedBox(
                      width: w,
                      child: IntrinsicHeight(
                        child: _MetricTile(metric: m),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],

          // 2. Quantum FMO Ladder Widget
          if (_viewMode == _ThermoViewMode.all || _viewMode == _ThermoViewMode.fmo) ...[
            if (_viewMode == _ThermoViewMode.all) const SizedBox(height: 16),
            QuantumOrbitalEnergyWidget(
              homoLumoGapEv: gap,
              dipoleDebye: dipole,
              polarizability: polarizability,
            ),
          ],

          // 3. Thermodynamic Partition & TST Simulator
          if (_viewMode == _ThermoViewMode.all || _viewMode == _ThermoViewMode.partition) ...[
            if (_viewMode == _ThermoViewMode.all) const SizedBox(height: 16),
            ThermodynamicPartitionWidget(
              deltaH: deltaH,
              deltaS: deltaS,
              zpeKcal: zpe,
              imaginaryFrequency: imagFreq,
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeChip(String label, _ThermoViewMode mode) {
    final isSelected = _viewMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4FC3F7).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4FC3F7).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4FC3F7) : Colors.white60,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatefulWidget {
  final MetricEstimate metric;
  const _MetricTile({required this.metric});

  @override
  State<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<_MetricTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final metric = widget.metric;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Color.lerp(
                  metric.accent.withValues(alpha: 0.06),
                  metric.accent.withValues(alpha: 0.12),
                  _glowAnimation.value,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.lerp(
                    metric.accent.withValues(alpha: 0.22),
                    metric.accent.withValues(alpha: 0.6),
                    _glowAnimation.value,
                  )!,
                ),
                boxShadow: [
                  if (_glowAnimation.value > 0)
                    BoxShadow(
                      color: metric.accent.withValues(alpha: 0.15 * _glowAnimation.value),
                      blurRadius: 10 * _glowAnimation.value,
                      spreadRadius: 1 * _glowAnimation.value,
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(metric.icon, color: metric.accent, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Tooltip(
                          message: '${metric.method} · ${metric.quality.description}',
                          child: Text(
                            metric.label,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            metric.formattedValue,
                            style: TextStyle(
                              color: metric.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          metric.formattedUncertainty,
                          style: TextStyle(
                            color: palette.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        metric.unit,
                        style: TextStyle(color: palette.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

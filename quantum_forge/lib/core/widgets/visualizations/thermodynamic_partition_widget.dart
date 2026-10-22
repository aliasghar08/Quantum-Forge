import 'dart:math' as math;
import 'package:flutter/material.dart';

class ThermodynamicPartitionWidget extends StatefulWidget {
  final double deltaH; // kcal/mol
  final double deltaS; // cal/(mol·K)
  final double initialTemperatureK;
  final double? zpeKcal;
  final double? imaginaryFrequency;

  const ThermodynamicPartitionWidget({
    super.key,
    required this.deltaH,
    required this.deltaS,
    this.initialTemperatureK = 298.15,
    this.zpeKcal,
    this.imaginaryFrequency,
  });

  @override
  State<ThermodynamicPartitionWidget> createState() => _ThermodynamicPartitionWidgetState();
}

class _ThermodynamicPartitionWidgetState extends State<ThermodynamicPartitionWidget> {
  late double _temperatureK;

  static const double _kb = 1.380649e-23; // J/K
  static const double _h = 6.62607015e-34; // J·s
  static const double _r = 8.314462618; // J/(mol·K)
  static const double _kcalToJ = 4184.0;

  @override
  void initState() {
    super.initState();
    _temperatureK = widget.initialTemperatureK;
  }

  @override
  Widget build(BuildContext context) {
    final tK = _temperatureK;
    final tDeltaS = (tK * widget.deltaS) / 1000.0; // kcal/mol
    final deltaG = widget.deltaH - tDeltaS; // ΔG = ΔH - TΔS

    // Eyring equation: k = (kB*T/h) * exp(-ΔG*4184 / (R*T))
    final prefactor = (_kb * tK) / _h;
    final exponent = -(deltaG * _kcalToJ) / (_r * tK);
    final double rateK;
    if (exponent < -100.0) {
      rateK = 1e-45;
    } else if (exponent > 80.0) {
      rateK = 1e35;
    } else {
      rateK = prefactor * math.exp(exponent);
    }

    final halfLifeSec = rateK > 0 ? (math.ln2 / rateK) : double.infinity;
    final (kineticTier, tierColor, tierIcon) = _classifyKinetics(rateK);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.04),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.waterfall_chart_rounded, size: 18, color: Color(0xFFFFB74D)),
              const SizedBox(width: 8),
              const Text(
                'Thermodynamic Partition & TST Simulator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'ΔG‡ = ${deltaG.toStringAsFixed(2)} kcal/mol',
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Waterfall Energy Partition Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Gibbs Free Energy Decomposition: ΔG‡ = ΔH‡ − TΔS‡',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildBarSegment('ΔH‡ (Enthalpic Barrier)', widget.deltaH, const Color(0xFFFF7043), true),
                const SizedBox(height: 8),
                _buildBarSegment('−TΔS‡ (Entropic Penalty)', -tDeltaS, const Color(0xFF42A5F5), false),
                const SizedBox(height: 8),
                _buildBarSegment('ΔG‡ (Effective Free Energy)', deltaG, const Color(0xFFFFCA28), true, isTotal: true),
                if (widget.zpeKcal != null) ...[
                  const SizedBox(height: 8),
                  _buildBarSegment('ZPE Offset (Zero-Point Energy)', widget.zpeKcal!, const Color(0xFF26A69A), false),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Eyring Temperature Slider
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thermostat_rounded, size: 16, color: Color(0xFFFF7043)),
                        const SizedBox(width: 6),
                        const Text(
                          'Thermal Kinetic Sweep:',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      '${_temperatureK.toStringAsFixed(1)} K (${(_temperatureK - 273.15).toStringAsFixed(1)} °C)',
                      style: const TextStyle(
                        color: Color(0xFFFF7043),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFFF7043),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: const Color(0xFFFF7043),
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _temperatureK,
                    min: 150.0,
                    max: 600.0,
                    divisions: 90,
                    label: '${_temperatureK.toStringAsFixed(0)} K',
                    onChanged: (v) => setState(() => _temperatureK = v),
                  ),
                ),
                // Quick temperature buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTempPreset(195.15, '195 K (Dry Ice)'),
                    _buildTempPreset(273.15, '273 K (0 °C)'),
                    _buildTempPreset(298.15, '298 K (Room Temp)'),
                    _buildTempPreset(310.15, '310 K (Body Temp)'),
                    _buildTempPreset(373.15, '373 K (Boiling)'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Rate Constant & Half-Life Output
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tierColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(tierIcon, size: 22, color: tierColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TST Rate k = ${_formatSci(rateK)} s⁻¹  ·  t½ ≈ ${_formatHalfLife(halfLifeSec)}',
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kineticTier,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
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

  Widget _buildBarSegment(String label, double value, Color color, bool isPositive, {bool isTotal = false}) {
    final maxRef = math.max(35.0, widget.deltaH.abs() * 1.5);
    final widthFactor = (value.abs() / maxRef).clamp(0.05, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white60, fontSize: 11)),
            Text(
              '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} kcal/mol',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: isTotal ? 7 : 5,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.05),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isTotal
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTempPreset(double tempK, String label) {
    final isSelected = (_temperatureK - tempK).abs() < 1.0;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => setState(() => _temperatureK = tempK),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF7043).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7043) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF7043) : Colors.white60,
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  (String, Color, IconData) _classifyKinetics(double k) {
    if (k > 1e6) {
      return ('Ultrafast / Diffusion-Controlled: instantaneous on mixing (< 1 µs)', const Color(0xFF00E676), Icons.bolt_rounded);
    }
    if (k > 1.0) {
      return ('Rapid Bench Scale: converges in milliseconds to seconds', const Color(0xFF81C784), Icons.timer_rounded);
    }
    if (k > 1e-4) {
      return ('Practical Synthetic Rate: proceeds to completion over minutes to hours', const Color(0xFF4FC3F7), Icons.hourglass_top_rounded);
    }
    if (k > 1e-8) {
      return ('Sluggish Kinetics: requires thermal heating or catalytic lowering of ΔG‡', const Color(0xFFFFB74D), Icons.hourglass_bottom_rounded);
    }
    return ('Thermally Inactive: barrier too high at this temperature (half-life > years)', const Color(0xFFFF5252), Icons.cancel_outlined);
  }

  String _formatSci(double val) {
    if (val <= 0 || val.isNaN || val.isInfinite) return '0.00';
    if (val >= 0.01 && val < 1000) return val.toStringAsFixed(3);
    final exp = (math.log(val) / math.ln10).floor();
    final mantissa = val / math.pow(10.0, exp);
    return '${mantissa.toStringAsFixed(2)} × 10^$exp';
  }

  String _formatHalfLife(double sec) {
    if (sec.isInfinite || sec > 1e12) return '> 100,000 years';
    if (sec < 1e-6) return '${(sec * 1e9).toStringAsFixed(1)} ns';
    if (sec < 1e-3) return '${(sec * 1e6).toStringAsFixed(1)} µs';
    if (sec < 1.0) return '${(sec * 1e3).toStringAsFixed(1)} ms';
    if (sec < 60) return '${sec.toStringAsFixed(1)} s';
    if (sec < 3600) return '${(sec / 60).toStringAsFixed(1)} min';
    if (sec < 86400) return '${(sec / 3600).toStringAsFixed(1)} h';
    if (sec < 31536000) return '${(sec / 86400).toStringAsFixed(1)} days';
    return '${(sec / 31536000).toStringAsFixed(1)} years';
  }
}

import 'package:flutter/material.dart';

class QuantumOrbitalEnergyWidget extends StatefulWidget {
  final double homoLumoGapEv;
  final double? homoEnergyEv;
  final double? lumoEnergyEv;
  final double? dipoleDebye;
  final double? polarizability;

  const QuantumOrbitalEnergyWidget({
    super.key,
    required this.homoLumoGapEv,
    this.homoEnergyEv,
    this.lumoEnergyEv,
    this.dipoleDebye,
    this.polarizability,
  });

  @override
  State<QuantumOrbitalEnergyWidget> createState() => _QuantumOrbitalEnergyWidgetState();
}

class _QuantumOrbitalEnergyWidgetState extends State<QuantumOrbitalEnergyWidget> {
  int? _selectedOrbitalIndex;

  @override
  Widget build(BuildContext context) {
    final gap = widget.homoLumoGapEv > 0 ? widget.homoLumoGapEv : 4.2;
    final homo = widget.homoEnergyEv ?? (-gap * 0.7 - 2.5);
    final lumo = widget.lumoEnergyEv ?? (homo + gap);

    // Derived chemical reactivity indices
    final hardness = gap / 2.0; // η = (ELUMO - EHOMO)/2
    final electronegativity = -(homo + lumo) / 2.0; // χ = -(EHOMO + ELUMO)/2
    final electrophilicity = hardness > 0 ? (electronegativity * electronegativity) / (2 * hardness) : 1.0;

    // Optical absorption wavelength λ = 1239.84 / ΔE (nm)
    final lambdaNm = gap > 0 ? (1239.84 / gap) : 300.0;
    final (spectralName, spectralColor) = _getSpectralBand(lambdaNm);

    final orbitals = [
      _OrbitalLevel(
        name: 'LUMO+1',
        energyEv: lumo + 1.8,
        isOccupied: false,
        description: 'Second lowest unoccupied molecular orbital (higher excited states)',
      ),
      _OrbitalLevel(
        name: 'LUMO',
        energyEv: lumo,
        isOccupied: false,
        isFrontier: true,
        description: 'Lowest Unoccupied Molecular Orbital: primary electron acceptor / Lewis acidic site',
      ),
      _OrbitalLevel(
        name: 'HOMO',
        energyEv: homo,
        isOccupied: true,
        isFrontier: true,
        description: 'Highest Occupied Molecular Orbital: primary electron donor / nucleophilic attack center',
      ),
      _OrbitalLevel(
        name: 'HOMO-1',
        energyEv: homo - 1.6,
        isOccupied: true,
        description: 'Penultimate occupied orbital (deep valence electrons)',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.05),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.blur_on_rounded, size: 18, color: Color(0xFF4FC3F7)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Frontier Molecular Orbital (FMO) Ladder',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'ΔE_HL = ${gap.toStringAsFixed(2)} eV',
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Interactive Orbital Ladder
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                for (int i = 0; i < orbitals.length; i++) ...[
                  _buildOrbitalRow(orbitals[i], i),
                  if (i == 1) _buildGapConnector(gap, lambdaNm, spectralName, spectralColor),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Selected orbital description card
          if (_selectedOrbitalIndex != null && _selectedOrbitalIndex! < orbitals.length) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (orbitals[_selectedOrbitalIndex!].isOccupied
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF5252))
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (orbitals[_selectedOrbitalIndex!].isOccupied
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF5252))
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    orbitals[_selectedOrbitalIndex!].isOccupied ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 14,
                    color: orbitals[_selectedOrbitalIndex!].isOccupied
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF5252),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${orbitals[_selectedOrbitalIndex!].name} (${orbitals[_selectedOrbitalIndex!].energyEv.toStringAsFixed(2)} eV): ${orbitals[_selectedOrbitalIndex!].description}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Reactivity Indices Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildIndexBadge(
                'Optical Absorption',
                '${lambdaNm.toStringAsFixed(1)} nm ($spectralName)',
                spectralColor,
                Icons.light_mode_rounded,
              ),
              _buildIndexBadge(
                'Chemical Hardness (η)',
                '${hardness.toStringAsFixed(2)} eV',
                const Color(0xFFAB47BC),
                Icons.shield_outlined,
              ),
              _buildIndexBadge(
                'Electronegativity (χ)',
                '${electronegativity.toStringAsFixed(2)} eV',
                const Color(0xFFFFA726),
                Icons.flash_on_rounded,
              ),
              _buildIndexBadge(
                'Electrophilicity (ω)',
                '${electrophilicity.toStringAsFixed(2)} eV',
                const Color(0xFF26C6DA),
                Icons.compare_arrows_rounded,
              ),
              if (widget.dipoleDebye != null)
                _buildIndexBadge(
                  'Dipole Moment (μ)',
                  '${widget.dipoleDebye!.toStringAsFixed(2)} D',
                  const Color(0xFF42A5F5),
                  Icons.near_me_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitalRow(_OrbitalLevel orb, int index) {
    final isSelected = _selectedOrbitalIndex == index;
    final color = orb.isOccupied ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _selectedOrbitalIndex = _selectedOrbitalIndex == index ? null : index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 65,
              child: Text(
                orb.name,
                style: TextStyle(
                  color: orb.isFrontier ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: orb.isFrontier ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: orb.isFrontier ? 3.5 : 2.0,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: orb.isFrontier
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  if (orb.isOccupied)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131722),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        '↑↓',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131722),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '○',
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 70,
              child: Text(
                '${orb.energyEv.toStringAsFixed(2)} eV',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGapConnector(double gap, double lambdaNm, String spectralName, Color spectralColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 65),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: const Color(0xFF4FC3F7).withValues(alpha: 0.5), width: 1.5),
                  right: BorderSide(color: const Color(0xFF4FC3F7).withValues(alpha: 0.5), width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF4FC3F7)),
                  const SizedBox(width: 4),
                  Text(
                    'HOMO–LUMO Gap: ${gap.toStringAsFixed(2)} eV',
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: spectralColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 70),
        ],
      ),
    );
  }

  Widget _buildIndexBadge(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 9.5),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color) _getSpectralBand(double lambdaNm) {
    if (lambdaNm < 200) return ('Vacuum UV', const Color(0xFF7E57C2));
    if (lambdaNm < 380) return ('Near UV', const Color(0xFF9575CD));
    if (lambdaNm < 450) return ('Violet', const Color(0xFF7C4DFF));
    if (lambdaNm < 495) return ('Blue', const Color(0xFF29B6F6));
    if (lambdaNm < 570) return ('Green', const Color(0xFF66BB6A));
    if (lambdaNm < 590) return ('Yellow', const Color(0xFFFFEE58));
    if (lambdaNm < 620) return ('Orange', const Color(0xFFFFA726));
    if (lambdaNm < 750) return ('Red', const Color(0xFFEF5350));
    return ('Near-IR', const Color(0xFF8D6E63));
  }
}

class _OrbitalLevel {
  final String name;
  final double energyEv;
  final bool isOccupied;
  final bool isFrontier;
  final String description;

  const _OrbitalLevel({
    required this.name,
    required this.energyEv,
    required this.isOccupied,
    this.isFrontier = false,
    required this.description,
  });
}

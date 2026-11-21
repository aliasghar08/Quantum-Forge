// ============================================================================
// DentoLab 3D: Dental Molecular Pharmacology & Therapeutics Bridge Dialog
// ----------------------------------------------------------------------------
// Bridges chairside dental/endodontic/surgical pathology directly to
// Quantum Forge's 3D transition state and chemical reaction engines.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import '../../data/dental_models.dart';

class DentalPharmacologyDialog extends StatefulWidget {
  const DentalPharmacologyDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const DentalPharmacologyDialog(),
    );
  }

  @override
  State<DentalPharmacologyDialog> createState() => _DentalPharmacologyDialogState();
}

class _DentalPharmacologyDialogState extends State<DentalPharmacologyDialog> {
  int _selectedDrugIdx = 0;

  @override
  Widget build(BuildContext context) {
    final drugs = DentalPharmacologyDrug.kDrugs;
    final drug = drugs[_selectedDrugIdx];

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF070C18),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication_liquid_rounded, color: Color(0xFF38BDF8), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Dental Molecular Pharmacology & Local Anesthesia Lab',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Evidence-Based Antimicrobial, Anesthetic & Analgesic Protocols (ADA / AAP / AAE)',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Drug Selector Tabs
            Container(
              color: const Color(0xFF0B132B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(drugs.length, (i) {
                    final isSel = i == _selectedDrugIdx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSel,
                        selectedColor: const Color(0xFF38BDF8),
                        backgroundColor: const Color(0xFF1E293B),
                        label: Text(
                          drugs[i].name.split(' ').first,
                          style: TextStyle(
                            color: isSel ? const Color(0xFF0F172A) : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        onSelected: (_) => setState(() => _selectedDrugIdx = i),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Drug Details Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drug.name,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        drug.classCategory.toUpperCase(),
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSection('Mechanism of Action & Receptor Kinetics (MoA):', drug.mechanismOfAction, Icons.biotech_rounded),
                    const SizedBox(height: 12),
                    _buildSection('Clinical Dental Indication:', drug.dentalIndication, Icons.healing_rounded),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildSection('Standard Dosage & Route:', drug.dosageAndRoute, Icons.local_pharmacy_rounded)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildSection('Maximum Safe Toxic Ceiling:', drug.maxDose, Icons.warning_amber_rounded)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer with 1-Click Link to Quantum Forge 3D Reaction Workspace
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF070C18),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hub_rounded, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Direct Molecular Coupling:',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Open in 3D Reaction Viewer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/aspirin');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

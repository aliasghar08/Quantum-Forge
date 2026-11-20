// ============================================================================
// Differential Diagnosis (DDx) Builder & Socratic Attending Safety Proctor
// ----------------------------------------------------------------------------
// Enables medical students to:
// 1. Rank Top 3 Differential Diagnoses from undifferentiated bedside presentations
// 2. Link supporting clinical evidence tags (POCUS, Vitals, ECG, ABG)
// 3. Place emergency bedside orders (Stat Labs, IV Fluids, Meds, Procedures)
// 4. Intercept life-threatening contraindications via Socratic AI Attending
// 5. Grade encounter out of 100 and launch targeted 3D organ remediation
//
// Strictly Educational Simulation — 7-Pillar SaMD Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import '../../data/ward_rounds_engine.dart';

class WardDdxProctorPanel extends StatefulWidget {
  final WardRoundsEngine engine;
  final VoidCallback? onRemediate;

  const WardDdxProctorPanel({
    super.key,
    required this.engine,
    this.onRemediate,
  });

  @override
  State<WardDdxProctorPanel> createState() => _WardDdxProctorPanelState();
}

class _WardDdxProctorPanelState extends State<WardDdxProctorPanel> {
  BedsideOrderCategory _selectedOrderCategory = BedsideOrderCategory.statLabs;

  static const List<String> availableEvidenceTags = [
    'Hypotension (MAP < 65)',
    'Jugular Venous Distension (JVD)',
    'POCUS Pericardial Effusion',
    'POCUS RV Diastolic Collapse',
    'Plethoric IVC (0% Collapse)',
    'POCUS Absent Lung Sliding',
    'M-Mode Barcode Sign',
    'Electrical Alternans ECG',
    'Peaked T-Waves / Wide QRS',
    'Kussmaul Acidotic Breathing',
    'Cushing Triad (HTN + Bradycardia)',
    'Asymmetric Pupil / Anisocoria',
    'SLUDGEM Cholinergic Signs',
    'Depressed Resp Rate (< 8/min)',
    'Lactate > 4.0 mmol/L',
    'B-Lines Pulmonary Edema',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final activeCase = widget.engine.activeCase;
        final isSubmitted = widget.engine.isCaseSubmitted;

        return Card(
          margin: EdgeInsets.zero,
          color: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Panel Header & Active Case Info
              _buildPanelHeader(activeCase),

              // Safety Interception Banner (if triggered)
              if (widget.engine.hasActiveSafetyAlert)
                _buildSafetyInterceptionBanner(),

              // Body Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top 3 Differential Diagnosis Selector
                      _buildDdxRankingSection(activeCase),
                      const SizedBox(height: 16),

                      // 2. Supporting Clinical Evidence Tags
                      _buildEvidenceTagsSection(),
                      const SizedBox(height: 16),

                      // 3. Bedside Orders Sheet
                      _buildBedsideOrdersSection(),
                      const SizedBox(height: 16),

                      // 4. Placed Orders History Log
                      _buildPlacedOrdersLog(),
                      const SizedBox(height: 20),

                      // 5. Submit or Review Section
                      if (!isSubmitted)
                        _buildSubmitButton()
                      else
                        _buildCaseReviewAndScoring(activeCase),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanelHeader(WardBedsideCase activeCase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              'CASE #${activeCase.caseNumber}',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeCase.triageId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  activeCase.demographic,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Timer Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${(widget.engine.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(widget.engine.elapsedSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyInterceptionBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.engine.activeSafetyAlertTitle ?? 'SAFETY INTERCEPTION',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                onPressed: widget.engine.dismissSafetyAlert,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.engine.activeSafetyAlertRationale ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDdxRankingSection(WardBedsideCase activeCase) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.format_list_numbered_rounded, color: Colors.cyanAccent, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'RANK TOP 3 DIFFERENTIAL DIAGNOSES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Slot 1: Primary Suspect
        _buildDdxSlot(0, '1. Primary Suspect (Most Likely)', Colors.cyanAccent, activeCase),
        const SizedBox(height: 6),
        // Slot 2: Alternative
        _buildDdxSlot(1, '2. Secondary Alternative', Colors.blueAccent, activeCase),
        const SizedBox(height: 6),
        // Slot 3: Must-Rule-Out
        _buildDdxSlot(2, '3. Must-Rule-Out Lethal Threat', Colors.orangeAccent, activeCase),
      ],
    );
  }

  Widget _buildDdxSlot(int slotIndex, String label, Color accentColor, WardBedsideCase activeCase) {
    final currentSelection = widget.engine.top3Ddx[slotIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: currentSelection != null ? accentColor.withValues(alpha: 0.5) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (currentSelection != null)
                GestureDetector(
                  onTap: () => widget.engine.clearDdxSlot(slotIndex),
                  child: const Text('Clear', style: TextStyle(color: Colors.white54, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentSelection,
              isExpanded: true,
              hint: Text(
                'Select diagnosis...',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              dropdownColor: const Color(0xFF0F172A),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: activeCase.differentialOptions.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  widget.engine.setDdxRank(slotIndex, val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.attachment_rounded, color: Colors.cyanAccent, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'LINK SUPPORTING CLINICAL EVIDENCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: availableEvidenceTags.map((tag) {
            final isSelected = widget.engine.selectedEvidenceTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (_) => widget.engine.toggleEvidenceTag(tag),
              labelStyle: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? Colors.cyanAccent : Colors.white70,
              ),
              backgroundColor: const Color(0xFF1E293B),
              selectedColor: Colors.cyan.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: isSelected ? Colors.cyanAccent : Colors.white12,
                ),
              ),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBedsideOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.medication_liquid_rounded, color: Colors.cyanAccent, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'BEDSIDE INTERVENTION & ORDER SHEET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: BedsideOrderCategory.values.map((cat) {
              final isSelected = _selectedOrderCategory == cat;
              String title = '';
              switch (cat) {
                case BedsideOrderCategory.statLabs:
                  title = 'Stat Labs';
                  break;
                case BedsideOrderCategory.ivFluids:
                  title = 'IV Resuscitation';
                  break;
                case BedsideOrderCategory.medications:
                  title = 'Pharmacotherapy';
                  break;
                case BedsideOrderCategory.proceduresAirway:
                  title = 'Procedures & Airway';
                  break;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(title),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedOrderCategory = cat),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.cyanAccent : Colors.white70,
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  selectedColor: Colors.cyan.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: isSelected ? Colors.cyanAccent : Colors.white12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Filtered order list
        ...WardRoundsEngine.catalogOrders
            .where((o) => o.category == _selectedOrderCategory)
            .map((order) {
          final isAlreadyPlaced = widget.engine.placedOrders.any((o) => o.id == order.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAlreadyPlaced ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.name,
                        style: TextStyle(
                          color: isAlreadyPlaced ? Colors.cyanAccent : Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.description,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isAlreadyPlaced
                      ? null
                      : () {
                          widget.engine.placeOrder(order);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    isAlreadyPlaced ? 'ORDERED' : 'EXECUTE',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPlacedOrdersLog() {
    final placed = widget.engine.placedOrders;
    if (placed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIVE ORDERS EXECUTED',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: placed.map((ord) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ord.name,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = widget.engine.top3Ddx[0] != null;

    return ElevatedButton.icon(
      onPressed: canSubmit ? widget.engine.submitCase : null,
      icon: const Icon(Icons.grading_rounded, size: 18),
      label: const Text('SUBMIT CASE FOR ATTENDING REVIEW'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        disabledBackgroundColor: Colors.white12,
        disabledForegroundColor: Colors.white38,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCaseReviewAndScoring(WardBedsideCase activeCase) {
    final score = widget.engine.finalEncounterScore;
    Color scoreColor = Colors.greenAccent;
    if (score < 60) {
      scoreColor = Colors.redAccent;
    } else if (score < 80) {
      scoreColor = Colors.amberAccent;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scoreColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withValues(alpha: 0.15),
                  border: Border.all(color: scoreColor, width: 2),
                ),
                child: Text(
                  '${score.toInt()}',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CLINICAL ENCOUNTER SCORE',
                      style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      score >= 80 ? 'Mastery Passed' : (score >= 60 ? 'Remediation Recommended' : 'Critical Failure'),
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),

          // Revealed Hidden Diagnosis
          const Text(
            'REVEALED DIAGNOSIS',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            activeCase.hiddenDiagnosis,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Pathophysiologic Mechanism
          const Text(
            'PATHOPHYSIOLOGY MECHANISM',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            activeCase.pathophysiologyMechanism,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),

          // USMLE Step 2/3 Pearl
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, color: Colors.amberAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'USMLE / MBBS CLINICAL PEARL',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  activeCase.usmlePearl,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Remediation Launch Button
          ElevatedButton.icon(
            onPressed: widget.onRemediate,
            icon: const Icon(Icons.explore_rounded, size: 16),
            label: Text('LAUNCH TARGETED 3D REMEDIATION (${activeCase.primaryOrganDomain.toUpperCase()})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Next Case Button
          OutlinedButton.icon(
            onPressed: widget.engine.nextCase,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('NEXT UNDIFFERENTIATED CASE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

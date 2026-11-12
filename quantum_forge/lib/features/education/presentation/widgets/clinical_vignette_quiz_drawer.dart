import 'package:flutter/material.dart';
import 'package:quantum_forge/features/education/data/medical_board_qbank.dart';

// ============================================================================
// CLINICAL VIGNETTE QUIZ DRAWER & SM-2 FLASHCARD WORKSTATION
// ----------------------------------------------------------------------------
// Interactive study drawer allowing students to solve 2-step clinical board
// vignettes, rate difficulty using SM-2 spaced repetition, and immediately
// jump into the corresponding 3D procedural/hemodynamic simulation.
// ============================================================================

class ClinicalVignetteQuizDrawer extends StatefulWidget {
  final ValueChanged<ClinicalVignette>? onLaunchSimulation;

  const ClinicalVignetteQuizDrawer({
    super.key,
    this.onLaunchSimulation,
  });

  /// Static helper to open the QBank modal bottom sheet / dialog
  static Future<void> show(
    BuildContext context, {
    ValueChanged<ClinicalVignette>? onLaunchSimulation,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880, maxHeight: 900),
          child: ClinicalVignetteQuizDrawer(onLaunchSimulation: onLaunchSimulation),
        ),
      ),
    );
  }

  @override
  State<ClinicalVignetteQuizDrawer> createState() =>
      _ClinicalVignetteQuizDrawerState();
}

class _ClinicalVignetteQuizDrawerState extends State<ClinicalVignetteQuizDrawer> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _isAnswerSubmitted = false;
  String _searchQuery = '';
  VignetteSpecialty? _filterSpecialty;
  bool _onlyDueCards = false;

  List<ClinicalVignette> get _filteredVignettes {
    return MedicalBoardQBank.vignettes.where((v) {
      if (_onlyDueCards && !MedicalBoardQBank.getCardState(v.id).isDue) {
        return false;
      }
      if (_filterSpecialty != null && v.specialty != _filterSpecialty) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = v.title.toLowerCase().contains(q) ||
            v.vignette.toLowerCase().contains(q) ||
            v.boardKeywords.any((k) => k.toLowerCase().contains(q)) ||
            v.examTags.any((t) => t.toLowerCase().contains(q));
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  void _onOptionSelected(int index) {
    if (_isAnswerSubmitted) return;
    setState(() {
      _selectedOption = index;
      _isAnswerSubmitted = true;
    });
  }

  void _recordSm2Rating(ClinicalVignette vignette, Sm2Rating rating) {
    MedicalBoardQBank.reviewCard(vignette.id, rating);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'SM-2 Review Recorded (${rating.label}) • Next review in ${rating.previewInterval}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _nextCard();
  }

  void _nextCard() {
    final list = _filteredVignettes;
    if (list.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % list.length;
      _selectedOption = null;
      _isAnswerSubmitted = false;
    });
  }

  void _prevCard() {
    final list = _filteredVignettes;
    if (list.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + list.length) % list.length;
      _selectedOption = null;
      _isAnswerSubmitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredVignettes;
    final dueCount = MedicalBoardQBank.getDueCount();

    if (_currentIndex >= filtered.length && filtered.isNotEmpty) {
      _currentIndex = 0;
    }

    final current = filtered.isNotEmpty ? filtered[_currentIndex] : null;
    final cardState = current != null ? MedicalBoardQBank.getCardState(current.id) : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090E17),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header Bar ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Medical Board QBank & SM-2 Spaced Repetition',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (dueCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD600).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFFFD600)),
                                ),
                                child: Text(
                                  '$dueCount Due for Review',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD600),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Text(
                          'USMLE Step 1 & 2 CK • MBBS Final Prof • Pharm-D • NEET-PG High-Yield Vignettes',
                          style: TextStyle(color: Colors.white54, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Search & Filter Controls ───────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFF0C131E),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search clinical keywords, drugs, or ECG findings...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.white54),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              filled: true,
                              fillColor: const Color(0xFF162030),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Due Only Filter Toggle
                      FilterChip(
                        label: Text('Due Only ($dueCount)'),
                        selected: _onlyDueCards,
                        selectedColor: const Color(0xFFFFD600).withValues(alpha: 0.25),
                        backgroundColor: const Color(0xFF162030),
                        labelStyle: TextStyle(
                          color: _onlyDueCards ? const Color(0xFFFFD600) : Colors.white70,
                          fontSize: 10.5,
                          fontWeight: _onlyDueCards ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) => setState(() {
                          _onlyDueCards = val;
                          _currentIndex = 0;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Specialty Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('All Specialties (${MedicalBoardQBank.vignettes.length})'),
                            selected: _filterSpecialty == null,
                            selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                            backgroundColor: const Color(0xFF162030),
                            labelStyle: TextStyle(
                              color: _filterSpecialty == null ? const Color(0xFF10B981) : Colors.white70,
                              fontSize: 10,
                              fontWeight: _filterSpecialty == null ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) => setState(() {
                              _filterSpecialty = null;
                              _currentIndex = 0;
                            }),
                          ),
                        ),
                        ...VignetteSpecialty.values.map((spec) {
                          final isSel = _filterSpecialty == spec;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('${spec.icon} ${spec.label}'),
                              selected: isSel,
                              selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                              backgroundColor: const Color(0xFF162030),
                              labelStyle: TextStyle(
                                color: isSel ? const Color(0xFF00E5FF) : Colors.white70,
                                fontSize: 10,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => setState(() {
                                _filterSpecialty = isSel ? null : spec;
                                _currentIndex = 0;
                              }),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Vignette Content Body ─────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No clinical vignettes match your filter.\nTry clearing filters or search query.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Vignette Header Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981)),
                                ),
                                child: Text(
                                  'CASE #${_currentIndex + 1} OF ${filtered.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...current!.examTags.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Text(
                                      t,
                                      style: const TextStyle(color: Colors.white70, fontSize: 8.5),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (cardState != null)
                                Text(
                                  'SM-2 Reps: ${cardState.repetitions} | Interval: ${cardState.intervalDays.toStringAsFixed(1)}d',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Vignette Title
                          Text(
                            current.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Clinical Vignette Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131D2E),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              current.vignette,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Question Text
                          Text(
                            current.question,
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 4 Multiple Choice Options
                          ...List.generate(current.options.length, (idx) {
                            final optionText = current.options[idx];
                            final isSelected = _selectedOption == idx;
                            final isCorrect = current.correctIndex == idx;

                            Color tileBorder = Colors.white12;
                            Color tileBg = const Color(0xFF111827);
                            Color textCol = Colors.white70;

                            if (_isAnswerSubmitted) {
                              if (isCorrect) {
                                tileBorder = const Color(0xFF00E676);
                                tileBg = const Color(0xFF00E676).withValues(alpha: 0.15);
                                textCol = const Color(0xFF00E676);
                              } else if (isSelected) {
                                tileBorder = const Color(0xFFFF1744);
                                tileBg = const Color(0xFFFF1744).withValues(alpha: 0.15);
                                textCol = const Color(0xFFFF5252);
                              }
                            } else if (isSelected) {
                              tileBorder = const Color(0xFF00E5FF);
                              tileBg = const Color(0xFF00E5FF).withValues(alpha: 0.15);
                              textCol = Colors.white;
                            }

                            final optionLetters = ['A', 'B', 'C', 'D'];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _onOptionSelected(idx),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: tileBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: tileBorder, width: isSelected || (_isAnswerSubmitted && isCorrect) ? 1.5 : 1.0),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? (_isAnswerSubmitted && isCorrect
                                                  ? const Color(0xFF00E676)
                                                  : (_isAnswerSubmitted ? const Color(0xFFFF1744) : const Color(0xFF00E5FF)))
                                              : Colors.white12,
                                        ),
                                        child: Center(
                                          child: Text(
                                            optionLetters[idx],
                                            style: TextStyle(
                                              color: isSelected ? Colors.black : Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          optionText,
                                          style: TextStyle(
                                            color: textCol,
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (_isAnswerSubmitted && isCorrect)
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 18),
                                      if (_isAnswerSubmitted && isSelected && !isCorrect)
                                        const Icon(Icons.cancel_rounded, color: Color(0xFFFF1744), size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Explanation & Rationale (Revealed upon answer selection)
                          if (_isAnswerSubmitted) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1B2A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedOption == current.correctIndex
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFFFF9100),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _selectedOption == current.correctIndex
                                            ? Icons.check_circle_rounded
                                            : Icons.lightbulb_rounded,
                                        color: _selectedOption == current.correctIndex
                                            ? const Color(0xFF00E676)
                                            : const Color(0xFFFFD600),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedOption == current.correctIndex
                                            ? 'CORRECT! HIGH-YIELD CLINICAL RATIONALE:'
                                            : 'INCORRECT — CLINICAL BOARD EXPLANATION:',
                                        style: TextStyle(
                                          color: _selectedOption == current.correctIndex
                                              ? const Color(0xFF00E676)
                                              : const Color(0xFFFFD600),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    current.explanation,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // High Yield Keywords
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: current.boardKeywords.map((k) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          k,
                                          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 9.5),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // SM-2 Spaced Repetition Self-Assessment Bar
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141F30),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFA78BFA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.history_edu_rounded, color: Color(0xFFA78BFA), size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'SM-2 Spaced Repetition Self-Assessment (Schedule Next Review):',
                                        style: TextStyle(
                                          color: Color(0xFFA78BFA),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: Sm2Rating.values.map((rating) {
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: rating == Sm2Rating.again
                                                  ? const Color(0xFFEF4444)
                                                  : (rating == Sm2Rating.hard
                                                      ? const Color(0xFFF59E0B)
                                                      : (rating == Sm2Rating.good
                                                          ? const Color(0xFF10B981)
                                                          : const Color(0xFF3B82F6))),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            onPressed: () => _recordSm2Rating(current, rating),
                                            child: Column(
                                              children: [
                                                Text(
                                                  rating.label,
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  rating.previewInterval,
                                                  style: const TextStyle(fontSize: 8.5, color: Colors.white70),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),

            // ── Bottom Navigation & 3D Launch Bar ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back_rounded, size: 14),
                    label: const Text('Previous Case'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    onPressed: filtered.isNotEmpty ? _prevCard : null,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('Next Case'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    onPressed: filtered.isNotEmpty ? _nextCard : null,
                  ),
                  const Spacer(),

                  // Launch 3D Simulation Button
                  if (current != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_filled_rounded, color: Colors.black, size: 18),
                      label: const Text('🚀 Launch 3D Simulation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onLaunchSimulation?.call(current);
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
}

// ============================================================================
// Hybrid MLIP → DFT workflow card
// ----------------------------------------------------------------------------
// MLIP screens; DFT refines. The DFT itself runs externally (ORCA/Gaussian on a
// cluster), so this card covers the handoff and the comparison:
//   * export the transition state as <reaction_id>_mlip_ts.xyz
//   * attach DFT results (any number of levels of theory)
//   * compare MLIP vs DFT barriers side by side
//   * emit a LaTeX-ready methods sentence
// ============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:quantum_forge/core/services/backend_compute_service.dart';
import 'package:quantum_forge/core/services/file_picker_service.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/core/utils/avogadro_bridge.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';

/// Builds the LaTeX-ready methods sentence.
///
/// Kept as a pure function so it can be tested without a widget, and so the exact
/// wording lives in one place.
///
/// The screening step is attributed to the MACHINE-LEARNED POTENTIAL only. An
/// earlier template read "MLIP-MLIP screening used {model} at the {method} level of
/// theory", which attributes a DFT functional and basis set to a machine-learned
/// interatomic potential — MLIP has no DFT level of theory.
String buildMethodsParagraph({
  required String model,
  required String method,
  required String solvent,
  String? singlePointMethod,
}) {
  final dft = method.trim().isEmpty ? '<DFT level of theory>' : method.trim();

  // A separate single-point level is claimed ONLY when one was supplied. It is
  // deliberately not defaulted to the geometry level: an absent value means no
  // separate single-point run happened, so the sentence is omitted rather than
  // fabricated.
  final sp = singlePointMethod?.trim() ?? '';
  final singlePoint =
      sp.isEmpty ? '' : 'Single-point energies were computed at $sp.';

  // Solvation clause is omitted entirely when no solvent was chosen, rather than
  // emitting a sentence about vacuum "solvation".
  final solventName = solvent.trim();
  final hasSolvent = solventName.isNotEmpty &&
      solventName.toLowerCase() != 'vacuum' &&
      solventName.toLowerCase() != 'none';
  final solvation = hasSolvent
      ? 'Implicit solvation was modeled with SMD ($solventName). '
      : '';

  return ('Screening was performed with the $model machine-learned interatomic '
          'potential. Transition state geometries were refined at the $dft level '
          'of theory. $solvation$singlePoint')
      .trim();
}

/// Difference beyond which MLIP is no longer considered reliable for a system.
const double kMlipReliableDeltaKcal = 5.0;

enum DftWorkflowTab {
  export,
  attach,
  comparison,
  methods,
}

class DftWorkflowCard extends StatefulWidget {
  final ReactionStatusResponse status;
  final String backendUrl;
  final String mlipModel;
  final String solvent;
  final void Function(String message) onNotify;
  final void Function(String message) onError;

  const DftWorkflowCard({
    super.key,
    required this.status,
    required this.backendUrl,
    required this.mlipModel,
    required this.solvent,
    required this.onNotify,
    required this.onError,
  });

  @override
  State<DftWorkflowCard> createState() => _DftWorkflowCardState();
}

class _DftWorkflowCardState extends State<DftWorkflowCard> {
  /// Attachments added in this session. Merged with whatever the status reports so
  /// a fresh poll cannot make a just-attached result disappear.
  final List<DftAttachment> _attachedHere = [];
  bool _busy = false;
  DftWorkflowTab _currentTab = DftWorkflowTab.export;

  List<DftAttachment> get _all {
    final fromStatus = widget.status.dftAttachments;
    final known = fromStatus.map((a) => a.attachmentId).toSet();
    return [
      ...fromStatus,
      ..._attachedHere.where((a) => !known.contains(a.attachmentId)),
    ];
  }

  bool get _hasBackend => widget.backendUrl.trim().isNotEmpty;

  Future<void> _exportTs() async {
    if (!_hasBackend) {
      widget.onError('No compute backend configured — set the backend URL in Settings.');
      return;
    }
    setState(() => _busy = true);
    try {
      final xyz = await const BackendComputeService()
          .exportTransitionState(widget.backendUrl, widget.status.reactionId);
      final modelSafe = widget.mlipModel.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      AvogadroBridge.download(
        '${widget.status.reactionId}_${modelSafe}_ts.xyz',
        xyz,
        mimeType: 'chemical/x-xyz',
      );
      widget.onNotify('Exported ${widget.status.reactionId}_${modelSafe}_ts.xyz');
    } catch (e) {
      widget.onError('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAttachDialog() async {
    if (!_hasBackend) {
      widget.onError('No compute backend configured — set the backend URL in Settings.');
      return;
    }
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _AttachDftDialog(),
    );
    if (result == null) return;

    setState(() => _busy = true);
    try {
      final attachment = await const BackendComputeService()
          .attachDft(widget.backendUrl, widget.status.reactionId, result);
      if (!mounted) return;
      setState(() {
        _attachedHere.add(attachment);
        _currentTab = DftWorkflowTab.comparison;
      });
      widget.onNotify(
        attachment.hasBarrier
            ? 'DFT result attached — barrier ${attachment.barrierKcalMol!.toStringAsFixed(1)} kcal·mol⁻¹'
            : 'DFT result attached (no barrier: needs both Hartree energies).',
      );
    } catch (e) {
      widget.onError('Attach failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final attachments = _all;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 18, color: palette.accent),
              const SizedBox(width: 8),
              const Text('MLIP → DFT workflow',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_busy)
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.mlipModel} is a screening method. Publication requires DFT refinement of TS '
            'geometries — export the geometry, run it on the cluster, then attach the '
            'result here.',
            style: TextStyle(
                color: palette.textMuted, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 14),

          // Modern Interactive Workflow Tabs
          _buildWorkflowTabs(palette, attachments),
          const SizedBox(height: 14),

          // Active Tab Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildActiveTabContent(palette, attachments),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowTabs(QuantumTheme palette, List<DftAttachment> attachments) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0C101C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _tabButton(
              tab: DftWorkflowTab.export,
              label: 'Export for DFT',
              icon: Icons.download_outlined,
              palette: palette,
            ),
            const SizedBox(width: 4),
            _tabButton(
              tab: DftWorkflowTab.attach,
              label: 'Attach Result',
              icon: Icons.upload_file_outlined,
              badge: attachments.isNotEmpty ? '${attachments.length}' : null,
              palette: palette,
            ),
            const SizedBox(width: 4),
            _tabButton(
              tab: DftWorkflowTab.comparison,
              label: 'Barrier Comparison',
              icon: Icons.compare_arrows_rounded,
              badge: attachments.isNotEmpty ? 'Active' : null,
              palette: palette,
            ),
            const SizedBox(width: 4),
            _tabButton(
              tab: DftWorkflowTab.methods,
              label: 'Methods Paragraph',
              icon: Icons.article_outlined,
              palette: palette,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required DftWorkflowTab tab,
    required String label,
    required IconData icon,
    String? badge,
    required QuantumTheme palette,
  }) {
    final active = _currentTab == tab;
    return InkWell(
      onTap: () => setState(() => _currentTab = tab),
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? palette.accent.withValues(alpha: 0.20) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: active
              ? Border.all(color: palette.accent.withValues(alpha: 0.50))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? palette.accent : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? Colors.white : Colors.grey.shade400,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: active ? palette.accent : Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.black : Colors.white70,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(QuantumTheme palette, List<DftAttachment> attachments) {
    switch (_currentTab) {
      case DftWorkflowTab.export:
        return _buildExportTab(palette);
      case DftWorkflowTab.attach:
        return _buildAttachTab(palette, attachments);
      case DftWorkflowTab.comparison:
        return _buildComparisonTab(palette, attachments);
      case DftWorkflowTab.methods:
        return _buildMethodsTab(palette, attachments);
    }
  }

  Widget _buildExportTab(QuantumTheme palette) {
    final modelSafe = widget.mlipModel.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final filename = '${widget.status.reactionId}_${modelSafe}_ts.xyz';

    return Container(
      key: const ValueKey('export_tab'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101524),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transition State Coordinates · $filename',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Exports the exact machine-learned saddle point structure in standard .xyz format '
            'ready for high-precision quantum chemical refinement (ORCA, Gaussian, Q-Chem, or PySCF).',
            style: TextStyle(color: palette.textMuted, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : _exportTs,
            icon: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.download_rounded, size: 16),
            label: const Text('Export .xyz for DFT Calculation'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachTab(QuantumTheme palette, List<DftAttachment> attachments) {
    return Container(
      key: const ValueKey('attach_tab'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101524),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.greenAccent),
              const SizedBox(width: 8),
              const Text(
                'Cluster Refinement Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (attachments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${attachments.length} Attached',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Attach single-point Hartrees, transition state frequencies, or output logs (.log, .out, .txt) '
            'to compute barrier deviations against surrogate MLIP screening.',
            style: TextStyle(color: palette.textMuted, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _busy ? null : _openAttachDialog,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('Attach DFT Result / Output Log'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
              foregroundColor: palette.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab(QuantumTheme palette, List<DftAttachment> attachments) {
    if (attachments.isEmpty) {
      return Container(
        key: const ValueKey('comparison_empty'),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF101524),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.compare_arrows_rounded, size: 34, color: Colors.grey.shade600),
              const SizedBox(height: 10),
              const Text(
                'No DFT Results Attached Yet',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Attach completed DFT results to inspect side-by-side barrier comparisons and calibration deviations.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textMuted, fontSize: 11.5),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => setState(() => _currentTab = DftWorkflowTab.attach),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('Go to Attach Result'),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      key: const ValueKey('comparison_table'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101524),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: _ComparisonTable(
        attachments: attachments,
        mlipProfile: widget.status.energyProfile ?? const [],
      ),
    );
  }

  Widget _buildMethodsTab(QuantumTheme palette, List<DftAttachment> attachments) {
    final method = attachments.isNotEmpty ? attachments.last.levelOfTheory : '<DFT level of theory>';
    final sp = attachments.isNotEmpty ? attachments.last.singlePointMethod : null;
    final paragraph = buildMethodsParagraph(
      model: widget.mlipModel,
      method: method,
      solvent: widget.solvent,
      singlePointMethod: sp,
    );

    return Container(
      key: const ValueKey('methods_tab'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101524),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              const Text(
                'Publication Methods Statement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: paragraph));
                  widget.onNotify('Methods paragraph copied to the clipboard.');
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy to Clipboard', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: SelectableText(
              paragraph,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// MLIP vs DFT, one row per attached level of theory.
class _ComparisonTable extends StatelessWidget {
  final List<DftAttachment> attachments;

  /// MLIP relative profile (ΔE vs reactant, kcal/mol). The MLIP barrier is its
  /// highest point.
  final List<double> mlipProfile;

  const _ComparisonTable({required this.attachments, required this.mlipProfile});

  double? get _mlipBarrierKcal {
    if (mlipProfile.isEmpty) return null;
    return mlipProfile.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MLIP vs DFT barrier',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(
              color: Colors.white.withValues(alpha: 0.10), width: 1),
          columnWidths: const {
            0: FlexColumnWidth(2.4),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.0),
          },
          children: [
            _headerRow(),
            for (final a in attachments)
              ..._dataRows(a, palette.danger, palette.success),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Δ is MLIP − DFT. |Δ| > ${kMlipReliableDeltaKcal.toStringAsFixed(0)} kcal·mol⁻¹ '
          'means the system is outside the range where MLIP is trusted.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45), fontSize: 10.5),
        ),
      ],
    );
  }

  TableRow _headerRow() => TableRow(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04)),
        children: const [
          _Cell('DFT level of theory', bold: true),
          _Cell('MLIP (kcal·mol⁻¹)', bold: true),
          _Cell('DFT (kcal·mol⁻¹)', bold: true),
          _Cell('Δ', bold: true),
        ],
      );

  List<TableRow> _dataRows(DftAttachment a, Color danger, Color ok) {
    final mlip = _mlipBarrierKcal;
    final dft = a.barrierKcalMol;
    final delta = (mlip != null && dft != null) ? mlip - dft : null;
    final unreliable = delta != null && delta.abs() > kMlipReliableDeltaKcal;

    return [
      TableRow(children: [
        _Cell(a.displayLevel),
        _Cell(mlip == null ? '—' : mlip.toStringAsFixed(1)),
        _Cell(dft == null ? '— (needs both energies)' : dft.toStringAsFixed(1)),
        _Cell(
          delta == null
              ? '—'
              : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
          color: delta == null ? null : (unreliable ? danger : ok),
          bold: true,
        ),
      ]),
      if (unreliable)
        TableRow(children: [
          _Cell(
            "Outside MLIP's reliable range (|Δ| > "
            '${kMlipReliableDeltaKcal.toStringAsFixed(0)} kcal·mol⁻¹)',
            color: danger,
            span: true,
          ),
          const _Cell(''),
          const _Cell(''),
          const _Cell(''),
        ]),
      if (a.imaginaryFrequencyCm1 != null || a.notes.isNotEmpty)
        TableRow(children: [
          _Cell(
            [
              if (a.imaginaryFrequencyCm1 != null)
                'ν‡ = ${a.imaginaryFrequencyCm1!.toStringAsFixed(1)} cm⁻¹',
              if (a.notes.isNotEmpty) a.notes,
            ].join(' · '),
            span: true,
          ),
          const _Cell(''),
          const _Cell(''),
          const _Cell(''),
        ]),
    ];
  }
}

/// A table cell; `span` fields are informational and left-aligned.
class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final bool span;

  const _Cell(this.text, {this.bold = false, this.color, this.span = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.white.withValues(alpha: span ? 0.6 : 0.85),
          fontSize: span ? 11 : 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );
  }
}

/// Collects the DFT fields. Returns the request body, or null when cancelled.
class _AttachDftDialog extends StatefulWidget {
  const _AttachDftDialog();

  @override
  State<_AttachDftDialog> createState() => _AttachDftDialogState();
}

class _AttachDftDialogState extends State<_AttachDftDialog> {
  final _ts = TextEditingController();
  final _reactant = TextEditingController();
  final _imaginary = TextEditingController();
  final _method = TextEditingController();
  final _notes = TextEditingController();
  final _logName = TextEditingController();
  final _logText = TextEditingController();
  final _singlePoint = TextEditingController();
  String? _validation;

  @override
  void dispose() {
    for (final c in [
      _ts,
      _reactant,
      _imaginary,
      _method,
      _notes,
      _logName,
      _logText,
      _singlePoint,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _number(TextEditingController c) {
    final raw = c.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  /// Accepted cluster-output types and the upload ceiling.
  static const List<String> _logExtensions = ['.log', '.out', '.txt'];
  static const int _maxLogBytes = 5 * 1024 * 1024;

  /// Reads a .log/.out/.txt file into the SAME text field the paste path uses, so
  /// one downstream parser will serve both. Stores the original filename.
  Future<void> _pickLogFile() async {
    try {
      final picked = await FilePickerService().pickAnyFile();
      if (picked == null) return; // cancelled

      final name = picked.name;
      final lower = name.toLowerCase();
      if (!_logExtensions.any(lower.endsWith)) {
        setState(() => _validation =
            'Unsupported file "$name" — choose a .log, .out or .txt file.');
        return;
      }
      if (picked.size > _maxLogBytes) {
        setState(() => _validation =
            'That file is ${(picked.size / 1048576).toStringAsFixed(1)} MB; '
            'the limit is 5 MB.');
        return;
      }

      final bytes = picked.bytes;
      if (bytes == null) {
        setState(() => _validation = 'Could not read "$name" — no bytes returned.');
        return;
      }
      final text = utf8.decode(bytes, allowMalformed: true);
      if (text.trim().isEmpty) {
        setState(() => _validation = 'That file is empty — nothing to attach.');
        return;
      }

      setState(() {
        _validation = null;
        _logName.text = name;
        _logText.text = text;
      });
    } catch (e) {
      setState(() => _validation = 'Could not read that file: $e');
    }
  }

  void _submit() {
    final ts = _number(_ts);
    final reactant = _number(_reactant);
    // One energy without the other cannot give a barrier, and half the fields
    // entered usually means the paste went into the wrong box.
    if ((ts == null) != (reactant == null)) {
      setState(() => _validation =
          'A barrier needs BOTH energies — enter the TS and reactant Hartrees, or neither.');
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{
      'level_of_theory': _method.text.trim(),
      'ts_energy_hartree': ts,
      'reactant_energy_hartree': reactant,
      'imaginary_frequency_cm1': _number(_imaginary),
      'notes': _notes.text.trim(),
      'single_point_method':
          _singlePoint.text.trim().isEmpty ? null : _singlePoint.text.trim(),
      'log_file_name': _logName.text.trim().isEmpty ? null : _logName.text.trim(),
      'log_file_text': _logText.text.trim().isEmpty ? null : _logText.text,
    });
  }

  Widget _field(TextEditingController c, String label,
      {String? hint, String? helper, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: lines,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 3,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attach DFT result'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_method, 'DFT level of theory', hint: 'e.g. ωB97X-D/def2-TZVP'),
              // A separate single-point level is usually a higher level than the
              // geometry method. Left blank it produces NO single-point sentence in
              // the methods paragraph — the value is never defaulted to the geometry
              // level.
              _field(
                _singlePoint,
                'Single-point method (optional)',
                hint: 'e.g. DLPNO-CCSD(T)/def2-QZVP',
                helper: 'Leave blank if no separate single-point calculation was '
                    'performed. This is usually a higher level than the geometry '
                    'method.',
              ),
              _field(_ts, 'DFT energy of TS (Hartree)', hint: '-1538.000000'),
              _field(_reactant, 'DFT energy of reactant (Hartree)', hint: '-1538.060000'),
              _field(_imaginary, 'Imaginary frequency (cm⁻¹)', hint: '-1180.0'),
              _field(_notes, 'Notes', lines: 2),
              const Divider(height: 20),
              const Text('Optional ORCA / Gaussian output',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickLogFile,
                    icon: const Icon(Icons.upload_file, size: 15),
                    label: const Text('Choose .log file',
                        style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('.log, .out or .txt · max 5 MB · read into the '
                        'field below',
                        style: TextStyle(fontSize: 10.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field(_logName, 'Output file name', hint: 'ts_freq.out'),
              _field(_logText, 'Paste, or load a file above (kept for later parsing)',
                  lines: 4),
              if (_validation != null)
                Text(_validation!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11.5)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Attach')),
      ],
    );
  }
}

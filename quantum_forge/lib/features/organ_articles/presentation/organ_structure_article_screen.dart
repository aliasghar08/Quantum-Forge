// ============================================================================
// Organ Structure Article Screen — In-App Scientific Article & Literature Reader
// ----------------------------------------------------------------------------
// Full-screen native monograph reader with live PubMed, CrossRef, OpenAlex,
// and Europe PMC literature integration for 3D anatomical structures.
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/organ_literature_service.dart';
import '../../../../core/services/url_service.dart';

class OrganStructureArticleScreen extends StatefulWidget {
  final String structureId;
  final String structureName;
  final String organSystem;
  final String? latinName;
  final String? bloodSupply;
  final String? innervation;
  final String? contextPearl;
  final OrganLiteratureService? service;

  const OrganStructureArticleScreen({
    super.key,
    required this.structureId,
    required this.structureName,
    required this.organSystem,
    this.latinName,
    this.bloodSupply,
    this.innervation,
    this.contextPearl,
    this.service,
  });

  /// Standard route constructor for Flutter navigation.
  static MaterialPageRoute<void> route({
    required String structureId,
    required String structureName,
    required String organSystem,
    String? latinName,
    String? bloodSupply,
    String? innervation,
    String? contextPearl,
  }) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: '/organ-article?id=$structureId&name=${Uri.encodeComponent(structureName)}&system=${Uri.encodeComponent(organSystem)}',
      ),
      builder: (_) => OrganStructureArticleScreen(
        structureId: structureId,
        structureName: structureName,
        organSystem: organSystem,
        latinName: latinName,
        bloodSupply: bloodSupply,
        innervation: innervation,
        contextPearl: contextPearl,
      ),
    );
  }

  /// Pushes the article screen directly onto the navigation stack.
  static Future<void> open(
    BuildContext context, {
    required String structureId,
    required String structureName,
    required String organSystem,
    String? latinName,
    String? bloodSupply,
    String? innervation,
    String? contextPearl,
  }) {
    return Navigator.of(context).push(
      route(
        structureId: structureId,
        structureName: structureName,
        organSystem: organSystem,
        latinName: latinName,
        bloodSupply: bloodSupply,
        innervation: innervation,
        contextPearl: contextPearl,
      ),
    );
  }

  @override
  State<OrganStructureArticleScreen> createState() => _OrganStructureArticleScreenState();
}

class _OrganStructureArticleScreenState extends State<OrganStructureArticleScreen> {
  late final OrganLiteratureService _service;
  late final OrganStructureMonograph _monograph;
  List<VerifiedResearchReference> _liveReferences = [];
  bool _isLoadingLive = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? OrganLiteratureService();
    _monograph = OrganLiteratureService.getCuratedMonograph(
      structureId: widget.structureId,
      structureName: widget.structureName,
      organSystem: widget.organSystem,
      latinName: widget.latinName,
      bloodSupply: widget.bloodSupply,
      innervation: widget.innervation,
      contextPearl: widget.contextPearl,
    );

    _loadLiveLiterature();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadLiveLiterature() async {
    final query = '${_monograph.structureName} ${_monograph.organSystem}';
    try {
      final results = await _service.fetchLiveLiterature(query, limit: 4);
      if (mounted) {
        setState(() {
          _liveReferences = results;
          _isLoadingLive = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLive = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final combinedRefs = OrganArticleResult(
      monograph: _monograph,
      liveReferences: _liveReferences,
      isLoadingLive: _isLoadingLive,
    ).allReferences;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0D1424) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const Key('organ_article_back_button'),
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          tooltip: 'Back to 3D Viewport',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
              ),
              child: Text(
                _monograph.organSystem.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _monograph.structureName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: subtextColor,
            tooltip: 'Re-fetch PubMed & CrossRef Literature',
            onPressed: () {
              setState(() => _isLoadingLive = true);
              _loadLiveLiterature();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Permanent SaMD 7-Pillar Legal Shield Banner ─────────────
                  _buildLegalShieldBanner(isDark),
                  const SizedBox(height: 16),

                  // ── Header Anatomy & Provenance Card ─────────────────────────
                  _buildHeaderCard(cardBg, borderColor, textColor, subtextColor),
                  const SizedBox(height: 16),

                  // ── Monograph Section 1: Gross & Micro Anatomy ───────────────
                  _buildMonographCard(
                    title: '1. Gross & Micro-Anatomical Architecture',
                    icon: Icons.account_tree_rounded,
                    accentColor: const Color(0xFF38BDF8),
                    body: _monograph.grossMicroAnatomy,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 14),

                  // ── Monograph Section 2: Biophysics & Hemodynamics ───────────
                  _buildMonographCard(
                    title: '2. Physiology, Biophysics & Hemodynamics',
                    icon: Icons.speed_rounded,
                    accentColor: const Color(0xFF10B981),
                    body: _monograph.biophysicsHemodynamics,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 14),

                  // ── Monograph Section 3: Pathophysiology & Clinical ──────────
                  _buildMonographCard(
                    title: '3. Pathophysiology & Clinical Correlations',
                    icon: Icons.healing_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    body: _monograph.pathophysiologyClinical,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 14),

                  // ── Monograph Section 4: Pharmacological & Interventions ──────
                  _buildMonographCard(
                    title: '4. Pharmacological & Interventional Targets',
                    icon: Icons.medication_rounded,
                    accentColor: const Color(0xFFA855F7),
                    body: _monograph.pharmacologicalInterventions,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 24),

                  // ── Multi-Source Verified Research Articles ──────────────────
                  _buildResearchLiteratureSection(
                    combinedRefs: combinedRefs,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // ── Bottom Permanent Disclaimer ──────────────────────────────
                  _buildLegalShieldBanner(isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header Card ───────────────────────────────────────────────────────────
  Widget _buildHeaderCard(Color cardBg, Color borderColor, Color textColor, Color subtextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monograph.structureName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_monograph.latinName != null && _monograph.latinName!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _monograph.latinName!,
                        style: TextStyle(
                          color: const Color(0xFF00E5FF),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'Verified Monograph',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vascular & Innervation Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_monograph.bloodSupply != null && _monograph.bloodSupply!.isNotEmpty)
                _buildPill(
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFFEF4444),
                  label: 'Perfusion: ${_monograph.bloodSupply!}',
                ),
              if (_monograph.innervation != null && _monograph.innervation!.isNotEmpty)
                _buildPill(
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFFF59E0B),
                  label: 'Innervation: ${_monograph.innervation!}',
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Provenance Badges
          Row(
            children: [
              Text(
                'Data Provenance:',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildSourceChip('PubMed (NCBI)', const Color(0xFF2563EB)),
                    _buildSourceChip('CrossRef', const Color(0xFFD97706)),
                    _buildSourceChip('OpenAlex', const Color(0xFF059669)),
                    _buildSourceChip('Europe PMC', const Color(0xFF7C3AED)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill({required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Monograph Section Card ────────────────────────────────────────────────
  Widget _buildMonographCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required String body,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ── Peer-Reviewed Research Articles Section ───────────────────────────────
  Widget _buildResearchLiteratureSection({
    required List<VerifiedResearchReference> combinedRefs,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.library_books_rounded, size: 18, color: Color(0xFF00E5FF)),
                const SizedBox(width: 8),
                Text(
                  'Peer-Reviewed Literature & Landmark Studies',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_isLoadingLive)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Multi-source indexed citations from PubMed (NCBI), CrossRef, OpenAlex, and Europe PMC. Tap "Read on Web ↗" to view the authoritative publication.',
          style: TextStyle(
            color: subtextColor,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 12),

        if (combinedRefs.isEmpty && !_isLoadingLive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              _errorMessage != null
                  ? 'Live literature lookup paused ($_errorMessage). Refer to the verified monograph above.'
                  : 'No indexed articles found for this exact query. Refer to the verified monograph above.',
              style: TextStyle(color: subtextColor, fontSize: 12),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: combinedRefs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ref = combinedRefs[index];
              return _buildReferenceCard(
                ref: ref,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
              );
            },
          ),
      ],
    );
  }

  Widget _buildReferenceCard({
    required VerifiedResearchReference ref,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ref.source.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: ref.source.badgeColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  ref.source.displayName,
                  style: TextStyle(
                    color: ref.source.badgeColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (ref.year != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ref.year.toString(),
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              ElevatedButton.icon(
                key: Key('open_article_${ref.doi ?? ref.pmid ?? ref.title.hashCode}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  foregroundColor: const Color(0xFF00E5FF),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 12),
                label: const Text(
                  'Read on Web ↗',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () => UrlService.launch(ref.targetUrl),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            ref.title,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),

          // Citation
          Text(
            ref.citation,
            style: TextStyle(
              color: subtextColor,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),

          if (ref.doi != null || ref.pmid != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                if (ref.pmid != null)
                  Text(
                    'PMID: ${ref.pmid}',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                if (ref.doi != null)
                  Text(
                    'DOI: ${ref.doi}',
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Permanent SaMD 7-Pillar Legal Shield Banner ───────────────────────────
  Widget _buildLegalShieldBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: Color(0xFFFFB300)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Educational & Research Simulation Only — Not for Clinical Diagnosis, Surgical Planning, or Patient Care. '
              'Quantum-Forge Software as a Medical Device (SaMD) Research Sandbox.',
              style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

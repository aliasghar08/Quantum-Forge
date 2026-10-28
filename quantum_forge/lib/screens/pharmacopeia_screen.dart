// ============================================================================
// Clinical & Veterinary Pharmacopeia Screen — Research-Grade Compendium
// For MBBS, Pharm-D, DVM and Clinical Specialist Practitioners.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';
import 'package:quantum_forge/features/pharmacopeia/data/pharmacopeia_repository.dart';
import 'package:quantum_forge/features/pharmacopeia/presentation/widgets/dossier_detail_dialog.dart';

class PharmacopeiaScreen extends StatefulWidget {
  final void Function(String reactionId)? onLoadReaction;

  const PharmacopeiaScreen({super.key, this.onLoadReaction});

  @override
  State<PharmacopeiaScreen> createState() => _PharmacopeiaScreenState();
}

class _PharmacopeiaScreenState extends State<PharmacopeiaScreen> {
  final PharmacopeiaRepository _repository = PharmacopeiaRepository();
  final TextEditingController _searchController = TextEditingController();

  TargetDiscipline? _selectedDiscipline;
  PharmacologicalSpecialty? _selectedSpecialty;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    await _repository.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeNotifier>().palette;
    final filteredProfiles = _repository.filter(
      discipline: _selectedDiscipline,
      specialty: _selectedSpecialty,
      query: _searchQuery,
    );

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(palette),
          _buildSliverFilterControls(palette),
          if (filteredProfiles.isEmpty)
            _buildEmptyState(palette)
          else
            _buildDossiersGrid(filteredProfiles, palette),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(dynamic palette) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: BoxDecoration(
          color: palette.panel,
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00BFA5)),
                  ),
                  child: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF00BFA5), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Clinical & Veterinary Pharmacopeia',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'RESEARCH LEVEL',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comprehensive educational & research compendium for MBBS, Pharm-D, DVM & Clinical Specialists. Covering origins, molecular targets, modes of action (MoA), comparative ADME, and active-site quantum transition states.',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Metrics bar
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetricChip(
                  icon: Icons.menu_book_outlined,
                  label: '${_repository.allProfiles.length} Research Dossiers',
                  color: const Color(0xFF00E676),
                  palette: palette,
                ),
                _buildMetricChip(
                  icon: Icons.hub_outlined,
                  label: '7 Clinical & Veterinary Specialties',
                  color: const Color(0xFF2979FF),
                  palette: palette,
                ),
                _buildMetricChip(
                  icon: Icons.psychology_outlined,
                  label: 'PharmaBioNet v1 (MPS Trained & Verified)',
                  color: const Color(0xFFFF9100),
                  palette: palette,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
    required dynamic palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.scaffold.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSliverFilterControls(dynamic palette) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: palette.panel.withValues(alpha: 0.5),
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by generic name, brand, indication, molecular target, or mechanism...',
                hintStyle: TextStyle(color: palette.textMuted, fontSize: 12.5),
                prefixIcon: Icon(Icons.search, size: 18, color: palette.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: palette.scaffold,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: palette.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: palette.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BFA5))),
              ),
            ),
            const SizedBox(height: 12),

            // Discipline & Specialty Filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Curriculum:', style: TextStyle(color: palette.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                _filterChip(
                  label: 'All Curricula',
                  isSelected: _selectedDiscipline == null,
                  onSelected: () => setState(() => _selectedDiscipline = null),
                  palette: palette,
                ),
                _filterChip(
                  label: '🩺 MBBS',
                  isSelected: _selectedDiscipline == TargetDiscipline.mbbs,
                  onSelected: () => setState(() => _selectedDiscipline = TargetDiscipline.mbbs),
                  palette: palette,
                ),
                _filterChip(
                  label: '💊 Pharm-D',
                  isSelected: _selectedDiscipline == TargetDiscipline.pharmD,
                  onSelected: () => setState(() => _selectedDiscipline = TargetDiscipline.pharmD),
                  palette: palette,
                ),
                _filterChip(
                  label: '🐾 DVM (Veterinary)',
                  isSelected: _selectedDiscipline == TargetDiscipline.dvm,
                  onSelected: () => setState(() => _selectedDiscipline = TargetDiscipline.dvm),
                  palette: palette,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Specialties
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text('Specialty: ', style: TextStyle(color: palette.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  _specialtyChip('All Specialties', null, palette),
                  ...PharmacologicalSpecialty.values.map((s) => _specialtyChip('${s.icon} ${s.label}', s, palette)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required dynamic palette,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BFA5) : palette.scaffold,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF00BFA5) : palette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : palette.textSecondary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _specialtyChip(String label, PharmacologicalSpecialty? specialty, dynamic palette) {
    final isSelected = _selectedSpecialty == specialty;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedSpecialty = specialty),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2979FF).withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFF2979FF) : palette.border.withValues(alpha: 0.6)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2979FF) : palette.textMuted,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic palette) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: palette.textMuted),
            const SizedBox(height: 12),
            Text('No pharmacological profiles matched your criteria', style: TextStyle(color: palette.textSecondary, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Try clearing filters or searching for alternative chemical terms.', style: TextStyle(color: palette.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDossiersGrid(List<MedicinePharmacologyProfile> profiles, dynamic palette) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 460,
          mainAxisExtent: 310,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildDossierCard(profiles[index], palette),
          childCount: profiles.length,
        ),
      ),
    );
  }

  Widget _buildDossierCard(MedicinePharmacologyProfile profile, dynamic palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badges
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF00BFA5).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${profile.specialty.icon} ${profile.specialty.label}',
                    style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'PDB: ${profile.pdbAccession}',
                  style: TextStyle(color: palette.textMuted, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Drug Generic Name
            Text(
              profile.genericName,
              style: TextStyle(color: palette.textPrimary, fontSize: 15.5, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              profile.chemicalClass,
              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Molecular Target
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target: ', style: TextStyle(color: palette.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
                Expanded(
                  child: Text(
                    profile.molecularTarget,
                    style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Therapeutic Indications snippet
            Expanded(
              child: Text(
                profile.therapeuticIndications,
                style: TextStyle(color: palette.textMuted, fontSize: 11.5, height: 1.3),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),

            // Key metrics strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: palette.scaffold.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.border.withValues(alpha: 0.5)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text('Ea: ${profile.activationBarrierKcalMol} kcal/mol', style: const TextStyle(color: Color(0xFFFF9100), fontSize: 10.5, fontWeight: FontWeight.w600)),
                  Text('t½: ${profile.eliminationHalfLifeHours}h', style: TextStyle(color: palette.textSecondary, fontSize: 10.5)),
                  Text('${profile.targetDisciplines.length} Curricula', style: const TextStyle(color: Color(0xFF00E676), fontSize: 10.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book_rounded, size: 14),
                    label: const Text('Complete Dossier', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _openDossierModal(profile, palette),
                  ),
                ),
                if (widget.onLoadReaction != null && profile.associatedReactionId.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.rocket_launch_outlined, size: 13),
                    label: const Text('3D Rxn', style: TextStyle(fontSize: 11.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => widget.onLoadReaction!(profile.associatedReactionId),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDossierModal(MedicinePharmacologyProfile profile, dynamic palette) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DossierDetailDialog(
        profile: profile,
        palette: palette,
        onLoadReaction: widget.onLoadReaction,
      ),
    );
  }
}

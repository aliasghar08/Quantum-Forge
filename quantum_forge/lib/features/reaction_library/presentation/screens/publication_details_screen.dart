import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:quantum_forge/core/config/api_endpoints.dart';
import 'package:quantum_forge/core/services/backend_compute_service.dart';
import 'package:quantum_forge/core/services/crossref_service.dart';
import 'package:quantum_forge/core/services/shared_reaction_service.dart';
import 'package:quantum_forge/core/settings/app_settings_provider.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/core/utils/avogadro_element_data.dart';
import 'package:quantum_forge/core/utils/xyz_parser.dart';
import 'package:quantum_forge/core/widgets/animations/staggered_animation_list.dart';
import 'package:quantum_forge/core/widgets/locked_animation_placeholder.dart';
import 'package:quantum_forge/core/widgets/reaction_animation_widget.dart';
import 'package:quantum_forge/features/auth/presentation/screens/auth_screen.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_preview_trajectory_generator.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/publication/publication_abstract_card.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/publication/publication_energies_card.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/publication/publication_external_links_card.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/publication/publication_header_card.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/publication/publication_related_videos_card.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/publication/publication_warning_banner.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/glass_card.dart';
import 'package:quantum_forge/state/settings_provider.dart';
import 'package:quantum_forge/views/publications/publication_videos_section.dart';

class PublicationDetailsScreen extends StatefulWidget {
  final ReactionTemplate template;

  const PublicationDetailsScreen({super.key, required this.template});

  @override
  State<PublicationDetailsScreen> createState() => _PublicationDetailsScreenState();
}

class _PublicationDetailsScreenState extends State<PublicationDetailsScreen> {
  bool _isLoadingCrossref = true;
  String? _crossrefError;
  Map<String, dynamic>? _crossrefData;
  String _effectiveDoi = '';
  bool _isAutoResolved = false;

  double? _reactantEnergy;
  double? _productEnergy;
  bool _isLoadingEnergies = true;

  final ScrollController _scrollCtrl = ScrollController();
  bool _showFab = false;

  StreamSubscription<User?>? _authSub;
  bool _signedInOverride = false;

  bool get _isUserSignedIn {
    if (_signedInOverride) return true;
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  set _isUserSignedIn(bool value) {
    _signedInOverride = value;
  }

  @override
  void initState() {
    super.initState();
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (mounted) {
          setState(() {
            _signedInOverride = user != null;
          });
        }
      });
    } catch (_) {}

    _effectiveDoi = widget.template.effectiveLiteratureDoi.isNotEmpty
        ? widget.template.effectiveLiteratureDoi
        : widget.template.doi;
    Future.microtask(() {
      _fetchCrossrefData();
      _fetchEnergies();
    });
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 200;
      if (show != _showFab) setState(() => _showFab = show);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _openAuthModal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => AuthScreen(
          redirectMessage:
              'Sign in required: Please log in with your researcher credentials to unlock interactive 3D trajectory playback and mechanism lecture demonstrations for this publication.',
          onLoginSuccess: () {
            Navigator.of(ctx).pop();
            if (mounted) {
              setState(() {
                _isUserSignedIn = true;
              });
            }
          },
        ),
      ),
    );
  }

  void _sharePublication() {
    final url = SharedReactionService.getPublicationShareUrl(widget.template.id);
    Clipboard.setData(ClipboardData(text: url));
    _showShareDialog(url);
  }

  void _showShareDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15151C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00B0FF), width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.share_rounded, color: Color(0xFF00B0FF), size: 22),
            SizedBox(width: 10),
            Text(
              'Share Publication',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anyone with this link can view the complete paper metadata, abstract, and DFT energies. Reaction trajectory animations require signing in.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Publication link copied to clipboard!'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Link'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00B0FF)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCrossrefData() async {
    try {
      final settings = Provider.of<AppSettingsNotifier>(context, listen: false).settings;
      final gnnUrl = settings.hasGnnBackend ? settings.gnnBackendUrl : null;

      final result = await CrossrefService.resolvePublicationMetadata(
        initialDoi: widget.template.doi,
        reactionName: widget.template.name,
        iupacName: widget.template.iupacName,
        gnnBackendUrl: gnnUrl,
      );

      if (result != null) {
        if (mounted) {
          setState(() {
            _crossrefData = result.metadata;
            _effectiveDoi = result.doi;
            _isAutoResolved = result.isAutoDiscovered;
            _isLoadingCrossref = false;
            _crossrefError = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _crossrefError = 'No verified peer-reviewed publication metadata matched in Crossref.';
            _isLoadingCrossref = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _crossrefError = 'Failed to load metadata: $e';
          _isLoadingCrossref = false;
        });
      }
    }
  }

  Future<void> _fetchEnergies() async {
    try {
      final settings = Provider.of<AppSettingsNotifier>(context, listen: false).settings;
      final quantumSettings = Provider.of<QuantumSettingsNotifier>(context, listen: false).value;
      if (!settings.hasGnnBackend) {
        if (mounted) setState(() => _isLoadingEnergies = false);
        return;
      }

      final reactantAtoms = XyzParser.parse(widget.template.reactantXyz);
      final productAtoms = XyzParser.parse(widget.template.productXyz);

      final reactantZ = reactantAtoms.map((a) => AvogadroElementData.atomicNumberForSymbol(a.symbol)).toList();
      final reactantPos = reactantAtoms.map((a) => [a.x, a.y, a.z]).toList();

      final productZ = productAtoms.map((a) => AvogadroElementData.atomicNumberForSymbol(a.symbol)).toList();
      final productPos = productAtoms.map((a) => [a.x, a.y, a.z]).toList();

      const computeService = BackendComputeService();
      String url = ApiEndpoints.sanitize(settings.gnnBackendUrl);
      if (quantumSettings.mlipModel == 'MACE-MP-0') {
        url = ApiEndpoints.forModel('MACE-MP-0');
      }
      if (url.isEmpty) {
        if (mounted) setState(() => _isLoadingEnergies = false);
        return;
      }
      final rEnergy = await computeService.predictEnergy(url, reactantZ, reactantPos);
      final pEnergy = await computeService.predictEnergy(url, productZ, productPos);

      if (mounted) {
        setState(() {
          _reactantEnergy = rEnergy;
          _productEnergy = pEnergy;
          _isLoadingEnergies = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEnergies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    return Scaffold(
      backgroundColor: palette.scaffold,
      floatingActionButton: AnimatedScale(
        scale: _showFab ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: FloatingActionButton.small(
          heroTag: 'pub_scroll_top',
          backgroundColor: palette.accent,
          foregroundColor: Colors.black87,
          onPressed: () => _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
          child: const Icon(Icons.keyboard_arrow_up),
        ),
      ),
      appBar: AppBar(
        backgroundColor: palette.scaffold,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Publication Details',
          style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: palette.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF4FC3F7)),
            tooltip: 'Share Public URL for this publication',
            onPressed: _sharePublication,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: palette.border),
        ),
      ),
      body: _buildBody(palette),
    );
  }

  Widget _buildMechanismAnimationCard(QuantumTheme palette) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00B0FF).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.view_in_ar, color: Color(0xFF00B0FF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3D Reaction Mechanism Trajectory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Published transition state & reaction coordinates for ${widget.template.name}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isUserSignedIn
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isUserSignedIn ? const Color(0xFF10B981) : Colors.amber,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isUserSignedIn ? Icons.check_circle_outline : Icons.lock_outline,
                        size: 12,
                        color: _isUserSignedIn ? const Color(0xFF10B981) : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isUserSignedIn ? 'Simulation Active' : 'Sign-In Required',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isUserSignedIn ? const Color(0xFF10B981) : Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 380,
                width: double.infinity,
                child: _isUserSignedIn
                    ? ReactionAnimationWidget(
                        trajectoryFrames:
                            ReactionPreviewTrajectoryGenerator.generateTrajectory(widget.template),
                        energyProfile:
                            ReactionPreviewTrajectoryGenerator.generateEnergyProfile(
                                widget.template.referenceEa),
                        maxEnergyIndex: ReactionPreviewTrajectoryGenerator.tsFrame,
                        frameRateOverride: ReactionPreviewTrajectoryGenerator.previewFps,
                      )
                    : LockedAnimationPlaceholder(
                        title: '3D Mechanism Animation Locked',
                        subtitle:
                            'This publication was opened via a link. Sign in with your researcher credentials to view interactive 3D reaction trajectory playback and step through the transition state.',
                        onSignInRequested: _openAuthModal,
                        onSignInSuccess: () {
                          if (mounted) setState(() => _isUserSignedIn = true);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(QuantumTheme palette) {
    // Non-blocking UI: The page renders immediately using bundled template data,
    // while the CrossRef data loads in the background.

    // Parse Data — every field falls back to the bundled template metadata.
    final titleList = _crossrefData?['title'] as List<dynamic>?;
    final rawTitle = (titleList != null && titleList.isNotEmpty) ? titleList[0].toString() : widget.template.name;
    final title = rawTitle.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    final abstractHtml = _crossrefData?['abstract']?.toString() ??
        'Publication metadata could not be fetched from CrossRef'
        '${_crossrefError != null ? ' ($_crossrefError)' : ''}.\n'
        'The details shown are from the bundled reaction library.';
    final abstractText = abstractHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    final authorsList = _crossrefData?['author'] as List<dynamic>?;
    String authors = 'Unknown Authors';
    if (authorsList != null && authorsList.isNotEmpty) {
      authors = authorsList.map((a) {
        final given = a['given']?.toString() ?? '';
        final family = a['family']?.toString() ?? '';
        return '$given $family'.trim();
      }).where((s) => s.isNotEmpty).join(', ');
      if (authors.isEmpty) authors = 'Unknown Authors';
    }

    final publisher = _crossrefData?['publisher']?.toString() ?? 'Unknown Publisher';

    final containerTitleList = _crossrefData?['container-title'] as List<dynamic>?;
    final containerTitle = (containerTitleList != null && containerTitleList.isNotEmpty)
        ? containerTitleList[0].toString()
        : widget.template.journalRef;

    final datePartsList = _crossrefData?['created']?['date-parts'] as List<dynamic>?;
    final createdDate = (datePartsList != null && datePartsList.isNotEmpty) ? datePartsList[0] as List<dynamic>? : null;
    final year = (createdDate != null && createdDate.isNotEmpty) ? createdDate[0].toString() : 'Unknown Year';

    final hPad = MediaQuery.of(context).size.width < 480 ? 16.0 : 24.0;

    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 80),
      child: StaggeredAnimationList(
        children: [
          if (_crossrefError != null && !_isLoadingCrossref)
            PublicationWarningBanner(error: _crossrefError!),
          if (_crossrefError != null && !_isLoadingCrossref) const SizedBox(height: 16),
          if (_isAutoResolved) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crossref Verified: Auto-resolved peer-reviewed literature citation for ${widget.template.name}',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          PublicationHeaderCard(
            title: title,
            authors: authors,
            journal: containerTitle,
            publisher: publisher,
            year: year,
            doi: _effectiveDoi,
            isLoading: _isLoadingCrossref,
            onShare: _sharePublication,
          ),
          if (widget.template.defaultCatalystName != null &&
              widget.template.defaultCatalystName!.isNotEmpty) ...[
            const SizedBox(height: 20),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.biotech_rounded, color: Color(0xFF34D399), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Literature Catalyst & Reference Barrier',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Primary benchmark DOI: $_effectiveDoi',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Reported Catalyst', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text(
                                  widget.template.defaultCatalystName!,
                                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 15, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Reference Ea', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text(
                                  '${widget.template.effectiveLiteratureBarrier.toStringAsFixed(1)} kcal·mol⁻¹',
                                  style: const TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          PublicationAbstractCard(
            abstractText: abstractText,
            isLoading: _isLoadingCrossref,
          ),
          const SizedBox(height: 20),
          PublicationEnergiesCard(
            isLoading: _isLoadingEnergies,
            reactantEnergy: _reactantEnergy,
            productEnergy: _productEnergy,
          ),
          const SizedBox(height: 20),
          // ── 3D Reaction Mechanism Trajectory ─────────────────────────────
          _buildMechanismAnimationCard(palette),
          const SizedBox(height: 20),
          PublicationExternalLinksCard(
            title: title,
            doi: _effectiveDoi,
          ),
          const SizedBox(height: 20),
          PublicationRelatedVideosCard(
            query: title,
            template: widget.template,
            isUserSignedIn: _isUserSignedIn,
            onSignInRequested: _openAuthModal,
            onSignInSuccess: () {
              if (mounted) setState(() => _isUserSignedIn = true);
            },
          ),
          const SizedBox(height: 24),
          PublicationVideosSection(
            query: title,
            isUserSignedIn: _isUserSignedIn,
            onSignInRequested: _openAuthModal,
            onSignInSuccess: () {
              if (mounted) setState(() => _isUserSignedIn = true);
            },
          ),
        ],
      ),
    );
  }
}

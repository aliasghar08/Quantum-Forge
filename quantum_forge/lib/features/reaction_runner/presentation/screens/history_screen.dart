// ============================================================================
// HistoryScreen — Reaction run history (Strictly Authenticated / Cloud Only)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/core/services/reaction_repository.dart';
import 'package:quantum_forge/core/services/auth_service.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/auth/presentation/screens/auth_screen.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/reaction_card_widget.dart';
import 'package:quantum_forge/core/widgets/animations/staggered_animation_list_item.dart';
import 'package:quantum_forge/core/widgets/adsense_banner_web.dart';

class HistoryScreen extends StatefulWidget {
  final ValueChanged<ReactionStatusResponse>? onReactionSelected;
  final VoidCallback? onNavigateToRun;
  final VoidCallback? onNavigateToLibrary;

  const HistoryScreen({
    super.key,
    this.onReactionSelected,
    this.onNavigateToRun,
    this.onNavigateToLibrary,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ReactionStatusResponse> _reactions = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      final isAuth = await auth.isAuthenticated();

      if (!isAuth) {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _reactions = [];
            _isLoading = false;
          });
        }
        return;
      }

      final userId = await auth.getUserId();
      if (!mounted) return;

      final repo = context.read<ReactionRepository>();
      final cloudReactions = await repo.listReactions(userId);

      cloudReactions.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _reactions = cloudReactions;
        });
      }
    } catch (e) {
      debugPrint('[HistoryScreen] Error loading reactions from cloud: $e');
      if (mounted) {
        setState(() {
          _reactions = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openAuth() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => AuthScreen(
          redirectMessage: 'Sign in to access your saved reaction calculations and 3D trajectories.',
          onLoginSuccess: () {
            Navigator.of(ctx).pop();
            _loadReactions();
          },
        ),
      ),
    );
  }


  Future<void> _deleteReaction(String reactionId) async {
    try {
      final repo = context.read<ReactionRepository>();
      await repo.deleteReaction(reactionId);
    } catch (e) {
      debugPrint('[HistoryScreen] Error deleting from cloud: $e');
    }

    if (mounted) {
      setState(() {
        _reactions.removeWhere((r) => r.reactionId == reactionId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reaction removed from cloud history.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _selectReaction(ReactionStatusResponse reaction) {
    if (widget.onReactionSelected != null) {
      widget.onReactionSelected!(reaction);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected reaction: ${reaction.reactionId}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  double? _computeBarrier(ReactionStatusResponse reaction) {
    if (reaction.dftAttachments.isNotEmpty && reaction.dftAttachments.first.hasBarrier) {
      return reaction.dftAttachments.first.barrierKcalMol;
    }
    final profile = reaction.energyProfile;
    if (profile == null || profile.length < 2) return null;
    final r0 = profile.first;
    double maxE = profile.first;
    for (final e in profile) {
      if (e > maxE) maxE = e;
    }
    final barrier = maxE - r0;
    return barrier > 0 ? barrier : null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: palette.accent),
            const SizedBox(height: 16),
            Text(
              'Retrieving cloud reaction history…',
              style: TextStyle(color: palette.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        // If not authenticated, require signing in
        if (!_isAuthenticated) {
          return _buildAuthPrompt(palette, isMobile);
        }

        return RefreshIndicator(
          color: palette.accent,
          onRefresh: _loadReactions,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 28,
              vertical: isMobile ? 16 : 24,
            ),
            children: [
              // Header Row
              _buildHeader(palette, isMobile),
              const SizedBox(height: 20),

              // Empty State or Grid
              if (_reactions.isEmpty)
                _buildEmptyState(palette, isMobile)
              else
                _buildReactionList(palette, isMobile, constraints.maxWidth),

              const SizedBox(height: 16),
              AdSenseBannerWeb(
                isSignedIn: _isAuthenticated,
                isProUser: false,
                placement: 'history_list',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthPrompt(QuantumTheme palette, bool isMobile) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 16 : 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: palette.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
                        ),
                        child: Icon(Icons.history_rounded, size: 34, color: palette.accent),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'History Requires an Account',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Reaction histories, activation barriers, and 3D transition-state trajectories '
                        'are stored securely in Cloud Firestore. Sign in to view and compare your runs.',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _openAuth,
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Sign In or Register'),
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.accent,
                            foregroundColor: palette.onAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AdSenseBannerWeb(
                isSignedIn: _isAuthenticated,
                isProUser: false,
                placement: 'history_auth',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(QuantumTheme palette, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.history_rounded, color: palette.accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Reaction History',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.border),
                    ),
                    child: Text(
                      '${_reactions.length} ${_reactions.length == 1 ? 'run' : 'runs'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Cloud-synced activation barriers, 3D trajectories, and vibration states',
                style: TextStyle(fontSize: 13, color: palette.textSecondary),
              ),
            ],
          ),
        ),
        if (_reactions.isNotEmpty)
          IconButton(
            tooltip: 'Refresh history',
            icon: Icon(Icons.refresh_rounded, color: palette.textSecondary),
            onPressed: _loadReactions,
          ),
      ],
    );
  }

  Widget _buildEmptyState(QuantumTheme palette, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 48 : 64,
      ),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.accent.withValues(alpha: 0.1),
              border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.science_outlined, size: 36, color: palette.accent),
          ),
          const SizedBox(height: 20),
          Text(
            'No Saved Reactions Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'Execute an optimization on the Reaction Workspace or choose a reaction from the Library. '
              'Your computed activation barriers, 3D trajectories, and vibrational frequencies will be automatically recorded here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: palette.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              if (widget.onNavigateToRun != null)
                FilledButton.icon(
                  onPressed: widget.onNavigateToRun,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Run New Reaction'),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              if (widget.onNavigateToLibrary != null)
                OutlinedButton.icon(
                  onPressed: widget.onNavigateToLibrary,
                  icon: const Icon(Icons.auto_stories_rounded, size: 18),
                  label: const Text('Explore Library'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.textPrimary,
                    side: BorderSide(color: palette.border),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  ReactionTemplate _templateFromReaction(ReactionStatusResponse reaction) {
    final barrier = _computeBarrier(reaction) ?? 0.0;
    final frames = reaction.trajectoryFrames?.length ?? 0;
    final dateStr = (reaction.createdAt ?? DateTime.now())
        .toLocal()
        .toString()
        .split('.')[0];

    // Check if there is an exact or partial match in curated kReactionTemplates
    ReactionTemplate? matched;
    final msgLower = (reaction.message ?? '').toLowerCase();
    for (final t in kReactionTemplates) {
      if (reaction.reactionId.contains(t.id) ||
          (msgLower.isNotEmpty && msgLower.contains(t.name.toLowerCase()))) {
        matched = t;
        break;
      }
    }

    // Name / Title
    String name;
    if (reaction.message != null && reaction.message!.trim().isNotEmpty) {
      name = reaction.message!;
    } else if (matched != null) {
      name = matched.name;
    } else {
      name =
          'Reaction ${reaction.reactionId.length > 8 ? reaction.reactionId.substring(0, 8) : reaction.reactionId}';
    }

    // Subtitle / IUPAC
    String iupac;
    if (matched != null && matched.iupacName.isNotEmpty) {
      iupac = matched.iupacName;
    } else if (reaction.modelUsed != null && reaction.modelUsed!.isNotEmpty) {
      iupac = '${reaction.modelUsed} • $frames frames';
    } else if (frames > 0) {
      iupac = '$frames trajectory frames';
    } else {
      iupac = 'Calculated Mechanism';
    }

    // Description
    String desc;
    if (matched != null && matched.description.isNotEmpty) {
      desc = matched.description;
    } else {
      final status = reaction.state == ReactionState.completed
          ? 'Converged calculation'
          : (reaction.state == ReactionState.error
              ? 'Optimization error'
              : 'In-progress run');
      desc =
          '$status with $frames trajectory frames and activation barrier of ${barrier.toStringAsFixed(2)} kcal/mol. Synced on $dateStr.';
    }

    // Category
    ReactionCategory category;
    if (matched != null) {
      category = matched.category;
    } else {
      final m = (reaction.modelUsed ?? '').toLowerCase();
      if (m.contains('transformer') || msgLower.contains('transformer')) {
        category = ReactionCategory.organometallic;
      } else if (msgLower.contains('diels') || msgLower.contains('pericyclic')) {
        category = ReactionCategory.pericyclic;
      } else if (msgLower.contains('radical')) {
        category = ReactionCategory.radical;
      } else if (msgLower.contains('polymer')) {
        category = ReactionCategory.polymer;
      } else if (msgLower.contains('pharma') ||
          msgLower.contains('paracetamol') ||
          msgLower.contains('aspirin')) {
        category = ReactionCategory.pharmaceutical;
      } else {
        category = ReactionCategory.thermal;
      }
    }

    final tags = <String>[
      if (reaction.modelUsed != null && reaction.modelUsed!.isNotEmpty)
        reaction.modelUsed!,
      if (frames > 0) '$frames frames',
      'cloud',
      if (reaction.state == ReactionState.completed)
        'converged'
      else
        reaction.state.name,
    ];

    return ReactionTemplate(
      id: reaction.reactionId,
      name: name,
      iupacName: iupac,
      description: desc,
      category: category,
      reactantXyz: matched?.reactantXyz ??
          (frames > 0 ? reaction.trajectoryFrames!.first : ''),
      productXyz: matched?.productXyz ??
          (frames > 1 ? reaction.trajectoryFrames!.last : ''),
      referenceEa: barrier,
      literatureBarrierKcalMol: barrier > 0 ? barrier : null,
      doi: matched?.doi ?? '',
      journalRef:
          matched?.journalRef.isNotEmpty == true ? matched!.journalRef : dateStr,
      tags: tags,
      defaultCatalystName: matched?.defaultCatalystName,
    );
  }

  Widget _buildReactionList(
      QuantumTheme palette, bool isMobile, double screenWidth) {
    final columns = screenWidth >= 1200
        ? 3
        : screenWidth >= 820
            ? 2
            : 1;

    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: isMobile ? 14 : 20,
          crossAxisSpacing: isMobile ? 14 : 20,
          mainAxisExtent: isMobile ? 250 : 255,
        ),
        itemCount: _reactions.length,
        itemBuilder: (context, index) {
          final reaction = _reactions[index];
          final template = _templateFromReaction(reaction);

          return StaggeredAnimationListItem(
            index: index,
            child: ReactionCardWidget(
              key: ValueKey(reaction.reactionId),
              template: template,
              onLoad: () => _selectReaction(reaction),
              onTap: () => _selectReaction(reaction),
              onDelete: () => _deleteReaction(reaction.reactionId),
            ),
          );
        },
      ),
    );
  }
}

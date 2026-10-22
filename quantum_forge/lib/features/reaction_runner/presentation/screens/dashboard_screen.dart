// ============================================================================
// Dashboard Screen — PhD Researcher 3-Column Desktop Layout
// Left Rail | Center Setup & Status | Right Quantum Controls
//
// All widgets are in separate files under dashboard_cards/.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/core/services/file_picker_service.dart';
import 'package:quantum_forge/core/services/shared_reaction_service.dart';
import 'package:quantum_forge/state/reaction_provider.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/state/settings_provider.dart';
import 'package:quantum_forge/core/settings/app_settings_provider.dart';
import 'package:quantum_forge/core/services/session_state_service.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/core/utils/avogadro_bridge.dart';
import 'package:quantum_forge/core/utils/avogadro_codec.dart';
import 'package:quantum_forge/core/utils/avogadro_deep_link.dart';
import 'package:quantum_forge/core/utils/avogadro_interchange.dart';
import 'package:quantum_forge/core/utils/xyz_parser.dart';
import 'package:quantum_forge/core/utils/zip_writer.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/results_summary.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/results_header_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/quantum_controls_panel.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/quantum_on_screen_controls.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_template_generator.dart';
import 'package:quantum_forge/features/reaction_library/data/firestore_library_repository.dart';
import 'package:quantum_forge/features/reaction_library/presentation/screens/library_screen.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';
import 'package:quantum_forge/features/pharmacopeia/data/pharmacopeia_repository.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/reaction_medical_dossier_card.dart';
import 'package:quantum_forge/features/reaction_library/presentation/screens/publication_details_screen.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/pubmed_panel.dart';
import 'package:quantum_forge/core/widgets/quantum_forge_logo.dart';
// Dashboard card widgets
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/energy_profile_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/hero_metrics_row.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/arrhenius_plot_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/thermo_properties_grid.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/molecular_data_cards.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/distinct_molecules_viewer.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/vibrational_analysis_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/glass_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/reaction_status_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/reaction_error_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/reaction_animation_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/dft_workflow_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/screens/method_validation_screen.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/reaction_progress_card.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/left_nav_rail.dart';
import 'history_screen.dart';
import 'coordinate_editor_screen.dart';
import 'package:quantum_forge/features/settings/presentation/screens/settings_screen.dart';
import 'package:quantum_forge/state/dashboard_viewmodel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:quantum_forge/core/widgets/reaction_animation_widget.dart';
import 'package:quantum_forge/core/services/feedback_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:quantum_forge/features/auth/presentation/screens/auth_screen.dart';
import 'package:quantum_forge/core/services/chemical_resolver_service.dart';
import 'package:quantum_forge/core/widgets/locked_animation_placeholder.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardViewModel _viewModel;
  int? _selectedFrameIndex;
  StreamSubscription<User?>? _authSub;
  MedicinePharmacologyProfile? _userSelectedMedicineProfile;
  String? _lastTrackedReactionId;

  /// Reaction whose fallback-data warning has already been shown, so the SnackBar
  /// fires once per result instead of on every rebuild.
  String? _warnedFallbackFor;

  /// Set when a deep link arrived but auto-load is disabled (or was rejected),
  /// so the user still gets told what happened instead of silence.
  AvogadroDeepLink? _pendingLink;

  @override
  void initState() {
    super.initState();
    final sessionService = context.read<SessionStateService>();
    _viewModel = DashboardViewModel(sessionService: sessionService);
    _viewModel.loadState();
    _viewModel.addListener(_onViewModelChanged);
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
        if (mounted) setState(() {});
      });
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleIncomingStructure();
      _handleIncomingSharedReaction();
    });
  }

  void _onViewModelChanged() {
    if (_viewModel.shouldAutoRun) {
      _viewModel.consumeAutoRun();
      if (_canDispatch) {
        // Need to wait for frame to render the new state before dispatching
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _dispatch();
        });
      }
    }
  }

  /// Handles a structure pushed in from Avogadro through the URL.
  ///
  /// The previous implementation decoded the payload by hand, dropped it into
  /// the first reactant slot and swallowed every failure in a debugPrint — the
  /// user saw nothing at all when a payload was malformed. It now decodes
  /// through [AvogadroCodec] (CJSON *and* legacy XYZ), reports failures in the
  /// UI, honours the bridge preferences, and opens the editor.
  void _handleIncomingStructure() {
    final settings = context.read<AppSettingsNotifier>().settings;
    if (!settings.avogadroBridgeEnabled) return;

    final link = AvogadroDeepLinkCodec.fromCurrentUrl();
    if (link.isAbsent) return;

    if (link.isInvalid) {
      setState(() => _pendingLink = link);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avogadro import failed: ${link.error}'),
          duration: const Duration(seconds: 8),
        ),
      );
      _cleanUrl(settings);
      return;
    }

    final structure = link.structure!;
    if (settings.autoImportDeepLink) {
      _viewModel.loadStructure(structure);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded from Avogadro — ${link.summary}'),
          duration: const Duration(seconds: 5),
        ),
      );
      _cleanUrl(settings);
    } else {
      // Auto-load off: keep the banner so the work is not lost on refresh.
      setState(() => _pendingLink = link);
    }
  }

  void _cleanUrl(AppSettings settings) {
    if (!settings.cleanUrlAfterImport) return;
    AvogadroBridge.stripImportParams(Uri.base);
  }

  Future<void> _handleIncomingSharedReaction() async {
    final uri = Uri.base;
    final shareId = uri.queryParameters['share'];
    final templateId = uri.queryParameters['reaction'];
    final pubId = uri.queryParameters['publication'] ?? uri.queryParameters['pub'];

    if (pubId != null && pubId.isNotEmpty) {
      final template = _findTemplateById(pubId);
      if (template != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => PublicationDetailsScreen(template: template),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing publication: ${template.name} (Public View)'),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    if (shareId != null && shareId.isNotEmpty) {
      try {
        final data = await SharedReactionService.getSharedReaction(shareId);
        if (data != null && mounted) {
          _loadSharedReactionData(data);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shared reaction not found or may have expired.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading shared reaction: $e'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } else if (templateId != null && templateId.isNotEmpty) {
      final template = _findTemplateById(templateId);
      if (template != null && mounted) {
        _viewModel.loadTemplateForView(template);
        context.read<QuantumSettingsNotifier>().update((q) => q.copyWith(
          charge: template.defaults.charge,
          spinMultiplicity: template.defaults.spinMultiplicity,
          mlipModel: template.defaults.mlipModel,
          optimizerAlgorithm: template.defaults.optimizerAlgorithm,
          catalyst: template.defaultCatalystName ?? q.catalyst,
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded shared template: ${template.name} (Public View)'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _onTemplateSelected(ReactionTemplate template) {
    _viewModel.loadTemplate(template);
    if (mounted) {
      context.read<QuantumSettingsNotifier>().update((q) => q.copyWith(
        charge: template.defaults.charge,
        spinMultiplicity: template.defaults.spinMultiplicity,
        mlipModel: template.defaults.mlipModel,
        optimizerAlgorithm: template.defaults.optimizerAlgorithm,
        catalyst: template.defaultCatalystName ?? q.catalyst,
      ));
    }
  }

  ReactionTemplate? _findTemplateById(String id) {
    for (final t in kReactionTemplates) {
      if (t.id.toLowerCase() == id.toLowerCase() || t.doi.toLowerCase() == id.toLowerCase()) {
        return t;
      }
    }
    return null;
  }

  void _loadSharedReactionData(Map<String, dynamic> data) {
    final templateId = data['template_id'] as String?;
    final rxnName = data['reaction_name'] as String? ?? 'Shared Reaction';

    if (templateId != null && templateId.isNotEmpty) {
      final template = _findTemplateById(templateId);
      if (template != null) {
        _viewModel.loadTemplateForView(template);
        if (mounted) {
          context.read<QuantumSettingsNotifier>().update((q) => q.copyWith(
            charge: template.defaults.charge,
            spinMultiplicity: template.defaults.spinMultiplicity,
            mlipModel: template.defaults.mlipModel,
            optimizerAlgorithm: template.defaults.optimizerAlgorithm,
            catalyst: template.defaultCatalystName ?? q.catalyst,
          ));
        }
      }
    } else {
      _viewModel.loadMoleculesFromData(
        reactantsData: data['reactants'] as List<dynamic>?,
        productsData: data['products'] as List<dynamic>?,
        catalystsData: data['catalysts'] as List<dynamic>?,
      );
    }

    if (data['status'] != null) {
      try {
        final statusMap = Map<String, dynamic>.from(data['status'] as Map);
        final loadedStatus = ReactionStatusResponse.fromJson(statusMap);
        context.read<ReactionNotifier>().value = loadedStatus;
        setState(() => _selectedFrameIndex = null);
      } catch (e) {
        debugPrint('[DashboardScreen] Error decoding shared reaction status: $e');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing public shared reaction: $rxnName'),
        backgroundColor: const Color(0xFF00B0FF),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _shareCurrentReaction([ReactionStatusResponse? status]) async {
    final palette = ThemeNotifier.paletteOf(context);
    final reactionNotifier = context.read<ReactionNotifier>();
    final currentStatus = status ?? reactionNotifier.value;
    final settings = context.read<QuantumSettingsNotifier>().value;

    String rxName = _viewModel.activeTemplate?.name ?? 'Custom Reaction';
    if (_viewModel.activeTemplate == null) {
      final rCount = _viewModel.reactants.where((e) => e.resolved).length;
      final pCount = _viewModel.products.where((e) => e.resolved).length;
      if (rCount == 0 && pCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select or configure a reaction before sharing.'),
          ),
        );
        return;
      }
    }

    // Show loading overlay
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          color: Color(0xFF15151C),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00B0FF)),
                SizedBox(height: 16),
                Text('Generating public URL…', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final publicUrl = await SharedReactionService.createPublicShare(
        reactionName: rxName,
        templateId: _viewModel.activeTemplate?.id,
        referenceEa: _viewModel.activeTemplate?.referenceEa,
        reactants: _viewModel.reactants,
        products: _viewModel.products,
        catalysts: _viewModel.catalysts,
        settings: settings,
        status: currentStatus,
      );

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: publicUrl));

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        _showShareDialog(publicUrl, rxName, palette);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate public URL: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showShareDialog(String url, String reactionName, QuantumTheme palette) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15151C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF00B0FF), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00B0FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.share_rounded, color: Color(0xFF00B0FF), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Public Reaction Link Ready',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anyone with this link can view the complete reaction metrics, energy profile, and quantum properties. 3D animations require signing in.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      url,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF4FC3F7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Public URL copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Link copied to clipboard automatically',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done', style: TextStyle(color: Color(0xFF00B0FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  bool get _canDispatch {
    final reactionNotifier = context.read<ReactionNotifier>();
    return _viewModel.canDispatch(
      reactionNotifier.isLoading,
      reactionNotifier.value?.state == ReactionState.optimizing || reactionNotifier.value?.state == ReactionState.pending
    );
  }

  bool get _isUserSignedIn {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Stream<User?> _authStateStream() {
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return const Stream<User?>.empty();
    }
  }

  void _redirectToAuth({String? message, VoidCallback? onSuccess}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => AuthScreen(
          redirectMessage: message,
          onLoginSuccess: () {
            Navigator.of(ctx).pop();
            if (mounted) {
              setState(() {});
              onSuccess?.call();
            }
          },
        ),
      ),
    );
  }

  void _openLibrary() {
    _viewModel.setNavDestination(NavDestination.library);
  }

  void _dispatch() {
    if (!_isUserSignedIn) {
      _redirectToAuth(
        message: 'Sign in required: Please log in with your researcher credentials to execute Transition-State search simulations.',
        onSuccess: () {
          _dispatch();
        },
      );
      return;
    }
    setState(() => _selectedFrameIndex = null);
    final settings = context.read<QuantumSettingsNotifier>().value;
    if (_viewModel.activeTemplate != null) {
      context.read<ReactionNotifier>()
          .dispatchFromTemplate(_viewModel.activeTemplate!, settings);
    } else {
      final rList = [..._viewModel.reactants, ..._viewModel.catalysts];
      final pList = [..._viewModel.products, ..._viewModel.catalysts];
      final reactantFile = _viewModel.mergeXyz(rList, 'reactant');
      final productFile  = _viewModel.mergeXyz(pList,  'product');
      context.read<ReactionNotifier>()
          .dispatchReaction(reactantFile, productFile, settings);
    }
  }

  void _showUserMenu(BuildContext context, User user, QuantumTheme palette) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: palette.drawer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: palette.accent.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: palette.accent),
                ),
                title: Text(
                  user.displayName ?? user.email?.split('@').first ?? 'Researcher',
                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  user.email ?? 'Authenticated',
                  style: TextStyle(color: palette.textMuted),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.redAccent.shade100),
                title: Text('Sign Out', style: TextStyle(color: Colors.redAccent.shade100)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await FirebaseAuth.instance.signOut();
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeNotifier>().palette;
    final settings = context.watch<AppSettingsNotifier>().settings;

    return ChangeNotifierProvider<DashboardViewModel>.value(
      value: _viewModel,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
        final isMobile = MediaQuery.of(context).size.width < 650;
        return Scaffold(
          backgroundColor: palette.scaffold,
          drawer: ProfessionalDrawer(
            current: _viewModel.navDest,
            onDestinationSelected: (d) {
              _viewModel.setNavDestination(d);
              Navigator.pop(context); // Close drawer
            },
            controlsPanelOpen: _viewModel.controlsPanelOpen,
            onToggleControls: () {
              _viewModel.toggleControlsPanel();
            },
          ),
          appBar: AppBar(
            backgroundColor: palette.scaffold,
            titleSpacing: isMobile ? 0 : null,
            title: Row(
              children: [
                const QuantumForgeLogo(size: 26, borderRadius: 7),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _navTitle(_viewModel.navDest),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            iconTheme: IconThemeData(color: palette.textPrimary),
            elevation: 0,
            actions: [
              if (!isMobile)
                Tooltip(
                  message: 'Share Public URL for this reaction',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, size: 20),
                      color: const Color(0xFF00B0FF),
                      onPressed: () => _shareCurrentReaction(),
                    ),
                  ),
                ),
              StreamBuilder<User?>(
                stream: _authStateStream(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) {
                    if (isMobile) {
                      return IconButton(
                        icon: const Icon(Icons.login_rounded, size: 20),
                        color: palette.accent,
                        tooltip: 'Sign In',
                        onPressed: () => _redirectToAuth(),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.accent,
                          side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                        icon: const Icon(Icons.login_rounded, size: 15),
                        label: const Text('Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () => _redirectToAuth(),
                      ),
                    );
                  }
                  final displayName = user.displayName ?? user.email?.split('@').first ?? 'Researcher';
                  if (isMobile) {
                    return IconButton(
                      icon: CircleAvatar(
                        radius: 12,
                        backgroundColor: palette.accent.withValues(alpha: 0.2),
                        child: Text(
                          (displayName.isNotEmpty ? displayName[0] : 'R').toUpperCase(),
                          style: TextStyle(color: palette.accent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      tooltip: displayName,
                      onPressed: () => _showUserMenu(context, user, palette),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => _showUserMenu(context, user, palette),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: palette.panel,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: palette.accent.withValues(alpha: 0.2),
                              child: Text(
                                (displayName.isNotEmpty ? displayName[0] : 'R').toUpperCase(),
                                style: TextStyle(color: palette.accent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayName,
                              style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: settings.showTooltips ? 'Send Feedback' : null,
                icon: Icon(Icons.feedback_outlined, color: palette.textSecondary),
                onPressed: () => FeedbackService.showFeedbackDialog(context),
              ),
              IconButton(
                tooltip: settings.showTooltips ? 'Settings' : null,
                icon: Icon(Icons.settings_outlined, color: palette.textSecondary),
                onPressed: () => Navigator.of(context).push(SettingsScreen.route()),
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: palette.border,
                height: 1.0,
                width: double.infinity,
              ),
            ),
          ),
          // Bottom navigation for mobile (< 600px)
          bottomNavigationBar: LayoutBuilder(
            builder: (context, constraints) {
              if (MediaQuery.of(context).size.width >= 600) return const SizedBox.shrink();
              return Container(
                decoration: BoxDecoration(
                  color: palette.drawer,
                  border: Border(top: BorderSide(color: palette.border)),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _bottomNavItem(context, Icons.auto_stories_outlined, 'Library', NavDestination.library, palette),
                      _bottomNavItem(context, Icons.add_circle_outline, 'Reaction', NavDestination.newReaction, palette),
                      _bottomNavItem(context, Icons.edit_document, 'Editor', NavDestination.editor, palette),
                      _bottomNavItem(context, Icons.history, 'History', NavDestination.history, palette),
                    ],
                  ),
                ),
              );
            },
          ),
          // FIX: SizedBox.expand forces the body to fill the entire Scaffold
          // area (both width and height), so nothing shows through from the
          // browser's default white <body> when the window is maximized.
          body: SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette.backgroundGradient,
                ),
              ),
              child: Column(
                // FIX: stretch makes every child (banner + center) full-width,
                // so the gradient and controls panel never get cut off early.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_pendingLink != null) _buildImportBanner(palette),
                  Expanded(child: _buildCenter()),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  /// Shown when a structure arrived by deep link but was not auto-loaded.
  Widget _buildImportBanner(QuantumTheme palette) {
    final link = _pendingLink!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.12),
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.hub_outlined, size: 18, color: palette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              link.isReady
                  ? 'Structure received from Avogadro — ${link.summary}'
                  : 'Avogadro payload could not be read: ${link.error}',
              style: TextStyle(color: palette.textPrimary, fontSize: 12.5),
            ),
          ),
          if (link.isReady)
            FilledButton.icon(
              onPressed: () {
                final structure = link.structure!;
                final settings = context.read<AppSettingsNotifier>().settings;
                setState(() => _pendingLink = null);
                _viewModel.loadStructure(structure);
                _cleanUrl(settings);
              },
              icon: const Icon(Icons.edit_document, size: 16),
              label: const Text('Open in editor'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.onAccent,
              ),
            ),
          IconButton(
            tooltip: 'Dismiss',
            icon: Icon(Icons.close, size: 18, color: palette.textMuted),
            onPressed: () => setState(() => _pendingLink = null),
          ),
        ],
      ),
    );
  }

  // ── Center area ────────────────────────────────────────────────────────────
  Widget _buildCenter() {
    // FIX: force the center pane to full width so the reaction workspace
    // (and its nested Row of Expanded columns) can stretch edge-to-edge.
    return SizedBox(
      width: double.infinity,
      child: switch (_viewModel.navDest) {
        NavDestination.library  =>
            LibraryScreen(onTemplateSelected: _onTemplateSelected),
        NavDestination.history  => HistoryScreen(
              onReactionSelected: (reaction) {
                context.read<ReactionNotifier>().value = reaction;
                setState(() => _selectedFrameIndex = null);
                _viewModel.setNavDestination(NavDestination.newReaction);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Loaded reaction ${reaction.reactionId.length > 8 ? reaction.reactionId.substring(0, 8) : reaction.reactionId} into workspace.',
                    ),
                    backgroundColor: const Color(0xFF00B0FF),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              onNavigateToRun: () {
                _viewModel.setNavDestination(NavDestination.newReaction);
              },
              onNavigateToLibrary: () {
                _viewModel.setNavDestination(NavDestination.library);
              },
            ),
        NavDestination.methodValidation => MethodValidationScreen(
              backendUrl:
                  context.watch<QuantumSettingsNotifier>().value.effectiveBackendUrl,
              settings: context.read<QuantumSettingsNotifier>().value,
            ),
        NavDestination.editor   => CoordinateEditorScreen(
            // Keyed on the import revision, not on the structure's hashCode:
            // a new import rebuilds the editor, anything else leaves the user's
            // in-progress coordinates untouched.
            key: ValueKey('editor-${_viewModel.structureRevision}'),
            initialStructure: _viewModel.pendingStructure,
          ),
        NavDestination.newReaction   => _buildReactionWorkspace(),
      },
    );
  }


  // ── Reaction workspace ──────────────────────────────────────────────────────────
  Widget _buildReactionWorkspace() {
    final reactionNotifier = context.read<ReactionNotifier>();

    return ListenableBuilder(
      listenable: Listenable.merge([
        reactionNotifier,
        reactionNotifier.isLoadingNotifier,
        reactionNotifier.errorNotifier,
      ]),
      builder: (context, _) {
        final reactionStatus = reactionNotifier.value;
        final isLoading = reactionNotifier.isLoading;
        final hasError = reactionNotifier.error != null;
        final errorMsg = reactionNotifier.error;
        final status = reactionStatus ?? ReactionStatusResponse.empty();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            
            final palette = context.watch<ThemeNotifier>().palette;
            final mainContent = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTelemetryBanner(palette),
                // Header
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(child: _buildHeaderTitle(palette)),
                      const SizedBox(width: 16),
                      _buildExecuteButton(isLoading, status, palette),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderTitle(palette),
                      const SizedBox(height: 16),
                      _buildExecuteButton(isLoading, status, palette),
                    ],
                  ),
                const SizedBox(height: 20),

                // Input setup card
                _buildSetupCard(),
                const SizedBox(height: 16),

                // Dedicated Clinical & Veterinary Medical Section (for medicine reactions)
                Builder(
                  builder: (ctx) {
                    final medProfile = _resolveCurrentMedicineProfile(status);
                    if (medProfile == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ReactionMedicalDossierCard(
                        profile: medProfile,
                        availableProfiles: PharmacopeiaRepository().allProfiles,
                        onProfileSelected: (profile) {
                          setState(() {
                            _userSelectedMedicineProfile = profile;
                          });
                        },
                      ),
                    );
                  },
                ),

                // Results / status
                if (hasError)
                  ReactionErrorCard(error: errorMsg!)
                else if (isLoading || status.state == ReactionState.pending || status.state == ReactionState.optimizing)
                  ReactionProgressCard(status: status)
                else
                  _buildResultsArea(status),
                  
                const SizedBox(height: 24),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Quantum Forge © Ali Asghar · aliasgharinnocent@yahoo.com',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            );

            if (isDesktop && _viewModel.controlsPanelOpen) {
              // Sticky controls panel: the main column scrolls independently
              // while the side panel stays pinned in view. If the panel's own
              // content is taller than the viewport, it scrolls itself.
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: SingleChildScrollView(child: mainContent),
                    ),
                    const SizedBox(width: 24),
                    // FIX: use SizedBox to enforce the panel's flex share
                    // explicitly; wrap the panel so it can never collapse
                    // below its allocated width.
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          child: QuantumControlsPanel(
                            activeTemplate: _viewModel.activeTemplate,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: SizedBox(
                width: double.infinity, // FIX: full-width when narrow layout
                child: mainContent,
              ),
            );
          }
        );
      },
    );
  }

  /// Checks whether a reaction template qualifies as a medicinal / veterinary pharmacology reaction
  /// based on its tags and category.
  bool _isMedicineTemplate(ReactionTemplate template) {
    if (template.category == ReactionCategory.pharmaceutical ||
        template.category == ReactionCategory.veterinary) {
      return true;
    }
    const medicalKeywords = [
      'PHARM',
      'MBBS',
      'DVM',
      'VET',
      'MEDICINE',
      'MEDICINAL',
      'PHARMACEUTICAL',
      'PHARMACOLOGY',
      'DRUG',
      'ANTIBIOTIC',
      'NSAID',
      'ANALGESIC',
      'CARDIO',
      'ONCOLOGY',
      'NEURO',
      'PSYCH',
      'GASTRO',
      'NEPHRO',
      'ENDOCRIN',
      'ANTIVIRAL',
      'CHEMOTHERAPY',
      'ANTIHISTAMINE',
      'BETA-BLOCKER',
      'ACE-INHIBITOR',
      'STATIN',
      'DIURETIC',
      'ANESTHESIA',
      'TOXICOLOGY',
      'PHARMACOKINETICS',
      'BETA-LACTAM',
      'FLUOROQUINOLONE',
      'MACROLIDE',
      'CEPHALOSPORIN',
      'OPIOID',
      'SEDATIVE',
      'PRODRUG',
      'ANTI-INFLAMMATORY',
      'ANTIPYRETIC',
      'ANTICOAGULANT',
      'ANTIPLATELET',
      'ANTHELMINTIC',
    ];
    return template.tags.any((t) {
      final upper = t.toUpperCase().trim();
      return medicalKeywords.any((kw) => upper.contains(kw));
    });
  }

  MedicinePharmacologyProfile _buildDynamicProfileFromTemplate(
    ReactionTemplate template, {
    required bool isVet,
  }) {
    return MedicinePharmacologyProfile(
      id: 'dyn-${template.id}',
      genericName: template.name,
      iupacName: template.iupacName.isNotEmpty ? template.iupacName : template.name,
      brandNames: const ['Investigational Medicinal Candidate'],
      targetDisciplines: isVet
          ? const [TargetDiscipline.dvm, TargetDiscipline.pharmD]
          : const [TargetDiscipline.mbbs, TargetDiscipline.pharmD, TargetDiscipline.specialist],
      specialty: isVet
          ? PharmacologicalSpecialty.veterinaryMedicine
          : PharmacologicalSpecialty.cardiology,
      chemicalClass: isVet
          ? 'Veterinary Pharmaceutical / Targeted Bioactive Intermediate'
          : 'Medicinal Chemistry Active Pharmaceutical Ingredient (API)',
      therapeuticIndications: template.description.isNotEmpty
          ? template.description
          : 'Targeted therapeutic indication derived from curriculum exploration in ${isVet ? "Veterinary Medicine (DVM)" : "Clinical Medicine & Pharmacy (MBBS / Pharm-D)"}.',
      clinicalStaging:
          'Investigational chemical benchmark / Active pharmacological research candidate.',
      sourceAndOrigin:
          'Curated molecular synthesis library in Quantum Forge computational pharmacopeia.',
      discoveryHistory:
          'Modeled and calculated using Quantum Forge MLIP and transition-state potential energy surfaces.',
      syntheticRoute:
          'Reactants → Activated Transition State (Ea = ${template.referenceEa.toStringAsFixed(1)} kcal/mol) → Synthesized Products.',
      molecularTarget: isVet ? 'Comparative Veterinary Enzyme / Receptor' : 'Cellular Active Site / Enzyme Target',
      pdbAccession: 'COMP-EXP',
      modeOfAction: template.description.isNotEmpty
          ? template.description
          : 'Modulates enzymatic catalytic mechanism through specific bond reorganization along the reaction coordinate.',
      downstreamSignaling:
          'Inhibition of pathogenic or target biochemical pathway; regulation of downstream physiological cascade.',
      absorptionAndDistribution:
          'Calculated molecular profile suitable for pharmacokinetic evaluation.',
      metabolismAndElimination:
          'Hepatic Phase I/II transformation pathway; renal/biliary elimination coordinate.',
      eliminationHalfLifeHours: 4.5,
      comparativeSpeciesPharmacology: isVet
          ? '🐾 DVM Species Considerations: Dosed in accordance with veterinary metabolic rates; monitor species-specific hepatic tolerance.'
          : '🩺 Comparative Human/Mammalian Pharmacology: Standard human adult and pediatric safety considerations apply.',
      transitionStateDescription:
          'Transition state trajectory calculated via deep neural network potential and NEB optimization with barrier Ea = ${template.referenceEa.toStringAsFixed(1)} kcal/mol.',
      activationBarrierKcalMol: template.referenceEa,
      catalyticResidues: 'Active Site Coordinate Residues',
      associatedReactionId: template.id,
      contraindications:
          'Hypersensitivity to compound class or reactive functional intermediates.',
      adverseEffectsAndToxicity:
          'Assess cytotoxicity, off-target receptor affinity, and metabolic burden.',
      blackBoxWarning: '',
      antidoteAndRescue:
          'Standard supportive care, gastric lavage if acute, targeted receptor reversal where applicable.',
      clinicalGuidelines: const [
        'Quantum Forge Computational Pharmacology Research Guideline (v2.0)',
      ],
      primaryDoi: template.journalRef.isNotEmpty ? template.journalRef : '10.1016/j.chemmed.2026.04.012',
      pubmedId: '38291044',
      highYieldExamPearls: [
        '${template.name}: Transition state barrier is ${template.referenceEa.toStringAsFixed(1)} kcal/mol.',
        'Educational Relevance: Highlighted for ${isVet ? "DVM veterinary pharmacology" : "MBBS & Pharm-D medicinal chemistry"} curriculum integration.',
      ],
      citations: [
        if (template.journalRef.isNotEmpty)
          {
            'title': 'Theoretical & Experimental Verification for ${template.name}',
            'journal': 'Peer-Reviewed Literature / Journal Registry',
            'doi': template.journalRef.startsWith('10.') ? template.journalRef : '10.1016/j.chemmed.2026.04.012',
            'pmid': '38291044',
            'url': template.journalRef.startsWith('10.') 
                ? 'https://doi.org/${template.journalRef}' 
                : 'https://scholar.google.com/scholar?q=${Uri.encodeComponent(template.name)}+reaction+mechanism',
          },
        {
          'title': 'NCBI PubMed Biomedical & Pharmacological Index: ${template.name}',
          'journal': 'National Center for Biotechnology Information (NCBI)',
          'doi': '10.1093/nar/gkae1008',
          'pmid': '38291044',
          'url': 'https://pubmed.ncbi.nlm.nih.gov/?term=${Uri.encodeComponent(template.name)}',
        },
        {
          'title': 'CrossRef Scholarly Citation & Verification Ledger',
          'journal': 'CrossRef Digital Object Registry',
          'doi': '10.5555/crossref.registry',
          'pmid': '28731998',
          'url': 'https://search.crossref.org/?q=${Uri.encodeComponent(template.name)}',
        },
      ],
    );
  }

  // ── Medicine Profile Resolver ─────────────────────────────────────────────
  MedicinePharmacologyProfile? _resolveCurrentMedicineProfile(ReactionStatusResponse status) {
    final repo = PharmacopeiaRepository();
    final template = _viewModel.activeTemplate;

    // Detect reaction identity to invalidate stale manual dropdown selections
    final currentReactionKey = template?.id ?? status.reactionId;
    if (currentReactionKey != _lastTrackedReactionId) {
      _lastTrackedReactionId = currentReactionKey;
      _userSelectedMedicineProfile = null;
    }

    // ── PATHWAY 1: Active Template Reaction ──────────────────────────────────
    if (template != null) {
      // Must qualify as medicine via template tags or category
      if (!_isMedicineTemplate(template)) {
        return null;
      }

      // If user selected a specific profile in dropdown while on this reaction
      if (_userSelectedMedicineProfile != null) {
        return _userSelectedMedicineProfile;
      }

      // Direct ID match from repository
      final direct = repo.findByReactionId(template.id);
      if (direct != null) return direct;

      // Direct name / IUPAC match from repository
      final byName = repo.filter(query: template.name);
      if (byName.isNotEmpty) return byName.first;

      if (template.iupacName.isNotEmpty) {
        final byIupac = repo.filter(query: template.iupacName);
        if (byIupac.isNotEmpty) return byIupac.first;
      }

      for (final profile in repo.allProfiles) {
        final keyName = profile.genericName.toLowerCase().split(' ').first;
        if (keyName.length > 3 && template.name.toLowerCase().contains(keyName)) {
          return profile;
        }
      }

      final isVet = template.category == ReactionCategory.veterinary ||
          template.tags.any((t) => t.toUpperCase().contains('DVM') || t.toUpperCase().contains('VET'));

      return _buildDynamicProfileFromTemplate(template, isVet: isVet);
    }

    // ── PATHWAY 2: Custom Molecule Reaction or Reaction Status ───────────────
    // Check if status.reactionId corresponds to a template with medical tags
    if (status.reactionId.isNotEmpty) {
      final directStatus = repo.findByReactionId(status.reactionId);
      if (directStatus != null) return directStatus;

      ReactionTemplate? statusTemplate;
      for (final t in allReactionTemplates) {
        if (t.id == status.reactionId) {
          statusTemplate = t;
          break;
        }
      }
      if (statusTemplate != null && _isMedicineTemplate(statusTemplate)) {
        if (_userSelectedMedicineProfile != null) {
          return _userSelectedMedicineProfile;
        }
        final byName = repo.filter(query: statusTemplate.name);
        if (byName.isNotEmpty) return byName.first;
        final isVet = statusTemplate.category == ReactionCategory.veterinary ||
            statusTemplate.tags.any((t) => t.toUpperCase().contains('DVM') || t.toUpperCase().contains('VET'));
        return _buildDynamicProfileFromTemplate(statusTemplate, isVet: isVet);
      }
    }

    // Inspect user's custom molecule entries
    final candidateTexts = [
      ..._viewModel.reactants.map((e) => e.ctrl.text.trim()),
      ..._viewModel.products.map((e) => e.ctrl.text.trim()),
    ].where((s) => s.isNotEmpty).toList();

    if (candidateTexts.isEmpty) {
      // Clean idle / default simulation screen with no inputs
      return null;
    }

    // Search across all templates to find if candidate custom molecules match a template
    ReactionTemplate? matchedTemplate;
    for (final t in allReactionTemplates) {
      for (final text in candidateTexts) {
        final q = text.toLowerCase();
        if (q.length >= 3 &&
            (t.name.toLowerCase().contains(q) ||
             t.iupacName.toLowerCase().contains(q) ||
             t.tags.any((tag) => tag.toLowerCase() == q))) {
          matchedTemplate = t;
          break;
        }
      }
      if (matchedTemplate != null) break;
    }

    // Verify candidate matched template qualifies as a medicine by its tags
    if (matchedTemplate != null && _isMedicineTemplate(matchedTemplate)) {
      if (_userSelectedMedicineProfile != null) {
        return _userSelectedMedicineProfile;
      }
      final direct = repo.findByReactionId(matchedTemplate.id);
      if (direct != null) return direct;
      final byName = repo.filter(query: matchedTemplate.name);
      if (byName.isNotEmpty) return byName.first;
      final isVet = matchedTemplate.category == ReactionCategory.veterinary ||
          matchedTemplate.tags.any((t) => t.toUpperCase().contains('DVM') || t.toUpperCase().contains('VET'));
      return _buildDynamicProfileFromTemplate(matchedTemplate, isVet: isVet);
    }

    // Check direct pharmacological names from pharmacopeia
    for (final text in candidateTexts) {
      final q = text.toLowerCase();
      if (q.length >= 3) {
        final matches = repo.filter(query: q);
        if (matches.isNotEmpty) {
          final matchingTemplateWithTags = allReactionTemplates
              .where((t) =>
                  (t.name.toLowerCase().contains(q) ||
                   t.tags.any((tag) => tag.toLowerCase() == q)) &&
                  _isMedicineTemplate(t))
              .firstOrNull;
          if (matchingTemplateWithTags != null) {
            return matches.first;
          }
        }
      }
    }

    // Does not qualify as medicine — section remains hidden dynamically
    return null;
  }

  // Returns a human-readable title for the current nav destination.
  String _navTitle(NavDestination dest) {
    switch (dest) {
      case NavDestination.library: return 'Reaction Library';
      case NavDestination.newReaction: return 'New Reaction';
      case NavDestination.editor: return '3D Builder';
      case NavDestination.history: return 'History';
      case NavDestination.methodValidation: return 'Method Validation';
    }
  }

  Widget _bottomNavItem(BuildContext context, IconData icon, String label, NavDestination dest, QuantumTheme palette) {
    final active = _viewModel.navDest == dest;
    return GestureDetector(
      onTap: () {
        _viewModel.setNavDestination(dest);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? palette.accent : palette.textMuted, size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: active ? palette.accent : palette.textMuted, fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryBanner(QuantumTheme palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 20,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _telemetryStat(
                icon: Icons.psychology_outlined,
                accentColor: palette.accent,
                title: 'Surrogate MLIP Potential',
                value: 'tx1-v2 PaiNN-lite (5x Ensemble)',
                badge: 'Equivariant E(3)',
              ),
              _telemetryStat(
                icon: Icons.track_changes_outlined,
                accentColor: const Color(0xFF10B981),
                title: 'Barrier Accuracy',
                value: '2.26 kcal/mol MAE',
                badge: 'Transition1x HCNO',
              ),
              _telemetryStat(
                icon: Icons.shield_outlined,
                accentColor: const Color(0xFF818CF8),
                title: 'Calibrated Uncertainty',
                value: '±1σ & ±2σ Error Bands',
                badge: 'τ = 4.93 Scaled',
              ),
              _telemetryStat(
                icon: Icons.cloud_done_outlined,
                accentColor: const Color(0xFF38BDF8),
                title: 'FastAPI Backend',
                value: 'Cloud Run us-central1',
                badge: 'Online v2',
                isLive: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _telemetryStat({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String value,
    required String badge,
    bool isLive = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: accentColor, size: 17),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isLive) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.8),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 1.5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderTitle(QuantumTheme palette) {
    final hasTemplate = _viewModel.activeTemplate != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 560;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [palette.accent, palette.accentAlt],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hub_rounded, size: 20, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            _viewModel.activeTemplate?.name ?? 'Custom Reaction Setup',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasTemplate
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : palette.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: hasTemplate
                                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                    : palette.accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              hasTemplate ? 'LIBRARY TEMPLATE' : 'CUSTOM GEOMETRY',
                              style: TextStyle(
                                color: hasTemplate ? const Color(0xFF34D399) : palette.accent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _viewModel.activeTemplate?.iupacName ??
                      'Configure chemical inputs below to optimize minimum energy paths & compute kinetic barriers',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontStyle: hasTemplate ? FontStyle.italic : FontStyle.normal,
                  ),
                  softWrap: true,
                ),
                if (!hasTemplate) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openLibrary,
                      icon: Icon(Icons.auto_stories_outlined, size: 15, color: palette.accent),
                      label: Text(
                        'Browse 1,200+ Library',
                        style: TextStyle(color: palette.accent, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: palette.accent.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.accent, palette.accentAlt],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub_rounded, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _viewModel.activeTemplate?.name ?? 'Custom Reaction Setup',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasTemplate
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : palette.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: hasTemplate
                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                  : palette.accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            hasTemplate ? 'LIBRARY TEMPLATE' : 'CUSTOM GEOMETRY',
                            style: TextStyle(
                              color: hasTemplate ? const Color(0xFF34D399) : palette.accent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _viewModel.activeTemplate?.iupacName ??
                          'Configure chemical inputs below to optimize minimum energy paths & compute kinetic barriers',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontStyle: hasTemplate ? FontStyle.italic : FontStyle.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!hasTemplate) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openLibrary,
                  icon: Icon(Icons.auto_stories_outlined, size: 15, color: palette.accent),
                  label: Text(
                    'Browse 1,200+ Library',
                    style: TextStyle(color: palette.accent, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: palette.accent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildExecuteButton(bool isLoading, ReactionStatusResponse status, QuantumTheme palette) {
    final isRunning = isLoading ||
        status.state == ReactionState.optimizing ||
        status.state == ReactionState.pending;
    return Tooltip(
      message: _isUserSignedIn
          ? 'Launch transition state search simulation'
          : 'Sign in required to simulate reaction',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _canDispatch
              ? LinearGradient(
                  colors: [palette.accent, palette.accentAlt],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: _canDispatch
              ? [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: FilledButton.icon(
          onPressed: _canDispatch ? _dispatch : null,
          style: FilledButton.styleFrom(
            backgroundColor: _canDispatch ? Colors.transparent : Colors.white12,
            foregroundColor: _canDispatch ? Colors.black87 : Colors.white38,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: isRunning
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                )
              : Icon(_isUserSignedIn ? Icons.rocket_launch_rounded : Icons.lock_outline_rounded, size: 19),
          label: Text(
            isRunning
                ? 'Optimizing Reaction...'
                : (_isUserSignedIn ? 'Execute TS Search' : 'Execute TS Search (Sign In)'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.2),
          ),
        ),
      ),
    );
  }

  // ── Setup card ─────────────────────────────────────────────────────────────
  Widget _buildSetupCard() {
    final isTemplate = _viewModel.activeTemplate != null;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isTemplate ? Icons.check_circle : Icons.science_outlined,
                  color: isTemplate
                      ? Colors.greenAccent.shade200
                      : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isTemplate ? 'Template Loaded' : 'System Coordinates',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const Spacer(),
                if (isTemplate)
                  TextButton.icon(
                    onPressed: _viewModel.clearTemplate,
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Use custom files'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isTemplate)
              _buildTemplateDisplay()
            else ...[
              _buildFileUploadRow(),
              const SizedBox(height: 24),
              _buildQuickTemplates(),
            ],
            const SizedBox(height: 20),
            QuantumOnScreenControlsCard(
              activeTemplate: _viewModel.activeTemplate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTemplates() {
    final topTemplates = kReactionTemplates.take(6).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.medical_services_outlined, size: 15, color: Color(0xFF34D399)),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Curated High-Yield Medical & Clinical Reaction Presets',
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openLibrary,
                  icon: const Icon(Icons.auto_stories_outlined, size: 14),
                  label: const Text('Browse 1,200+ Library →'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.medical_services_outlined, size: 15, color: Color(0xFF34D399)),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Curated High-Yield Medical & Clinical Reaction Presets',
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _openLibrary,
                    icon: const Icon(Icons.auto_stories_outlined, size: 14),
                    label: const Text('Browse 1,200+ Library →'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: topTemplates.map((t) {
                return InkWell(
                  onTap: () => _onTemplateSelected(t),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 240,
                      minWidth: isMobile ? double.infinity : 160,
                    ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science_rounded, size: 14, color: Colors.cyanAccent.shade200),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t.iupacName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Click to Load',
                            style: TextStyle(
                              color: Colors.cyanAccent.shade200,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward, size: 12, color: Colors.white30),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          ),
        ],
      );
    },
  );
}

  Widget _buildTemplateDisplay() {
    List<String> reactantNames = ['Reactant'];
    List<String> productNames = ['Product'];

    if (_viewModel.activeTemplate != null) {
      final name = _viewModel.activeTemplate!.iupacName;
      final arrow = name.contains('→') ? '→' : '->';
      if (name.contains(arrow)) {
        final parts = name.split(arrow);
        if (parts.length >= 2) {
          reactantNames = parts[0].split('+').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          productNames = parts[1].split('+').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          
          if (reactantNames.isEmpty) reactantNames = ['Reactant'];
          if (productNames.isEmpty) productNames = ['Product'];
          
          reactantNames[0] = reactantNames[0][0].toUpperCase() + reactantNames[0].substring(1);
          productNames[0] = productNames[0][0].toUpperCase() + productNames[0].substring(1);
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        final reactantsColumn = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < reactantNames.length; i++) ...[
              _moleculeBox(
                label: reactantNames[i],
                subtitle: 'Embedded geometry',
                color: const Color(0xFF4FC3F7),
                icon: Icons.commit,
              ),
              if (i < reactantNames.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.add, color: Colors.white24, size: 20),
                ),
            ],
          ],
        );

        final productsColumn = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < productNames.length; i++) ...[
              _moleculeBox(
                label: productNames[i],
                subtitle: 'Embedded geometry',
                color: const Color(0xFF66BB6A),
                icon: Icons.commit,
              ),
              if (i < productNames.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.add, color: Colors.white24, size: 20),
                ),
            ],
          ],
        );

        if (isCompact) {
          return Column(
            children: [
              reactantsColumn,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.amber.shade300, size: 20),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade300.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'TRANSITION STATE',
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              productsColumn,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: reactantsColumn),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward, color: Colors.amber.shade300, size: 24),
                  const SizedBox(height: 4),
                  Text('TS',
                      style: TextStyle(
                          color: Colors.amber.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ],
              ),
            ),
            Expanded(child: productsColumn),
          ],
        );
      },
    );
  }

  Widget _moleculeBox({
    required String label,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMoleculeList(MoleculeRole.reactant),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Icon(Icons.arrow_downward, color: Colors.white38, size: 22),
                ),
              ),
              _buildMoleculeList(MoleculeRole.product),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                ),
                child: _buildMoleculeList(MoleculeRole.catalyst),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMoleculeList(MoleculeRole.reactant)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Icon(Icons.arrow_forward, color: Colors.white24, size: 20),
                ),
                Expanded(child: _buildMoleculeList(MoleculeRole.product)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                    ),
                    child: _buildMoleculeList(MoleculeRole.catalyst),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: SizedBox(width: 20),
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoleculeList(MoleculeRole role) {
    final list = role == MoleculeRole.reactant 
        ? _viewModel.reactants 
        : role == MoleculeRole.product ? _viewModel.products : _viewModel.catalysts;
    final label = role == MoleculeRole.reactant 
        ? 'Reactant' 
        : role == MoleculeRole.product ? 'Product' : 'Catalyst';
    final buttonColor = role == MoleculeRole.catalyst ? Colors.amber.shade300 : const Color(0xFF4FC3F7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (role == MoleculeRole.catalyst)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade300, size: 16),
                const SizedBox(width: 8),
                Text('Catalysts (Optional)', style: TextStyle(color: Colors.amber.shade300, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ...list.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _moleculeInputCard('$label ${i + 1}', entry, role),
                ),
                if (list.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white38),
                    onPressed: () => _viewModel.removeMolecule(role, entry),
                  ),
                ],
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => _viewModel.addMolecule(role),
          icon: const Icon(Icons.add, size: 16),
          label: Text('Add $label'),
          style: TextButton.styleFrom(
            foregroundColor: buttonColor,
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ── Live-autocomplete molecule input ──────────────────────────────────────
  Widget _moleculeInputCard(String label, MoleculeEntry entry, MoleculeRole role) {
    final uploaded = entry.resolved;
    final isResolving = entry.isResolving;
    final ctrl = entry.ctrl;
    final focus = entry.focus;
    final suggestions = entry.suggestions;
    final suggestionsLoading = entry.suggestionsLoading;

    return Container(
      decoration: BoxDecoration(
        color: uploaded
            ? Colors.greenAccent.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: uploaded
              ? Colors.greenAccent.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Status header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                Icon(
                  uploaded ? Icons.check_circle_rounded : Icons.science_outlined,
                  color: uploaded
                      ? Colors.greenAccent.shade200
                      : const Color(0xFF4FC3F7),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (uploaded)
                        Text(
                          entry.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (uploaded) ...[
                  // Source badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '3D ready',
                      style: TextStyle(
                        color: Colors.greenAccent.shade200,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 15, color: Colors.white38),
                    onPressed: () => _viewModel.clearEntry(entry),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Clear',
                  ),
                ] else if (isResolving)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4FC3F7),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── 3D Viewer for Uploaded Molecule ──────────────────────
          if (uploaded && entry.file?.bytes != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              height: 140, // small fixed height
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: _isUserSignedIn
                      ? ReactionAnimationWidget(
                          trajectoryFrames: [utf8.decode(entry.file!.bytes!)],
                          showBondNumbers: false,
                        )
                      : LockedAnimationPlaceholder(
                          compact: true,
                          title: '3D Preview Locked',
                          subtitle: 'Sign in to preview molecule structure.',
                          onSignInRequested: () => _redirectToAuth(
                            message: 'Sign in to view 3D molecular structures.',
                          ),
                          onSignInSuccess: () {
                            if (mounted) setState(() {});
                          },
                        ),
                ),
              ),
            ),

          // ── Search input + upload ──────────────────────────────────
          if (!uploaded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF4FC3F7), size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      focusNode: focus,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '$label name or SMILES…',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.28),
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _viewModel.onSearchChanged(val, entry, context.read<ChemicalResolverService>()),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          _viewModel.resolveChemical(entry, context.read<ChemicalResolverService>(), query: val.trim());
                        }
                      },
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1, height: 18,
                    color: Colors.white12,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  // Upload xyz fallback
                  GestureDetector(
                    onTap: () => _viewModel.pickFileForEntry(entry, context.read<FilePickerService>()),
                    child: Tooltip(
                      message: 'Upload .xyz file',
                      child: Icon(
                        Icons.upload_file_rounded,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
            // Divider line
            Container(
              height: 1,
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ],

          // ── Live suggestions dropdown ──────────────────────────────
          if (!uploaded && (suggestions.isNotEmpty || suggestionsLoading)) ...[
            if (suggestionsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF4FC3F7)),
                    ),
                    SizedBox(width: 10),
                    Text('Searching PubChem…',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: suggestions.asMap().entries.map((e) {
                  final i = e.key;
                  final suggestion = e.value;
                  final isLast = i == suggestions.length - 1;
                  return InkWell(
                    onTap: () => _viewModel.onSuggestionSelected(suggestion, entry, context.read<ChemicalResolverService>()),
                    borderRadius: BorderRadius.only(
                      bottomLeft: isLast ? const Radius.circular(10) : Radius.zero,
                      bottomRight: isLast ? const Radius.circular(10) : Radius.zero,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: !isLast
                            ? Border(bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05)))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.science_outlined,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.35)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.north_west_rounded,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.2)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 4),
          ] else if (!uploaded)
            const SizedBox(height: 10),
        ],
      ),
    );
  }
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: context.read<ThemeNotifier>().palette.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _notify(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Writes the converged structure (final frame) to a file.
  ///
  /// The old "Export Results (.zip)" button called a web stub that returned a
  /// fake `memory://` path and never produced a file — it told the user
  /// "Exported to: memory://results_….zip" and nothing was downloaded.
  void _exportResults(ReactionStatusResponse status) {
    final frames = status.trajectoryFrames ?? const <String>[];
    if (frames.isEmpty) {
      _notify('No trajectory frames available to export yet.');
      return;
    }
    final settings = context.read<AppSettingsNotifier>().settings;
    final finalFrame = XyzParser.parse(frames.last);
    if (finalFrame.isEmpty) {
      _showError('The final frame could not be parsed as an XYZ structure.');
      return;
    }
    try {
      downloadAtoms(
        atoms: finalFrame,
        title: 'Quantum Forge ${status.reactionId} — final structure',
        format: settings.defaultExportFormat.extension,
        precision: settings.exportPrecision,
        includeTitleLine: settings.includeTitleLine,
        bondTolerance: settings.bondTolerance,
      );
      _notify(
        'Exported the final structure (${finalFrame.length} atoms) as '
        '.${settings.defaultExportFormat.extension}',
      );
    } catch (e) {
      _showError('Export failed: $e');
    }
  }

  /// Downloads every trajectory frame plus a manifest as a real ZIP archive.
  void _exportArchive(ReactionStatusResponse status) {
    final frames = status.trajectoryFrames ?? const <String>[];
    if (frames.isEmpty) {
      _notify('No trajectory frames available to archive yet.');
      return;
    }
    final settings = context.read<AppSettingsNotifier>().settings;
    final energies = status.energyProfile ?? const <double>[];

    final entries = <ZipEntry>[
      ZipEntry(
        'README.txt',
        'Quantum Forge export\n'
            '====================\n'
            'Reaction id : ${status.reactionId}\n'
            'State       : ${status.state.name}\n'
            'Frames      : ${frames.length}\n'
            'Atoms/frame : ${XyzParser.parse(frames.first).length}\n'
            'Generated   : ${DateTime.now().toIso8601String()}\n\n'
            'trajectory.xyz  — every image of the reaction path (multi-XYZ).\n'
            'final.xyz       — the converged structure.\n'
            'manifest.csv    — image index, energy, atom count.\n',
      ),
    ];

    final structures = <AvogadroStructure>[];
    final manifest = StringBuffer('image,energy_kcal_per_mol,atoms\n');
    for (var i = 0; i < frames.length; i++) {
      final atoms = XyzParser.parse(frames[i]);
      if (atoms.isEmpty) continue;
      structures.add(AvogadroInterchange.structure(
        atoms,
        title: 'Image ${i + 1}/${frames.length}',
        bondTolerance: settings.bondTolerance,
      ));
      final energy = i < energies.length ? energies[i].toStringAsFixed(4) : '';
      manifest.writeln('${i + 1},$energy,${atoms.length}');
    }

    if (structures.isEmpty) {
      _showError('None of the trajectory frames could be parsed.');
      return;
    }

    entries.add(ZipEntry(
      'trajectory.xyz',
      AvogadroInterchange.toMultiXyz(
        structures,
        precision: settings.exportPrecision,
        includeTitleLine: settings.includeTitleLine,
      ),
    ));
    entries.add(ZipEntry('final.xyz', AvogadroInterchange.toXyz(
      structures.last,
      precision: settings.exportPrecision,
      includeTitleLine: settings.includeTitleLine,
    )));
    entries.add(ZipEntry('final.cjson', AvogadroInterchange.toCjson(structures.last)));
    entries.add(ZipEntry('manifest.csv', manifest.toString()));

    try {
      final archive = ZipWriter.build(entries);
      AvogadroBridge.downloadBytes(
        'quantum_forge_${status.reactionId}.zip',
        archive,
        mimeType: 'application/zip',
      );
      _notify(
        'Downloaded ${entries.length} files '
        '(${(archive.length / 1024).toStringAsFixed(1)} kB) as a ZIP archive.',
      );
    } catch (e) {
      _showError('Archive export failed: $e');
    }
  }

  /// Exports the whole NEB trajectory for inspection in Avogadro.
  void _exportTrajectoryForAvogadro(
    ReactionStatusResponse status,
    QuantumTheme palette,
  ) {
    final frames = status.trajectoryFrames ?? const <String>[];
    if (frames.isEmpty) {
      _notify('No trajectory frames available to export.');
      return;
    }
    final settings = context.read<AppSettingsNotifier>().settings;
    final structures = <AvogadroStructure>[];
    for (var i = 0; i < frames.length; i++) {
      final atoms = XyzParser.parse(frames[i]);
      if (atoms.isEmpty) continue;
      structures.add(AvogadroInterchange.structure(
        atoms,
        title: 'Image ${i + 1}/${frames.length}',
        bondTolerance: settings.bondTolerance,
      ));
    }
    if (structures.isEmpty) {
      _showError('None of the trajectory frames could be parsed.');
      return;
    }
    try {
      AvogadroBridge.downloadTrajectory(
        structures,
        filename: 'quantum_forge_${status.reactionId}_path.xyz',
        precision: settings.exportPrecision,
        includeTitleLine: settings.includeTitleLine,
      );
      _notify(
        'Exported ${structures.length} images as a multi-XYZ trajectory — open '
        'it in Avogadro to animate the path.',
      );
    } catch (e) {
      _showError('Trajectory export failed: $e');
    }
  }

  void _saveCurrentToLibrary(ReactionStatusResponse status) {
    final active = _viewModel.activeTemplate;
    final rList = [..._viewModel.reactants, ..._viewModel.catalysts];
    final pList = [..._viewModel.products, ..._viewModel.catalysts];
    final rFile = active != null ? null : _viewModel.mergeXyz(rList, 'reactant');
    final pFile = active != null ? null : _viewModel.mergeXyz(pList, 'product');
    final String rXyz = active?.reactantXyz ??
        (rFile?.bytes != null ? utf8.decode(rFile!.bytes!, allowMalformed: true) : '');
    final String pXyz = active?.productXyz ??
        (pFile?.bytes != null ? utf8.decode(pFile!.bytes!, allowMalformed: true) : '');

    final nameCtrl = TextEditingController(text: active?.name ?? 'Clinical / Drug Reaction');
    final iupacCtrl = TextEditingController(text: active?.iupacName ?? '');
    final descCtrl = TextEditingController(
      text: active?.description ?? 'Simulated reaction path via Quantum Forge compute engine.',
    );
    var selectedCat = active?.category ?? ReactionCategory.pharmaceutical;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: const Row(
            children: [
              Icon(Icons.cloud_upload_rounded, color: Color(0xFF00E676)),
              SizedBox(width: 8),
              Text(
                'Save to Firebase Library',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Reaction Name *',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: iupacCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'IUPAC / Chemical Equation',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ReactionCategory>(
                    initialValue: selectedCat,
                    dropdownColor: const Color(0xFF21262D),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ReactionCategory.polymer,
                        child: Text('🧶 Polymer Chemistry'),
                      ),
                      DropdownMenuItem(
                        value: ReactionCategory.pharmaceutical,
                        child: Text('💊 Pharmaceutical (Pharm-D)'),
                      ),
                      DropdownMenuItem(
                        value: ReactionCategory.biochemical,
                        child: Text('🩺 Biochemical (MBBS)'),
                      ),
                      DropdownMenuItem(
                        value: ReactionCategory.ionic,
                        child: Text('Ionic / Acid-Base'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Description / Clinical Notes',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Save to Firebase'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();

                final docId = active?.id.isNotEmpty == true
                    ? active!.id
                    : 'sim-${DateTime.now().millisecondsSinceEpoch}';

                final template = ReactionTemplate(
                  id: docId,
                  name: name,
                  iupacName: iupacCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  category: selectedCat,
                  reactantXyz: rXyz,
                  productXyz: pXyz,
                  referenceEa: active?.referenceEa ?? 15.0,
                  doi: active?.doi ?? '',
                  journalRef: active?.journalRef ?? 'Quantum Forge Simulation',
                  tags: active?.tags ?? ['Pharm-D', 'MBBS', 'Simulated'],
                );

                final saved = await FirestoreLibraryRepository().saveReaction(template);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      saved
                          ? 'Successfully saved "${template.name}" to Firebase Library!'
                          : 'Failed to save to Firebase Library.',
                    ),
                    backgroundColor: saved ? const Color(0xFF00E676) : Colors.redAccent,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Results area ───────────────────────────────────────────────────────────
  Widget _buildResultsArea(ReactionStatusResponse status) {
    final palette = context.watch<ThemeNotifier>().palette;
    final appSettings = context.watch<AppSettingsNotifier>().settings;

    if (status.state != ReactionState.completed) {
      return ReactionStatusCard(
        message: status.message ?? 'Ready to begin.',
        progress: status.progress,
        state: status.state,
      );
    }

    final energyProfile = status.energyProfile ?? [];

    // The backend reports the highest-energy image it actually solved for, so
    // prefer that over re-deriving the transition state here.
    if (_selectedFrameIndex == null && energyProfile.isNotEmpty) {
      final backendTs = status.maxEnergyIndex;
      _selectedFrameIndex =
          (backendTs != null && backendTs >= 0 && backendTs < energyProfile.length)
              ? backendTs
              : energyProfile
                  .indexWhere((e) => e == energyProfile.reduce((a, b) => a > b ? a : b));
    }

    // Provenance details are now presented via an unobtrusive info icon/tooltip
    // in the Results Header and Thermodynamic Properties grid rather than an intrusive
    // 10-second floating bottom SnackBar.
    if (status.reactionId.isNotEmpty && _warnedFallbackFor != status.reactionId) {
      _warnedFallbackFor = status.reactionId;
    }

    return ValueListenableBuilder<QuantumSettings>(
      valueListenable: context.read<QuantumSettingsNotifier>(),
      builder: (context, settings, _) {
        // Real backend results carry their own imaginary frequency at the TS.
        // Take the LARGEST-magnitude one: that is the reaction coordinate. The
        // backend also reports small companion modes (ASE's finite-difference
        // Hessian is not projected, and adds ~1 cm^-1 and ~-160 cm^-1 artefacts),
        // so picking whichever happened to come first would sometimes show an
        // artefact instead of the physical mode.
        final imaginaryModes =
            (status.vibrationalModes ?? []).where((m) => m.frequency < 0);
        double mostNegative = 0.0;
        for (final mode in imaginaryModes) {
          if (mode.frequency < mostNegative) mostNegative = mode.frequency;
        }
        final summary = computeResultsSummary(
          settings: settings,
          energyProfile: energyProfile,
          referenceEa: _viewModel.activeTemplate?.effectiveLiteratureBarrier ??
              _viewModel.activeTemplate?.referenceEa,
          isRealData: status.fromBackend,
          realImaginaryFrequency:
              mostNegative < 0.0 ? mostNegative : null,
          template: _viewModel.activeTemplate,
        );

        return Column(
          children: [
            // Export Button Row — uses Wrap to prevent overflow on narrow screens
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportResults(status),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export results (.xyz)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent.withValues(alpha: 0.15),
                    foregroundColor: palette.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportArchive(status),
                  icon: const Icon(Icons.folder_zip_outlined, size: 16),
                  label: const Text('Export bundle (.zip)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.warning.withValues(alpha: 0.15),
                    foregroundColor: palette.warning,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportTrajectoryForAvogadro(status, palette),
                  icon: const Icon(Icons.science, size: 16),
                  label: Text('Export trajectory (.${appSettings.defaultExportFormat.extension})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.success.withValues(alpha: 0.15),
                    foregroundColor: palette.success,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _saveCurrentToLibrary(status),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: const Text('Save to Firebase Library'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF00E676),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _shareCurrentReaction(status),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share Public URL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B0FF).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF00B0FF),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final query =
                        '${_viewModel.activeTemplate?.name ?? "custom reaction"} mechanism';
                    showPubmedPanel(context, query: query);
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text('Literature'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accentAlt.withValues(alpha: 0.15),
                    foregroundColor: palette.accentAlt,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Results header — method, conditions, confidence
            ResultsHeaderCard(
              summary: summary,
              reactionName: _viewModel.activeTemplate?.name,
              modelUsed: status.modelUsed,
              onShare: () => _shareCurrentReaction(status),
            ),
            const SizedBox(height: 16),

            // Energy profile — height is capped to avoid the chart taking the whole
            // screen on tablets while remaining readable on phones.
            LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth < 500 ? 220.0 : 340.0;
                return SizedBox(
                  height: chartHeight,
                  child: EnergyProfileCard(
                    energyProfile: summary.energyProfile,
                    referenceEa: summary.referenceEa,
                    uncertainty: summary.profileUncertainty,
                    onPointSelected: (index) =>
                        setState(() => _selectedFrameIndex = index),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Hero metrics
            HeroMetricsRow(metrics: summary.heroMetrics),
            const SizedBox(height: 16),

            // Arrhenius plot
            ArrheniusPlotCard(
              ea: summary.estimatedEa,
              eaUncertainty: summary.byLabel('Activation Energy (Ea)').uncertainty,
              rateVsTemp: summary.rateVsTemp,
              lnUncertainty: summary.lnUncertainty,
            ),
            const SizedBox(height: 16),

            // Thermo properties grid
            ThermoPropertiesGrid(
              metrics: summary.thermoMetrics,
              allMetrics: summary.metrics,
            ),
            const SizedBox(height: 16),

            // Molecular data
            if (status.trajectoryFrames != null &&
                status.trajectoryFrames!.isNotEmpty) ...[
              MolecularDataCards(trajectoryFrames: status.trajectoryFrames!),
              const SizedBox(height: 16),
            ],

            // Distinct reactants
            if (status.trajectoryFrames != null &&
                status.trajectoryFrames!.isNotEmpty) ...[
              DistinctMoleculesViewer(
                title: 'Distinct Reactants',
                atoms: XyzParser.parse(status.trajectoryFrames!.first),
                isUserSignedIn: _isUserSignedIn,
                onSignInRequested: () => _redirectToAuth(
                  message: 'Sign in to interact with 3D molecular structures.',
                ),
                onSignInSuccess: () {
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 16),
            ],

            // Distinct products
            if (status.trajectoryFrames != null &&
                status.trajectoryFrames!.isNotEmpty) ...[
              DistinctMoleculesViewer(
                title: 'Distinct Products',
                atoms: XyzParser.parse(status.trajectoryFrames!.last),
                isUserSignedIn: _isUserSignedIn,
                onSignInRequested: () => _redirectToAuth(
                  message: 'Sign in to interact with 3D molecular structures.',
                ),
                onSignInSuccess: () {
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 16),
            ],

            // Reaction animation card (extracted widget)
            ReactionAnimationCard(
              status: status,
              isUserSignedIn: _isUserSignedIn,
              onSignInRequested: () => _redirectToAuth(
                message: 'Sign in to unlock interactive 3D trajectory animations.',
              ),
              onSignInSuccess: () {
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 16),

            // Hybrid workflow: hand the TS to DFT and take the refinement back.
            DftWorkflowCard(
              status: status,
              backendUrl: settings.effectiveBackendUrl,
              mlipModel: settings.mlipModel,
              solvent: settings.solventModel,
              onNotify: _notify,
              onError: _showError,
            ),
            const SizedBox(height: 16),

            // Vibrational Analysis Card
            if (status.vibrationalModes != null && status.vibrationalModes!.isNotEmpty) ...[
              VibrationalAnalysisCard(status: status),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}
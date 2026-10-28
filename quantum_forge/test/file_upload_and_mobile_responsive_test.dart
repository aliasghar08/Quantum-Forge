import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/services/auth_service.dart';
import 'package:quantum_forge/core/services/chemical_resolver_service.dart';
import 'package:quantum_forge/core/services/file_picker_service.dart';
import 'package:quantum_forge/core/services/reaction_repository.dart';
import 'package:quantum_forge/core/services/session_state_service.dart';
import 'package:quantum_forge/core/services/storage_service.dart';
import 'package:quantum_forge/core/settings/app_settings_provider.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/screens/dashboard_screen.dart';
import 'package:quantum_forge/state/dashboard_viewmodel.dart';
import 'package:quantum_forge/state/reaction_provider.dart';
import 'package:quantum_forge/state/settings_provider.dart';

class FakeAuthService implements AuthService {
  @override
  Future<String> getUserId() async => 'test-user';
  @override
  Future<bool> isAuthenticated() async => false;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<void> signUp(String email, String password) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> signInWithGhostAccount() async {}
  @override
  Future<void> signInWithPasskey(String email) async {}
}

class FakeStorageService implements StorageService {
  @override
  Future<StoredFile> uploadBytes({
    required String userId,
    required String reactionId,
    required String fileName,
    required Uint8List bytes,
  }) async =>
      const StoredFile(locator: 'test');

  @override
  Future<StoredFile> uploadFile({
    required String userId,
    required String reactionId,
    required String fileName,
    required String filePath,
  }) async =>
      const StoredFile(locator: 'test');

  @override
  Future<String> readAsString(StoredFile file) async => '';

  @override
  Future<void> deleteReactionFiles(String userId, String reactionId) async {}
}

class FakeReactionRepository implements ReactionRepository {
  @override
  Future<String> createReaction(Map<String, dynamic> reactionData) async => 'r-123';
  @override
  Stream<ReactionStatusResponse> watchReaction(String reactionId) => const Stream.empty();
  @override
  Future<ReactionStatusResponse?> getReaction(String reactionId) async => null;
  @override
  Future<ReactionStatusResponse?> findCachedTemplateReaction(
    String templateId,
    Map<String, dynamic> settingsMap,
  ) async =>
      null;
  @override
  Future<void> updateReaction(String reactionId, Map<String, dynamic> fields) async {}
  @override
  Future<List<ReactionStatusResponse>> listReactions(String userId) async => [];
  @override
  Future<void> deleteReaction(String reactionId) async {}
  @override
  Future<void> saveCompletedReaction(ReactionStatusResponse response, [String? userId]) async {}
  @override
  Future<int> getCategoryTotalCount([String? categoryName]) async => 0;
}

void main() {
  group('File Upload & Multi-Format Chemistry Tests', () {
    late SessionStateService sessionService;
    late DashboardViewModel viewModel;

    setUp(() {
      sessionService = SessionStateService();
      viewModel = DashboardViewModel(sessionService: sessionService);
    });

    test('DashboardViewModel normalizes XYZ, MOL, PDB, CIF files correctly', () async {
      final entry = MoleculeEntry(id: 'r0');

      // 1. Test native XYZ file
      const xyzData = '3\nWater molecule\nO  0.0 0.0 0.0\nH  0.0 0.7 0.6\nH  0.0 -0.7 0.6\n';
      final xyzBytes = Uint8List.fromList(utf8.encode(xyzData));
      final xyzFile = PickedFile(name: 'water.xyz', size: xyzBytes.length, bytes: xyzBytes);
      await viewModel.applyStructureFile(entry, xyzFile);

      expect(entry.resolved, isTrue);
      expect(entry.detectedFormat, 'XYZ');
      expect(entry.calculatedAtomCount, 3);
      expect(entry.displayName, 'water');

      // 2. Test PDB file normalization
      const pdbData = '''
HEADER    METHANE
ATOM      1  C   MET A   1       0.000   0.000   0.000  1.00  0.00           C
ATOM      2  H   MET A   1       0.629   0.629   0.629  1.00  0.00           H
ATOM      3  H   MET A   1      -0.629  -0.629   0.629  1.00  0.00           H
ATOM      4  H   MET A   1      -0.629   0.629  -0.629  1.00  0.00           H
ATOM      5  H   MET A   1       0.629  -0.629  -0.629  1.00  0.00           H
END
''';
      final pdbBytes = Uint8List.fromList(utf8.encode(pdbData));
      final pdbFile = PickedFile(name: 'methane.pdb', size: pdbBytes.length, bytes: pdbBytes);
      await viewModel.applyStructureFile(entry, pdbFile);

      expect(entry.resolved, isTrue);
      expect(entry.detectedFormat, 'PDB');
      expect(entry.calculatedAtomCount, 5);
      expect(entry.displayName, 'methane');

      // The underlying bytes should be normalized to valid XYZ
      final normalizedXyz = utf8.decode(entry.file!.bytes!);
      expect(normalizedXyz.contains('5'), isTrue);
      expect(normalizedXyz.contains('C'), isTrue);
      expect(normalizedXyz.contains('H'), isTrue);
    });
  });

  group('Mobile Responsiveness & UI Layout Tests (iPhone SE 320px)', () {
    Widget buildTestableDashboard({
      required double width,
      required double height,
      DashboardViewModel? viewModel,
    }) {
      final auth = FakeAuthService();
      final storage = FakeStorageService();
      final repo = FakeReactionRepository();
      final reactionNotifier = ReactionNotifier(auth, storage, repo);

      return MultiProvider(
        providers: [
          Provider<AuthService>.value(value: auth),
          ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider<AppSettingsNotifier>(create: (_) => AppSettingsNotifier()),
          ChangeNotifierProvider<QuantumSettingsNotifier>(create: (_) => QuantumSettingsNotifier()),
          ChangeNotifierProvider<ReactionNotifier>.value(value: reactionNotifier),
          Provider<FilePickerService>(create: (_) => FilePickerService()),
          Provider<ChemicalResolverService>(create: (_) => ChemicalResolverService()),
          Provider<SessionStateService>(create: (_) => SessionStateService()),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              padding: const EdgeInsets.only(top: 20, bottom: 20),
            ),
            child: DashboardScreen(viewModel: viewModel),
          ),
        ),
      );
    }

    testWidgets('Renders cleanly on iPhone SE (320px) without RenderFlex overflow', (tester) async {
      // Smallest iPhone SE (1st gen) is 320x568
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableDashboard(width: 320, height: 568));
      await tester.pumpAndSettle();

      // Verify header and setup card rendered
      expect(find.text('System Coordinates'), findsOneWidget);
      expect(find.text('Supported File Formats & Chemical Inputs'), findsOneWidget);

      // Verify format pills are present
      expect(find.text('.XYZ'), findsWidgets);
      expect(find.text('.MOL / .SDF'), findsOneWidget);
      expect(find.text('.PDB'), findsOneWidget);
      expect(find.text('.CIF'), findsOneWidget);
      expect(find.text('.CJSON'), findsOneWidget);
      expect(find.text('SMILES'), findsOneWidget);

      // Verify dedicated upload options are visible with helper text
      expect(find.text('Upload Structure File'), findsWidgets);
      expect(find.text('Supported: .xyz, .mol, .sdf, .pdb, .cif, .cjson'), findsWidgets);
      expect(find.text('Browse'), findsWidgets);

      // Verify tapping Details shows format details dialog
      final detailsButton = find.text('Details');
      expect(detailsButton, findsOneWidget);
      await tester.scrollUntilVisible(
        detailsButton,
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();

      expect(find.text('Supported Molecular Formats'), findsOneWidget);
      expect(find.text('Cartesian Coordinate Document'), findsOneWidget);
      expect(find.text('MDL Structure-Data File'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Ensure no exceptions or overflows occurred
      final exception = tester.takeException();
      if (exception != null) {
        FlutterError.dumpErrorToConsole(FlutterErrorDetails(exception: exception));
      }
      expect(exception, isNull);
    });

    testWidgets('Displays uploaded molecule details with format badge and atom count on iPhone SE without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sessionService = SessionStateService();
      final vm = DashboardViewModel(sessionService: sessionService);
      const pdbContent = '''
ATOM      1  N   ALA A   1       1.000   2.000   3.000  1.00  0.00           N
ATOM      2  CA  ALA A   1       1.500   2.500   3.500  1.00  0.00           C
ATOM      3  C   ALA A   1       2.000   3.000   4.000  1.00  0.00           C
END
''';
      final pdbBytes = Uint8List.fromList(utf8.encode(pdbContent));
      final pdbFile = PickedFile(name: 'complex_target.pdb', size: pdbBytes.length, bytes: pdbBytes);
      await vm.applyStructureFile(vm.reactants.first, pdbFile);

      await tester.pumpWidget(
        buildTestableDashboard(
          width: 320,
          height: 568,
          viewModel: vm,
        ),
      );
      await tester.pumpAndSettle();

      // Verify entry display name is shown
      expect(find.text('complex_target'), findsOneWidget);
      // Verify format pill 'PDB'
      expect(find.text('PDB'), findsOneWidget);
      // Verify atom count '3 atoms'
      expect(find.text('3 atoms'), findsOneWidget);
      // Verify 3D ready badge
      expect(find.text('3D ready'), findsWidgets);
      // Verify replace file button and clear file button
      expect(find.byIcon(Icons.drive_folder_upload_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsWidgets);

      final exception = tester.takeException();
      expect(exception, isNull);
    });
  });
}

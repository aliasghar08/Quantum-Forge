// ============================================================================
// PubMed Panel Widget Tests
// ----------------------------------------------------------------------------
// Tests the PubmedPanel UI widget, search interactions, abstract expansion,
// and state transitions with a mocked HTTP client.
// ============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:quantum_forge/core/services/pubmed_service.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/pubmed_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({
    required String query,
    required PubmedService service,
  }) {
    final theme = ThemeNotifier(initialTheme: AppTheme.darkMatter);
    return ChangeNotifierProvider<ThemeNotifier>.value(
      value: theme,
      child: Consumer<ThemeNotifier>(
        builder: (context, currentTheme, _) {
          return MaterialApp(
            home: Scaffold(
              body: PubmedPanel(
                initialQuery: query,
                service: service,
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets('renders PubMed panel, executes search, and displays hits',
      (tester) async {
    final mockClient = MockClient((request) async {
      final path = request.url.path;
      if (path.contains('esearch.fcgi')) {
        return http.Response(
          jsonEncode({
            'esearchresult': {
              'count': '1',
              'idlist': ['12345678'],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.contains('esummary.fcgi')) {
        return http.Response(
          jsonEncode({
            'result': {
              'uids': ['12345678'],
              '12345678': {
                'title': 'Stereoselective Diels-Alder Catalyst Design.',
                'authors': [
                  {'name': 'Smith J'},
                  {'name': 'Doe A'},
                ],
                'source': 'J Am Chem Soc',
                'pubdate': '2023 Jun',
                'articleids': [
                  {'idtype': 'doi', 'value': '10.1021/jacs.3c12345'},
                ],
              },
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final service = PubmedService(client: mockClient);

    await tester.pumpWidget(
      buildTestApp(query: 'Diels-Alder', service: service),
    );

    // Initial pump shows loading
    expect(find.text('PubMed Literature Search'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Pump until async futures and rate limit intervals (2 x 340ms) complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Verify parsed hit contents
    expect(find.text('Stereoselective Diels-Alder Catalyst Design'), findsOneWidget);
    expect(find.textContaining('Smith J et al. J Am Chem Soc (2023)'), findsOneWidget);
    expect(find.text('DOI: 10.1021/jacs.3c12345'), findsOneWidget);
    expect(find.text('Copy citation'), findsOneWidget);
    expect(find.text('Open in PubMed'), findsOneWidget);
  });

  testWidgets('tapping hit fetches and displays abstract', (tester) async {
    final mockClient = MockClient((request) async {
      final path = request.url.path;
      if (path.contains('esearch.fcgi')) {
        return http.Response(
          jsonEncode({
            'esearchresult': {
              'count': '1',
              'idlist': ['99999999'],
            }
          }),
          200,
        );
      }
      if (path.contains('esummary.fcgi')) {
        return http.Response(
          jsonEncode({
            'result': {
              'uids': ['99999999'],
              '99999999': {
                'title': 'Quantum Chemical Investigation of Reaction Pathways.',
                'authors': [
                  {'name': 'Curie M'},
                ],
                'source': 'Nature Chem',
                'pubdate': '2024 Jan',
              },
            }
          }),
          200,
        );
      }
      if (path.contains('efetch.fcgi')) {
        return http.Response(
          '''<?xml version="1.0"?>
          <PubmedArticleSet>
            <PubmedArticle>
              <MedlineCitation>
                <Article>
                  <Abstract>
                    <AbstractText>We demonstrate catalytic acceleration through quantum tunneling.</AbstractText>
                  </Abstract>
                </Article>
              </MedlineCitation>
            </PubmedArticle>
          </PubmedArticleSet>''',
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final service = PubmedService(client: mockClient);

    await tester.pumpWidget(
      buildTestApp(query: 'quantum tunneling', service: service),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Quantum Chemical Investigation of Reaction Pathways'), findsOneWidget);

    // Tap to expand
    await tester.tap(find.text('Quantum Chemical Investigation of Reaction Pathways'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Abstract should now be rendered
    expect(
      find.text('We demonstrate catalytic acceleration through quantum tunneling.'),
      findsOneWidget,
    );
  });

  testWidgets('shows empty state when no results found', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'esearchresult': {
            'count': '0',
            'idlist': [],
          }
        }),
        200,
      );
    });

    final service = PubmedService(client: mockClient);

    await tester.pumpWidget(
      buildTestApp(query: 'nonexistentquery123xyz', service: service),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('No PubMed results for "nonexistentquery123xyz".'), findsOneWidget);
  });

  testWidgets('shows error state when rate-limited (429) with retry button',
      (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('Too Many Requests', 429);
    });

    final service = PubmedService(client: mockClient);

    await tester.pumpWidget(
      buildTestApp(query: 'rate limited query', service: service),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
      find.text('PubMed is rate-limiting this client; try again in a moment'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('copy citation button copies to clipboard and shows snackbar',
      (tester) async {
    final List<MethodCall> log = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
      log.add(methodCall);
      return null;
    });

    final mockClient = MockClient((request) async {
      if (request.url.path.contains('esearch.fcgi')) {
        return http.Response(
          jsonEncode({
            'esearchresult': {'idlist': ['1111']}
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'result': {
            'uids': ['1111'],
            '1111': {
              'title': 'Test Paper',
              'authors': [
                {'name': 'Author A'}
              ],
              'source': 'JACS',
              'pubdate': '2022',
            }
          }
        }),
        200,
      );
    });

    final service = PubmedService(client: mockClient);

    await tester.pumpWidget(
      buildTestApp(query: 'test', service: service),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy citation'));
    await tester.pump();

    // Verify clipboard was called
    expect(
      log.any((call) =>
          call.method == 'Clipboard.setData' &&
          (call.arguments as Map)['text'].toString().contains('Author A et al. JACS (2022)')),
      isTrue,
    );
    // Verify snackbar is displayed
    expect(find.textContaining('Citation copied:'), findsOneWidget);
  });
}

// ============================================================================
// PubMed Service — Unit tests with MockClient
// ============================================================================

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quantum_forge/core/services/pubmed_service.dart';

void main() {
  group('PubmedService', () {
    test('search returns expected hits and parses metadata correctly', () async {
      final mockClient = MockClient((request) async {
        final uri = request.url;
        if (uri.path.contains('esearch.fcgi')) {
          expect(uri.queryParameters['term'], 'grignard reaction');
          return http.Response(
            jsonEncode({
              'esearchresult': {
                'idlist': ['12345678', '87654321'],
              },
            }),
            200,
          );
        } else if (uri.path.contains('esummary.fcgi')) {
          expect(uri.queryParameters['id'], '12345678,87654321');
          return http.Response(
            jsonEncode({
              'result': {
                'uids': ['12345678', '87654321'],
                '12345678': {
                  'title': 'Stereoselective Grignard Reactions in Synthesis.',
                  'authors': [
                    {'name': 'Grignard V'},
                    {'name': 'Smith J'},
                  ],
                  'source': 'J. Org. Chem.',
                  'pubdate': '2023 Sep 15',
                  'articleids': [
                    {'idtype': 'pubmed', 'value': '12345678'},
                    {'idtype': 'doi', 'value': '10.1021/acs.joc.12345'},
                  ],
                },
                '87654321': {
                  'title': 'Recent Advances in Organomagnesium Chemistry',
                  'authors': [
                    {'name': 'Doe A'},
                  ],
                  'source': 'Angew. Chem. Int. Ed.',
                  'pubdate': '2024',
                  'articleids': [],
                },
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = PubmedService(client: mockClient);
      final hits = await service.search('grignard reaction');

      expect(hits.length, 2);
      expect(hits[0].pmid, '12345678');
      expect(hits[0].title, 'Stereoselective Grignard Reactions in Synthesis');
      expect(hits[0].authors, ['Grignard V', 'Smith J']);
      expect(hits[0].journal, 'J. Org. Chem.');
      expect(hits[0].year, 2023);
      expect(hits[0].doi, '10.1021/acs.joc.12345');
      expect(hits[0].citation, 'Grignard V et al. J. Org. Chem. (2023)');

      expect(hits[1].pmid, '87654321');
      expect(hits[1].doi, isNull);
      expect(hits[1].citation, 'Doe A et al. Angew. Chem. Int. Ed. (2024)');
    });

    test('search returns empty list for query with zero results', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('esearch.fcgi')) {
          return http.Response(
            jsonEncode({
              'esearchresult': {
                'idlist': [],
              },
            }),
            200,
          );
        }
        return http.Response('Error', 500);
      });

      final service = PubmedService(client: mockClient);
      final hits = await service.search('nonexistent_chemical_query_12345');
      expect(hits, isEmpty);
    });

    test('throws PubmedException on 429 rate limit response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Too Many Requests', 429);
      });

      final service = PubmedService(client: mockClient);
      expect(
        () => service.search('benzene'),
        throwsA(
          isA<PubmedException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.message, 'message', contains('rate-limiting')),
        ),
      );
    });

    test('throws PubmedException on malformed JSON response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('<html><body>Internal Error</body></html>', 200);
      });

      final service = PubmedService(client: mockClient);
      expect(
        () => service.search('toluene'),
        throwsA(
          isA<PubmedException>().having(
            (e) => e.message,
            'message',
            contains('unreadable response'),
          ),
        ),
      );
    });

    test('five-minute cache prevents duplicate HTTP requests for identical query', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (request.url.path.contains('esearch.fcgi')) {
          return http.Response(
            jsonEncode({
              'esearchresult': {
                'idlist': ['99999999'],
              },
            }),
            200,
          );
        } else if (request.url.path.contains('esummary.fcgi')) {
          return http.Response(
            jsonEncode({
              'result': {
                'uids': ['99999999'],
                '99999999': {
                  'title': 'Cached Study',
                  'authors': [],
                  'source': 'Nature Chem.',
                  'pubdate': '2024',
                },
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = PubmedService(client: mockClient);

      final hits1 = await service.search('cache test query');
      expect(hits1.length, 1);
      expect(callCount, 2); // 1 search + 1 summary

      // Second identical search should hit in-memory cache without HTTP calls
      final hits2 = await service.search('cache test query');
      expect(hits2.length, 1);
      expect(callCount, 2); // Unchanged!
    });

    test('withAbstract fetches and parses XML abstract text', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('efetch.fcgi')) {
          return http.Response(
            '''
<?xml version="1.0"?>
<PubmedArticleSet>
  <PubmedArticle>
    <MedlineCitation>
      <Article>
        <Abstract>
          <AbstractText Label="BACKGROUND">Transition metal catalysis enables complex couplings.</AbstractText>
          <AbstractText Label="RESULTS">Here we report high enantioselectivity &amp; yields &gt; 95%.</AbstractText>
        </Abstract>
      </Article>
    </MedlineCitation>
  </PubmedArticle>
</PubmedArticleSet>
''',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = PubmedService(client: mockClient);
      const hit = PubmedHit(
        pmid: '12345678',
        title: 'Transition Metal Catalysis',
      );

      final hitWithAbstract = await service.withAbstract(hit);
      expect(hitWithAbstract.abstractText, isNotNull);
      expect(
        hitWithAbstract.abstractText,
        contains('Transition metal catalysis enables complex couplings.'),
      );
      expect(
        hitWithAbstract.abstractText,
        contains('enantioselectivity & yields > 95%'),
      );
    });
  });
}

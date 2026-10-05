import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/config/api_endpoints.dart';

void main() {
  group('ApiEndpoints.forModel', () {
    test('debug uses 127.0.0.1 dev servers per model', () {
      expect(ApiEndpoints.forModel('tx1-fastapi', debug: true),
          'http://127.0.0.1:8005');
      expect(ApiEndpoints.forModel('MACE-MP-0', debug: true),
          'http://127.0.0.1:8001');
      expect(ApiEndpoints.forModel('GFN2-xTB', debug: true),
          'http://127.0.0.1:8004');
    });

    test('release never returns a loopback or plain-http URL', () {
      for (final model in ['tx1-fastapi', 'MACE-MP-0', 'CHGNet', 'ANI-2x']) {
        final url = ApiEndpoints.forModel(model, debug: false);
        expect(url, startsWith('https://'));
        expect(ApiEndpoints.isLoopback(url), isFalse);
      }
    });

    test('release drops a loopback override and falls back to production', () {
      final url = ApiEndpoints.forModel('tx1-fastapi',
          userOverride: 'http://localhost:8005', debug: false);
      expect(url, ApiEndpoints.sanitize(ApiEndpoints.productionBaseUrl,
          debug: false));
    });

    test('release upgrades http:// overrides to https://', () {
      expect(
        ApiEndpoints.forModel('tx1-fastapi',
            userOverride: 'http://api.example.com/', debug: false),
        'https://api.example.com',
      );
    });

    test('debug keeps an explicit override as typed (minus trailing slash)', () {
      expect(
        ApiEndpoints.forModel('tx1-fastapi',
            userOverride: 'http://192.168.1.5:9000/', debug: true),
        'http://192.168.1.5:9000',
      );
    });
  });

  group('ApiEndpoints.sanitize / isLoopback', () {
    test('adds https when no scheme is given', () {
      expect(ApiEndpoints.sanitize('api.example.com', debug: false),
          'https://api.example.com');
    });

    test('empty stays empty', () {
      expect(ApiEndpoints.sanitize('  ', debug: false), '');
    });

    test('recognises loopback hosts', () {
      expect(ApiEndpoints.isLoopback('http://localhost:8005'), isTrue);
      expect(ApiEndpoints.isLoopback('http://127.0.0.1:8001'), isTrue);
      expect(ApiEndpoints.isLoopback('https://quantom-forge.web.app'), isFalse);
    });
  });
}

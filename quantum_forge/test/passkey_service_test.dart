import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/services/passkey_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PasskeyService Tests', () {
    test('PasskeyService instance is accessible and supported', () async {
      final supported = await PasskeyService.instance.isPasskeySupported();
      expect(supported, isTrue);
    });

    test('getPlatformInfo returns valid platform metadata', () async {
      final info = await PasskeyService.instance.getPlatformInfo();
      expect(info.platformName, isNotEmpty);
      expect(info.managerName, isNotEmpty);
      expect(info.authenticatorName, isNotEmpty);
      expect(info.iconName, isNotEmpty);
      expect(
        [
          PasskeyPlatform.apple,
          PasskeyPlatform.windows,
          PasskeyPlatform.google,
          PasskeyPlatform.generic,
        ],
        contains(info.platform),
      );
    });

    test('registerPasskey and authenticatePasskey cycle succeeds', () async {
      const testEmail = 'researcher@quantumforge.org';
      const testDisplayName = 'Dr. Curie';

      // 1. Register passkey
      final regResult = await PasskeyService.instance.registerPasskey(
        email: testEmail,
        displayName: testDisplayName,
      );

      expect(regResult.success, isTrue);
      expect(regResult.credentialId, isNotNull);
      expect(regResult.email, equals(testEmail));

      // 2. Query registered passkeys
      final list = await PasskeyService.instance.getRegisteredPasskeys();
      expect(list.any((p) => p.email == testEmail), isTrue);

      // 3. Authenticate with passkey
      final authResult = await PasskeyService.instance.authenticatePasskey(
        email: testEmail,
      );

      expect(authResult.success, isTrue);
      expect(authResult.email, equals(testEmail));
      expect(authResult.cancelled, isFalse);

      // 4. Delete passkey
      if (regResult.credentialId != null) {
        final deleted = await PasskeyService.instance.deletePasskey(regResult.credentialId!);
        expect(deleted, isTrue);
      }
    });

    test('PasskeyCredential serialization and deserialization', () {
      final now = DateTime.now();
      final cred = PasskeyCredential(
        id: 'cred_12345',
        email: 'scientist@institution.edu',
        displayName: 'Lead Scientist',
        createdAt: now,
        platform: PasskeyPlatform.apple,
      );

      final json = cred.toJson();
      expect(json['id'], equals('cred_12345'));
      expect(json['platform'], equals('apple'));

      final reconstructed = PasskeyCredential.fromJson(json);
      expect(reconstructed.id, equals(cred.id));
      expect(reconstructed.email, equals(cred.email));
      expect(reconstructed.platform, equals(PasskeyPlatform.apple));
    });
  });
}

// ============================================================================
// PasskeyService Web Implementation (Native WebAuthn / FIDO2 interop)
// ============================================================================

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

enum PasskeyPlatform {
  apple,
  windows,
  google,
  generic,
}

class PasskeyPlatformInfo {
  final PasskeyPlatform platform;
  final String platformName;
  final String managerName;
  final String authenticatorName;
  final String iconName;

  const PasskeyPlatformInfo({
    required this.platform,
    required this.platformName,
    required this.managerName,
    required this.authenticatorName,
    required this.iconName,
  });
}

class PasskeyCredential {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final PasskeyPlatform platform;

  const PasskeyCredential({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
        'platform': platform.name,
      };

  factory PasskeyCredential.fromJson(Map<String, dynamic> json) {
    return PasskeyCredential(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      platform: PasskeyPlatform.values.firstWhere(
        (p) => p.name == json['platform'],
        orElse: () => PasskeyPlatform.generic,
      ),
    );
  }
}

class PasskeyResult {
  final bool success;
  final String? credentialId;
  final String? email;
  final PasskeyPlatform? platform;
  final String? message;
  final String? error;
  final bool cancelled;

  const PasskeyResult({
    required this.success,
    this.credentialId,
    this.email,
    this.platform,
    this.message,
    this.error,
    this.cancelled = false,
  });
}

@JS('QuantumForgePasskeys')
external JSObject? get _passkeysGlobal;

class PasskeyServiceImplementation {
  bool get _hasInterop => _passkeysGlobal != null;

  Future<bool> isPasskeySupported() async {
    if (!_hasInterop) return false;
    try {
      final res = _passkeysGlobal!.callMethod('isSupported'.toJS);
      return (res as JSBoolean).toDart;
    } catch (e) {
      debugPrint('isPasskeySupported error: $e');
      return false;
    }
  }

  Future<bool> isPlatformAuthenticatorAvailable() async {
    if (!_hasInterop) return false;
    try {
      final promise = _passkeysGlobal!.callMethod('isPlatformAuthenticatorAvailable'.toJS) as JSPromise;
      final res = await promise.toDart;
      return (res as JSBoolean).toDart;
    } catch (e) {
      debugPrint('isPlatformAuthenticatorAvailable error: $e');
      return false;
    }
  }

  Future<PasskeyPlatformInfo> getPlatformInfo() async {
    if (!_hasInterop) {
      return _detectFromUserAgent();
    }
    try {
      final info = _passkeysGlobal!.callMethod('getPlatformInfo'.toJS) as JSObject;
      final id = (info.getProperty('id'.toJS) as JSString).toDart;
      final platformName = (info.getProperty('platformName'.toJS) as JSString).toDart;
      final managerName = (info.getProperty('managerName'.toJS) as JSString).toDart;
      final authenticatorName = (info.getProperty('authenticatorName'.toJS) as JSString).toDart;
      final iconName = (info.getProperty('iconName'.toJS) as JSString).toDart;

      PasskeyPlatform platform;
      switch (id) {
        case 'apple':
          platform = PasskeyPlatform.apple;
          break;
        case 'windows':
          platform = PasskeyPlatform.windows;
          break;
        case 'google':
          platform = PasskeyPlatform.google;
          break;
        default:
          platform = PasskeyPlatform.generic;
      }

      return PasskeyPlatformInfo(
        platform: platform,
        platformName: platformName,
        managerName: managerName,
        authenticatorName: authenticatorName,
        iconName: iconName,
      );
    } catch (e) {
      debugPrint('getPlatformInfo error: $e');
      return _detectFromUserAgent();
    }
  }

  PasskeyPlatformInfo _detectFromUserAgent() {
    final ua = web.window.navigator.userAgent;
    if (ua.contains('Macintosh') || ua.contains('Mac OS X') || ua.contains('iPhone') || ua.contains('iPad')) {
      return const PasskeyPlatformInfo(
        platform: PasskeyPlatform.apple,
        platformName: 'macOS / iOS',
        managerName: 'Apple Password Manager & iCloud Keychain',
        authenticatorName: 'Touch ID / Apple Passkey',
        iconName: 'fingerprint',
      );
    } else if (ua.contains('Windows')) {
      return const PasskeyPlatformInfo(
        platform: PasskeyPlatform.windows,
        platformName: 'Windows',
        managerName: 'Windows Credential Manager',
        authenticatorName: 'Windows Hello / Windows Passkey',
        iconName: 'shield',
      );
    } else if (ua.contains('Chrome') && !ua.contains('Edg')) {
      return const PasskeyPlatformInfo(
        platform: PasskeyPlatform.google,
        platformName: 'Google Chrome',
        managerName: 'Google Password Manager',
        authenticatorName: 'Google Password Manager Passkey',
        iconName: 'key',
      );
    }
    return const PasskeyPlatformInfo(
      platform: PasskeyPlatform.generic,
      platformName: 'WebAuthn',
      managerName: 'Device Password Manager',
      authenticatorName: 'Passkey Authenticator',
      iconName: 'key',
    );
  }

  Future<PasskeyResult> createPasskey({
    required String email,
    String? displayName,
  }) async {
    if (!_hasInterop) {
      return const PasskeyResult(
        success: false,
        error: 'WebAuthn passkey engine not initialized in browser.',
      );
    }
    try {
      final promise = _passkeysGlobal!.callMethod(
        'createPasskey'.toJS,
        email.toJS,
        (displayName ?? email.split('@').first).toJS,
      ) as JSPromise;
      final res = await promise.toDart as JSObject;

      final success = (res.getProperty('success'.toJS) as JSBoolean).toDart;
      if (!success) {
        final err = res.getProperty('error'.toJS);
        final errName = res.getProperty('errorName'.toJS);
        final errStr = err != null ? (err as JSString).toDart : 'Passkey registration cancelled.';
        final isCancel = errName != null && (errName as JSString).toDart == 'NotAllowedError';
        return PasskeyResult(
          success: false,
          error: errStr,
          cancelled: isCancel,
        );
      }

      final credId = (res.getProperty('credentialId'.toJS) as JSString).toDart;
      final platformStr = (res.getProperty('platform'.toJS) as JSString).toDart;
      final msg = (res.getProperty('message'.toJS) as JSString).toDart;

      final platform = PasskeyPlatform.values.firstWhere(
        (p) => p.name == platformStr,
        orElse: () => PasskeyPlatform.generic,
      );

      return PasskeyResult(
        success: true,
        credentialId: credId,
        email: email,
        platform: platform,
        message: msg,
      );
    } catch (e) {
      debugPrint('createPasskey error: $e');
      return PasskeyResult(
        success: false,
        error: 'Passkey registration failed: $e',
      );
    }
  }

  Future<PasskeyResult> authenticatePasskey({String? email}) async {
    if (!_hasInterop) {
      return const PasskeyResult(
        success: false,
        error: 'WebAuthn passkey engine not initialized in browser.',
      );
    }
    try {
      final JSAny? emailArg = email?.toJS;
      final promise = _passkeysGlobal!.callMethod(
        'authenticatePasskey'.toJS,
        emailArg,
      ) as JSPromise;
      final res = await promise.toDart as JSObject;

      final success = (res.getProperty('success'.toJS) as JSBoolean).toDart;
      if (!success) {
        final err = res.getProperty('error'.toJS);
        final errName = res.getProperty('errorName'.toJS);
        final errStr = err != null ? (err as JSString).toDart : 'Authentication was cancelled.';
        final isCancel = errName != null && (errName as JSString).toDart == 'NotAllowedError';
        return PasskeyResult(
          success: false,
          error: errStr,
          cancelled: isCancel,
        );
      }

      final credId = (res.getProperty('credentialId'.toJS) as JSString).toDart;
      final matchedEmail = (res.getProperty('email'.toJS) as JSString).toDart;
      final platformStr = (res.getProperty('platform'.toJS) as JSString).toDart;
      final msg = (res.getProperty('message'.toJS) as JSString).toDart;

      final platform = PasskeyPlatform.values.firstWhere(
        (p) => p.name == platformStr,
        orElse: () => PasskeyPlatform.generic,
      );

      return PasskeyResult(
        success: true,
        credentialId: credId,
        email: matchedEmail,
        platform: platform,
        message: msg,
      );
    } catch (e) {
      debugPrint('authenticatePasskey error: $e');
      return PasskeyResult(
        success: false,
        error: 'Passkey authentication failed: $e',
      );
    }
  }

  Future<List<PasskeyCredential>> getRegisteredPasskeys() async {
    if (!_hasInterop) return [];
    try {
      final array = _passkeysGlobal!.callMethod('listPasskeys'.toJS) as JSArray;
      final list = <PasskeyCredential>[];
      final len = array.length;
      for (int i = 0; i < len; i++) {
        final item = array[i] as JSObject;
        final id = (item.getProperty('id'.toJS) as JSString).toDart;
        final email = (item.getProperty('email'.toJS) as JSString).toDart;
        final displayName = (item.getProperty('displayName'.toJS) as JSString).toDart;
        final createdAtStr = (item.getProperty('createdAt'.toJS) as JSString).toDart;
        final platformStr = (item.getProperty('platform'.toJS) as JSString).toDart;

        list.add(
          PasskeyCredential(
            id: id,
            email: email,
            displayName: displayName,
            createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
            platform: PasskeyPlatform.values.firstWhere(
              (p) => p.name == platformStr,
              orElse: () => PasskeyPlatform.generic,
            ),
          ),
        );
      }
      return list;
    } catch (e) {
      debugPrint('getRegisteredPasskeys error: $e');
      return [];
    }
  }

  Future<bool> deletePasskey(String credentialId) async {
    if (!_hasInterop) return false;
    try {
      final res = _passkeysGlobal!.callMethod('deletePasskey'.toJS, credentialId.toJS);
      return (res as JSBoolean).toDart;
    } catch (e) {
      debugPrint('deletePasskey error: $e');
      return false;
    }
  }
}

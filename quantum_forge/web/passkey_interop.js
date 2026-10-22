// ============================================================================
// Quantum Forge WebAuthn & Passkey Interop
// Provides native FIDO2 / WebAuthn passkey registration & authentication
// for Apple iCloud Keychain / Touch ID (macOS/iOS), Windows Hello (Windows),
// and Google Password Manager (Chrome / Android).
// ============================================================================

(function () {
  'use strict';

  function bufferToBase64(buffer) {
    var binary = '';
    var bytes = new Uint8Array(buffer);
    for (var i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return window.btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  }

  function base64ToBuffer(base64) {
    var str = base64.replace(/-/g, '+').replace(/_/g, '/');
    while (str.length % 4) {
      str += '=';
    }
    var binary = window.atob(str);
    var bytes = new Uint8Array(binary.length);
    for (var i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
  }

  function getRandomBytes(len) {
    var bytes = new Uint8Array(len);
    window.crypto.getRandomValues(bytes);
    return bytes;
  }

  var QuantumForgePasskeys = {
    // 1. Check if Passkeys / WebAuthn is supported in this browser
    isSupported: function () {
      return !!(
        window.PublicKeyCredential &&
        navigator.credentials &&
        navigator.credentials.create &&
        navigator.credentials.get
      );
    },

    // 2. Check if a platform authenticator (Apple Touch ID, Windows Hello, etc.) is available
    isPlatformAuthenticatorAvailable: async function () {
      if (!this.isSupported()) return false;
      try {
        if (typeof window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable === 'function') {
          return await window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
        }
        return true;
      } catch (e) {
        console.warn('Error probing platform authenticator:', e);
        return false;
      }
    },

    // 3. Detect current platform (Apple, Windows, Google/Chrome, Generic)
    getPlatformInfo: function () {
      var ua = navigator.userAgent || '';
      var platform = navigator.platform || '';
      var isMac = /Macintosh|MacIntel|iPad|iPhone|iPod/.test(platform) || /Mac OS X/.test(ua);
      var isWindows = /Win32|Win64|Windows|WinCE/.test(platform) || /Windows NT/.test(ua);
      var isChrome = /Chrome/.test(ua) && !/Edg/.test(ua);

      if (isMac) {
        return {
          id: 'apple',
          platformName: 'macOS / iOS',
          managerName: 'Apple Password Manager & iCloud Keychain',
          authenticatorName: 'Touch ID / Apple Passkey',
          iconName: 'fingerprint'
        };
      } else if (isWindows) {
        return {
          id: 'windows',
          platformName: 'Windows',
          managerName: 'Windows Credential Manager',
          authenticatorName: 'Windows Hello / Windows Passkey',
          iconName: 'shield'
        };
      } else if (isChrome) {
        return {
          id: 'google',
          platformName: 'Google Chrome',
          managerName: 'Google Password Manager',
          authenticatorName: 'Google Password Manager Passkey',
          iconName: 'key'
        };
      }

      return {
        id: 'generic',
        platformName: 'WebAuthn',
        managerName: 'Device Password Manager',
        authenticatorName: 'Device Passkey',
        iconName: 'key'
      };
    },

    // 4. Register a new Passkey with the platform authenticator (Apple Keychain, Windows Hello, Google Password Manager)
    createPasskey: async function (email, displayName) {
      if (!this.isSupported()) {
        return {
          success: false,
          error: 'WebAuthn / Passkeys is not supported by your current browser environment.'
        };
      }

      try {
        var challengeBytes = getRandomBytes(32);
        var encoder = new TextEncoder();
        var userIdBytes = encoder.encode(email);
        var host = window.location.hostname || 'localhost';

        var makeCredentialOptions = {
          publicKey: {
            challenge: challengeBytes,
            rp: {
              name: 'Quantum Forge Workstation',
              id: host === 'localhost' ? undefined : host
            },
            user: {
              id: userIdBytes,
              name: email,
              displayName: displayName || email.split('@')[0] || 'Researcher'
            },
            pubKeyCredParams: [
              { type: 'public-key', alg: -7 },   // ES256 (standard for Apple & Google)
              { type: 'public-key', alg: -257 }  // RS256 (standard for Windows Hello)
            ],
            authenticatorSelection: {
              authenticatorAttachment: 'platform', // Triggers Touch ID on Mac, Windows Hello on Windows, Google on Chrome
              userVerification: 'preferred',
              residentKey: 'preferred',
              requireResidentKey: false
            },
            timeout: 60000,
            attestation: 'none'
          }
        };

        var credential = await navigator.credentials.create(makeCredentialOptions);
        if (!credential) {
          return { success: false, error: 'Passkey creation failed: No credential returned.' };
        }

        var credId = credential.id || bufferToBase64(credential.rawId);

        // Store credential registration in local storage
        var existing = [];
        try {
          var raw = localStorage.getItem('quantum_forge_passkeys');
          if (raw) existing = JSON.parse(raw);
        } catch (_) {}

        var passkeyRecord = {
          id: credId,
          email: email,
          displayName: displayName || email.split('@')[0],
          createdAt: new Date().toISOString(),
          platform: this.getPlatformInfo().id
        };

        // Avoid duplicates
        existing = existing.filter(function (p) { return p.id !== credId; });
        existing.push(passkeyRecord);
        localStorage.setItem('quantum_forge_passkeys', JSON.stringify(existing));

        return {
          success: true,
          credentialId: credId,
          email: email,
          platform: this.getPlatformInfo().id,
          message: 'Passkey successfully created and stored in ' + this.getPlatformInfo().managerName + '!'
        };
      } catch (err) {
        console.warn('Passkey creation error:', err);
        var msg = err.message || 'Passkey creation failed.';
        if (err.name === 'NotAllowedError') {
          msg = 'Passkey setup was cancelled or timed out by the user.';
        } else if (err.name === 'InvalidStateError') {
          msg = 'A passkey for this account is already registered on this device.';
        }
        return {
          success: false,
          error: msg,
          errorName: err.name
        };
      }
    },

    // 5. Authenticate / Sign In with Passkey (Apple Touch ID, Windows Hello, Google Password Manager)
    authenticatePasskey: async function (emailHint) {
      if (!this.isSupported()) {
        return {
          success: false,
          error: 'Passkeys are not supported in this browser.'
        };
      }

      try {
        var challengeBytes = getRandomBytes(32);
        var host = window.location.hostname || 'localhost';

        // Check if we have registered passkeys locally
        var registered = [];
        try {
          var raw = localStorage.getItem('quantum_forge_passkeys');
          if (raw) registered = JSON.parse(raw);
        } catch (_) {}

        var allowCredentials = [];
        if (emailHint && registered.length > 0) {
          var matched = registered.filter(function (p) { return p.email === emailHint; });
          for (var i = 0; i < matched.length; i++) {
            allowCredentials.push({
              type: 'public-key',
              id: base64ToBuffer(matched[i].id)
            });
          }
        }

        var getOptions = {
          publicKey: {
            challenge: challengeBytes,
            rpId: host === 'localhost' ? undefined : host,
            userVerification: 'preferred',
            timeout: 60000
          }
        };

        if (allowCredentials.length > 0) {
          getOptions.publicKey.allowCredentials = allowCredentials;
        }

        var assertion = await navigator.credentials.get(getOptions);
        if (!assertion) {
          return { success: false, error: 'Passkey verification failed: No assertion returned.' };
        }

        var credId = assertion.id || bufferToBase64(assertion.rawId);

        // Find associated email from local registered list or assertion
        var matchedEmail = emailHint;
        for (var j = 0; j < registered.length; j++) {
          if (registered[j].id === credId) {
            matchedEmail = registered[j].email;
            break;
          }
        }

        if (!matchedEmail && registered.length === 1) {
          matchedEmail = registered[0].email;
        }

        return {
          success: true,
          credentialId: credId,
          email: matchedEmail || 'passkey-researcher@quantumforge.internal',
          platform: this.getPlatformInfo().id,
          message: 'Passkey verified via ' + this.getPlatformInfo().authenticatorName
        };
      } catch (err) {
        console.warn('Passkey authentication error:', err);
        var msg = err.message || 'Passkey verification failed.';
        if (err.name === 'NotAllowedError') {
          msg = 'Passkey authentication was cancelled or biometric prompt was dismissed.';
        }
        return {
          success: false,
          error: msg,
          errorName: err.name
        };
      }
    },

    // 6. List locally saved passkeys
    listPasskeys: function () {
      try {
        var raw = localStorage.getItem('quantum_forge_passkeys');
        return raw ? JSON.parse(raw) : [];
      } catch (_) {
        return [];
      }
    },

    // 7. Delete a passkey
    deletePasskey: function (credentialId) {
      try {
        var list = this.listPasskeys();
        list = list.filter(function (p) { return p.id !== credentialId; });
        localStorage.setItem('quantum_forge_passkeys', JSON.stringify(list));
        return true;
      } catch (_) {
        return false;
      }
    }
  };

  window.QuantumForgePasskeys = QuantumForgePasskeys;
})();

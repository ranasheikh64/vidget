import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class VaultAuthService extends GetxService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  static const String _pinKey = 'vault_pin';
  static const String _encryptionKey = 'vault_aes_key';

  final isVaultSetup = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkSetupStatus();
  }

  Future<void> checkSetupStatus() async {
    final pin = await _storage.read(key: _pinKey);
    isVaultSetup.value = pin != null;
  }

  Future<bool> setPin(String pin) async {
    try {
      await _storage.write(key: _pinKey, value: pin);
      isVaultSetup.value = true;
      return true;
    } catch (e) {
      print("[VaultAuth] Error setting PIN: $e");
      return false;
    }
  }

  Future<String?> getEncryptionKey() async {
    String? key = await _storage.read(key: _encryptionKey);
    if (key == null) {
      key = _generateRandomString(32);
      await _storage.write(key: _encryptionKey, value: key);
    }
    return key;
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    return List.generate(length, (index) => chars[DateTime.now().millisecond % chars.length]).join();
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = await _storage.read(key: _pinKey);
    return savedPin == pin;
  }

  Future<bool> authenticateBiometrically() async {
    try {
      print("[VaultAuth] Attempting base authentication...");
      
      final bool canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        print("[VaultAuth] Device does not support biometrics.");
        return false;
      }

      // Minimalist call to avoid all 'AuthenticationOptions' / class missing errors
      final bool result = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to open your Private Vault',
      );

      print("[VaultAuth] Authentication Result: $result");
      return result;
    } on PlatformException catch (e) {
      print("[VaultAuth] Platform Error: ${e.code} - ${e.message}");
      return false;
    } catch (e) {
      print("[VaultAuth] General Error: $e");
      return false;
    }
  }

  Future<void> resetVault() async {
    await _storage.delete(key: _pinKey);
    isVaultSetup.value = false;
  }
}

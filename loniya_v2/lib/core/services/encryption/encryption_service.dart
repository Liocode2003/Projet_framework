/// Interface contract for encryption services.
abstract class EncryptionService {
  Future<void> init();
  String encrypt(String plaintext);
  String decrypt(String ciphertext);
  String hashPin(String pin);
  bool verifyPin(String pin, String storedHash);
  List<int> get hiveEncryptionKey;
}

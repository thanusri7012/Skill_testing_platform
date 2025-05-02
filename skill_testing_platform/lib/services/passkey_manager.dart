class PasskeyManager {
  static final PasskeyManager _instance = PasskeyManager._internal();
  factory PasskeyManager() => _instance;
  PasskeyManager._internal();

  bool _passkeyUsed = false;
  final String _correctPasskey = "12345";

  bool get passkeyUsed => _passkeyUsed;
  String get correctPasskey => _correctPasskey;

  void markPasskeyUsed() {
    _passkeyUsed = true;
  }

  void resetPasskey() {
    _passkeyUsed = false;
  }
}
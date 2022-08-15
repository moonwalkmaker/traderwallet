import 'dart:async';
import 'package:app/config.dart';
import 'package:app/services/wallet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/credentials.dart';

class UserData {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String walletPublicKey = '', walletPrivateKey = '', publicAddress = '', seedPhrase = '';
  late WalletService walletService;

  UserData(bool autoGenerateWallet) {
    loadUserData(autoGenerateWallet);
  }

  void setUserDefaults(String walletPublicKey, String walletPrivateKey,
                       String publicAddress, String seedPhrase) async {
    if (!(walletPublicKey.isEmpty || walletPrivateKey.isEmpty ||
        publicAddress.isEmpty || seedPhrase.isEmpty)) {
      final SharedPreferences prefs = await _prefs;
      prefs.setString('walletPublicKey', walletPublicKey);
      prefs.setString('walletPrivateKey', walletPrivateKey);
      prefs.setString('publicAddress', publicAddress);
      prefs.setString('seedPhrase', seedPhrase);
      bool autoGenerateWallet = false;
      loadUserDefaults(autoGenerateWallet);
    }
  }

  void loadUserData(bool autoGenerateWallet) {
    walletService = WalletService();

    // TODO load from Cloud if NULL loads from local
    loadUserDefaults(autoGenerateWallet);

  }

  void loadUserDefaults(bool autoGenerateWallet) async {
    final SharedPreferences prefs = await _prefs;
    walletPublicKey = prefs.getString('walletPublicKey') ?? '';
    walletPrivateKey = prefs.getString('walletPrivateKey') ?? '';
    publicAddress = prefs.getString('publicAddress') ?? Config.noWalletStr;
    seedPhrase = prefs.getString('seedPhrase') ?? Config.noSeedPhraseStr;

    if(autoGenerateWallet == true &&
        (walletPublicKey.isEmpty || walletPrivateKey.isEmpty ||
            publicAddress.isEmpty || seedPhrase.isEmpty)
    ) {
      createWallet();
    }
  }

  void loadWallet(String seedPhrase) async {
    final privateKey = await walletService.getPrivateKey(seedPhrase);
    final publicKey = await walletService.getPublicKey(privateKey);
    walletPrivateKey = privateKey;
    walletPublicKey = publicKey.toString();
    publicAddress = publicKey.toString();
    setUserDefaults(walletPublicKey, walletPrivateKey, publicAddress, seedPhrase);
  }

  void createWallet() async {
    seedPhrase = walletService.generateMnemonic();
    final privateKey = await walletService.getPrivateKey(seedPhrase);
    final publicKey = await walletService.getPublicKey(privateKey);
    walletPrivateKey = privateKey;
    walletPublicKey = publicKey.toString();
    publicAddress = publicKey.toString();
    setUserDefaults(walletPublicKey, walletPrivateKey, publicAddress, seedPhrase);
  }

  Credentials getCredentials() {
    return walletService.getCredentials(walletPrivateKey);
  }

  Future<num> getBalance() async {
    return await walletService.getBalance(walletPrivateKey);
  }

  Future<num> getSmartContractBalance() async {
    return await walletService.getBalance(walletPrivateKey);
  }

}
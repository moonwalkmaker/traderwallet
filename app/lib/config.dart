import 'dart:io';
import 'dart:convert';
import 'dart:async' show Future;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web3dart/web3dart.dart';
import 'package:path/path.dart' show join, dirname;

class Config {
  static const String appTitle = 'Trader Wallet';
  static const String rinkebyUrl = 'https://rinkeby.infura.io/v3/208dc164656e4276967971e6614a44d0';
  static const String rinkebySocketUrl = 'wss://rinkeby.infura.io/v3/208dc164656e4276967971e6614a44d0';
  static const int rinkebyChainId = 4;
  static const int ethereumChainId = rinkebyChainId;
  static const String ethereumUrl = rinkebyUrl;
  static const String ethereumSocketUrl = rinkebySocketUrl;
  static const String noWalletStr = 'No wallet yet';
  static const String noSeedPhraseStr = 'No seed wallet yet';

  static EthereumAddress usdmAddress() {
    // ???? 0xB526D34ba883F6FA79cB5bEa800CF71E1dEc660d
    // v0.0.8 = 0x311F0e3D49A9577845DC155F2Ca5f891B90c5e64 (not validating)
    // v0.0.5 = 0x9DBf67aF5d769862e4F2f8696529007F1b129ACc (working correctly)
    return EthereumAddress.fromHex('0x9DBf67aF5d769862e4F2f8696529007F1b129ACc');
  }

  static Future<String> abiUsdm() async {
    final data = await rootBundle.loadString('assets/references/usdm/MintDollar-abi.json');
    return data;
  }
}
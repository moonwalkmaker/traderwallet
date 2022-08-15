import 'package:app/config.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:hex/hex.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class EthNetwork {
  static const rinkeby = 4;
}

class TransactionDTO {
  late EthereumAddress fromAddress;
  late EthereumAddress toAddress;
  late String privateKey;
  late EtherUnit unit;
  late BigInt amount;
  final _wei = EtherAmount.fromUnitAndValue(EtherUnit.ether, 1).getInWei.toDouble();

  TransactionDTO(this.privateKey, String fromAddress,
                 String toAddress, String amount) {

    // convert string formatted number to EtherUnits
    this.amount = BigInt.from(double.parse(amount) * _wei);
    unit = EtherUnit.wei;

    // Convert strings into addresses
    this.fromAddress = EthereumAddress.fromHex(fromAddress);
    this.toAddress = EthereumAddress.fromHex(toAddress);

  }
}

abstract class WalletAddressService {
  String generateMnemonic();
  EthPrivateKey getCredentials(String privateKey);
  Future<num> getBalance(String privateKey);
  Future<String> getPrivateKey(String mnemonic);
  Future<EthereumAddress> getPublicKey(String privateKey);
  Future<Transaction> prepareTransaction(TransactionDTO transaction);
  void sendEther(TransactionDTO transactionDTO);
  // Future<List<dynamic>> query(String functionName, List<dynamic> args);
}

class WalletService implements WalletAddressService {

  final Client _httpClient = Client();
  late Web3Client _ethClient;

  WalletService() {
    _ethClient = Web3Client(Config.ethereumUrl, _httpClient);
  }

  @override
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  @override
  Future<String> getPrivateKey(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final master = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
    final privateKey = HEX.encode(master.key);
    return privateKey;
  }

  @override
  Future<EthereumAddress> getPublicKey(String privateKey) async {
    final privateHex = EthPrivateKey.fromHex(privateKey);
    final address = await privateHex.extractAddress();
    return address;
  }

  @override
  Future<num> getBalance(String privateKey) async {
    if(privateKey.isEmpty) return 0;
    final credentials = EthPrivateKey.fromHex(privateKey);
    EtherAmount balance = await _ethClient.getBalance(credentials.address);
    return balance.getValueInUnit(EtherUnit.ether);
  }

  @override
  EthPrivateKey getCredentials(String privateKey) {
    return EthPrivateKey.fromHex(privateKey);
  }

  @override
  Future<Transaction> prepareTransaction(TransactionDTO transaction) async {
    EthereumAddress sender = transaction.fromAddress;
    EthereumAddress receiver = transaction.toAddress;
    EtherAmount etherAmount = EtherAmount.fromUnitAndValue(transaction.unit, transaction.amount);
    return Transaction(from: sender, to: receiver, value: etherAmount);
  }

  @override
  void sendEther(TransactionDTO transactionDTO) async {
    Credentials credentials = getCredentials(transactionDTO.privateKey);
    Transaction transaction = await prepareTransaction(transactionDTO);
    _ethClient.sendTransaction(credentials, transaction, chainId: EthNetwork.rinkeby);
  }

  String validatePublicAddress(String address) {
    try {
      EthereumAddress.fromHex(address);
      return '';
    } catch (e) {
      return e.toString();
    }
  }

}
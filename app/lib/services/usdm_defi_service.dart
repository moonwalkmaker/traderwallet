import 'dart:ffi';
import 'dart:io';
import 'package:app/models/user_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:app/config.dart';
import 'package:web3dart/web3dart.dart';

class USDMDeFiCollateral {
  BigInt lockedCollateral, remainingCollateral, vaultDebt, liquidationPrice;
  USDMDeFiCollateral(this.lockedCollateral, this.remainingCollateral,
                      this.vaultDebt, this.liquidationPrice);
}

class USDMDeFiService {

  // Integration
  String rpcUrl = Config.ethereumUrl;
  String wsUrl = Config.ethereumSocketUrl;
  late Client httpClient;
  late Web3Client web3Client;
  late UserData _userWalletData;

  // Contract data
  final EthereumAddress contractAddress = Config.usdmAddress();
  late File abiFile;
  late String abiCode;
  late DeployedContract contract;

  // Contract events & functions
  late ContractEvent transferEvent;
  late ContractFunction balanceFunction, calcProvidedRatioFunction,
                        estimateLiquidationPriceFunction, getETHUSDFunction,
                        getCollateralsEthOfFunction, estimateMaxMintableStable,
                        collateralizeFunction;

  USDMDeFiService() {
    httpClient = Client();
    web3Client = Web3Client(rpcUrl, httpClient);
    const autoGenerateWallet = false;
    _userWalletData = UserData(autoGenerateWallet);
    setupContract();
  }

  void setupContract() async {
    abiCode = await Config.abiUsdm();
    contract = DeployedContract(ContractAbi.fromJson(abiCode, 'USDM'), contractAddress);

    // extracting functions and events
    transferEvent = contract.event('Transfer');
    balanceFunction = contract.function('balanceOf');
    calcProvidedRatioFunction = contract.function('calcProvidedRatio');
    estimateLiquidationPriceFunction = contract.function('estimateLiquidationPrice');
    getCollateralsEthOfFunction = contract.function('getCollateralsEthOf');
    getETHUSDFunction = contract.function('getETHUSD');
    estimateMaxMintableStable = contract.function('estimateMaxMintableStable');
    collateralizeFunction = contract.function('collaterallize'); // collaterallize (v0.5), collateralize (+v0.7) 
  }

  void subscribeTransferEvent() {
    // listen for the Transfer event when it's emitted by the contract above
    final subscription = web3Client
        .events(FilterOptions.events(contract: contract, event: transferEvent))
        .take(1)
        .listen((event) {
          final decoded = transferEvent
                          .decodeResults(event.topics as List<String>,
                                         event.data as String);

          final from = decoded[0] as EthereumAddress;
          final to = decoded[1] as EthereumAddress;
          final value = decoded[2] as BigInt;
          debugPrint('$from sent $value Coin to $to');
    });
  }

  Future<List> getBalance() {
    final userWalletAddress = EthereumAddress.fromHex(_userWalletData.publicAddress);
    return web3Client.call(
        contract: contract,
        function: balanceFunction,
        params: [userWalletAddress]
    );
  }

  Future<List> getPositions() {
    final userWalletAddress = EthereumAddress.fromHex(_userWalletData.publicAddress);
    return web3Client.call(
        contract: contract,
        function: getCollateralsEthOfFunction,
        params: [userWalletAddress]
    );
  }

  Future<BigInt> maxMintableStable(BigInt lockedCollateral, BigInt globalPrice) async {
    final resp = await web3Client.call(
        contract: contract,
        function: estimateMaxMintableStable,
        params: [lockedCollateral, globalPrice]
    );

    return (resp[0] as BigInt);
  }

  // vaultDebt = how much generated stable coins
  Future<BigInt> providedRatio(BigInt collateral, BigInt globalPrice, BigInt vaultDebt) async {
    final zero = BigInt.from(0);

    if(collateral == zero || vaultDebt == zero) {
      return zero;
    }

    final resp = await web3Client.call(
        contract: contract,
        function: calcProvidedRatioFunction,
        params: [collateral, globalPrice, vaultDebt]
    );

    return (resp[0] as BigInt);
  }

  Future<BigInt> liquidationPrice(BigInt vaultDebt, BigInt currentPrice, BigInt collateralUSD) async {
    final resp = await web3Client.call(
        contract: contract,
        function: estimateLiquidationPriceFunction,
        params: [vaultDebt, currentPrice, collateralUSD]
    );

    return (resp[0] as BigInt);
  }

  Future<BigInt> getPriceETHUSD(BigInt amount) async {
    final resp = await web3Client.call(
        contract: contract,
        function: getETHUSDFunction,
        params: [amount]
    );

    return (resp[2] as BigInt);
  }

  Future<String> openCollateralPosition(EthereumAddress sender, EtherAmount collateralETH,
                                        BigInt vaultDebt, EtherAmount maxGasFee,
                                        Credentials credentials, int chainId) async {

    final transaction = Transaction.callContract(from: sender, contract: contract,
                                                  function: collateralizeFunction,
                                                  parameters: [vaultDebt],
                                                  value: collateralETH);

    return web3Client.sendTransaction(credentials, transaction, chainId: chainId);

  }

  Future<BigInt> estimateGasFee({EthereumAddress? sender, EthereumAddress? to, required List<dynamic> params,
                                EtherAmount? collateral, ContractFunction? contractFunction }) async {

    // 1 GAS = 1 Gwei = 0,000000001
    // BlockInformation blockInfo = await web3Client.getBlockInformation(blockNumber: 'latest', isContainFullObj: true);
    // EtherAmount lastGasFee = blockInfo.baseFeePerGas!;

    try {
      final transaction = Transaction.callContract(from: sender, contract: contract,
                                                    function: contractFunction!, parameters: params, value: collateral);
      return await web3Client.estimateGas(sender: sender, to: transaction.to, value: transaction.value, data: transaction.data);
    } on Exception catch (_) {
      throw Exception(_);
    }

  }

  double formatStable(BigInt amount) {
    return amount.toDouble() / 100;
  }

  double parseBalance(List result) {
    return formatStable(result[0]);
  }

  List<USDMDeFiCollateral> parseCollateral(List result) {
    List<USDMDeFiCollateral> collaterals = [];
    final resp = result[0];
    for (var element in resp) {
      final lockedCollateral = element[0];
      final remainingCollateral = element[1];
      final vaultDebt = element[2];
      final liquidationPrice = element[3];
      collaterals.add(USDMDeFiCollateral(lockedCollateral, remainingCollateral, vaultDebt, liquidationPrice));
    }

    return collaterals;
  }



}
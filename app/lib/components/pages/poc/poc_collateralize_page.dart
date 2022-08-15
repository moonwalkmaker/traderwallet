import 'dart:math';

import 'package:app/components/widgets/alert.dart';
import 'package:app/config.dart';
import 'package:app/models/user_data.dart';
import 'package:app/services/usdm_defi_service.dart';
import 'package:app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class PocCollateralizePage extends StatefulWidget {
  const PocCollateralizePage({Key? key}) : super(key: key);

  @override
  State<PocCollateralizePage> createState() => _PocCollateralizePageState();
}

class _PocCollateralizePageState extends State<PocCollateralizePage> {

  late Client httpClient;
  late Web3Client ethClient;
  late num _availableToGenerate = 0.00;
  late num _calcCollateralizationRatio = 0.00;
  late num _maxCollateralizationRatio = 0.00;
  late num _maxWithdraw = 0.00;
  late num _remainWithdraw = 0.00;
  late num _calcLiquidationPrice = 0.00;
  late num _maxLiquidationPrice = 0.00;
  late num _balanceAmountEther = 0;
  late num _estimatedGasFee = 0.00;
  late num _expectedStable = 0.00;
  late double _maxStable = 0.00;
  late UserData _userWalletData;
  late USDMDeFiService deFi;
  late String _availableToGenerateStr = '0.00';
  final WalletService _walletService = WalletService();

  final TextEditingController _gasFeeCtrl = TextEditingController();
  final TextEditingController _depositETHCtrl = TextEditingController();
  final TextEditingController _stableToGenerateCtrl = TextEditingController();

  void openCollateral() {
    _expectedStable = double.parse(_stableToGenerateCtrl.text);
    final vaultDebt = BigInt.from(_expectedStable*100);
    BigInt collateral = BigInt.from(double.parse(_depositETHCtrl.text)*pow(10,18));
    EthereumAddress sender = EthereumAddress.fromHex(_userWalletData.publicAddress);
    EtherAmount providedCollateral = EtherAmount.inWei(collateral);
    EtherAmount maxGasFee = EtherAmount.inWei(BigInt.from(_estimatedGasFee * pow(10,18)));
    Credentials credentials = _userWalletData.getCredentials();
    const chainId = Config.ethereumChainId;
    Future<String> resp = deFi.openCollateralPosition(sender, providedCollateral, vaultDebt, maxGasFee, credentials, chainId);
    resp.then((result){
      Alert.show(context, "Transaction created", <Widget>[Text("Your request was registered on the transaction: $result")]);
    }).catchError((handleError) {
      Alert.show(context, "Contract returned an exception", <Widget>[Text(handleError.toString())]);
    });
  }

  void updateCollateralLessFess() {
    setState(() {
      if(_gasFeeCtrl.text.isNotEmpty && _depositETHCtrl.text.isNotEmpty) {
        final gasFee = double.parse(_gasFeeCtrl.text);
        final collateral = double.parse(_depositETHCtrl.text);
        _depositETHCtrl.text = (collateral - gasFee).toString();
        setupMaxMint(double.parse(_depositETHCtrl.text));
      }
    });
  }

  void calcWithdraw() {
    if(_depositETHCtrl.text.isNotEmpty) {
      _maxWithdraw = double.parse(_depositETHCtrl.text);
      if(_stableToGenerateCtrl.text.isNotEmpty) {
        final vaultDebt = double.parse(_stableToGenerateCtrl.text);
        final collateral = BigInt.from(_maxWithdraw * pow(10,18));
        deFi.getPriceETHUSD(collateral).then((collateralUSD) {
          final collateralUSDF = (collateralUSD).toDouble() / 100;
          final availableWithdraw = collateralUSDF - (vaultDebt*1.7);
          final ratio = availableWithdraw/collateralUSDF;
          _remainWithdraw = _maxWithdraw * ratio;
        });
      }
    }
  }

  void setupRatios() {
    setState(() {

      calcWithdraw();
      _expectedStable = double.parse(_stableToGenerateCtrl.text);
      _availableToGenerate = _maxStable - _expectedStable;
      _availableToGenerateStr = _availableToGenerate.toStringAsFixed(2);
      BigInt defaultGlobalPrice = BigInt.from(0);

      if(_depositETHCtrl.text.isEmpty) return;
      final collateral = BigInt.from(double.parse(_depositETHCtrl.text) * pow(10,18));

      Future<BigInt> providedRatio = deFi.providedRatio(collateral, defaultGlobalPrice, BigInt.from(_expectedStable*100));
      providedRatio.then((result){
        setState(() {
          _calcCollateralizationRatio = ((result).toDouble() / 100);
        });
      });

      Future<BigInt> priceETHUSD = deFi.getPriceETHUSD(collateral);
      priceETHUSD.then((collateralUSD) {
        final vaultDebt = BigInt.from(_expectedStable*100);
        Future<BigInt> liquidationPrice = deFi.liquidationPrice(vaultDebt, defaultGlobalPrice, collateralUSD);
        liquidationPrice.then((result) {
          setState(() {
            _calcLiquidationPrice = ((result).toDouble() / 100);
          });
        });
      });

      EthereumAddress to = deFi.contractAddress;
      EthereumAddress sender = EthereumAddress.fromHex(_userWalletData.publicAddress);
      EtherAmount providedCollateral = EtherAmount.inWei(collateral);
      BigInt vaultDebit = BigInt.from(_expectedStable*100);

      deFi.estimateGasFee(sender: sender, to: to, contractFunction: deFi.collateralizeFunction,
          collateral: providedCollateral, params: [vaultDebit]).then((estimatedGasFree) {
        setState(() {
          final estimatedGasInWeis = estimatedGasFree.toDouble() * pow(10,9);
          _estimatedGasFee = estimatedGasInWeis/pow(10,18);
        });
      }).catchError((handleError) {
        Alert.show(context, "Contract returned an exception", <Widget>[Text(handleError.toString())]);
      });

    });
  }

  void setupMaxMint(num collateral) {
    BigInt defaultGlobalPrice = BigInt.from(0);
    BigInt possibleLockedCollateral = BigInt.from(collateral * pow(10,18));

    final maxMintableInt = deFi.maxMintableStable(possibleLockedCollateral, defaultGlobalPrice);
    maxMintableInt.then((result) {
      setState(() {
        _maxStable = deFi.formatStable(result);
        deFi.providedRatio(possibleLockedCollateral, defaultGlobalPrice, BigInt.from(_expectedStable*100));

        Future<BigInt> providedRatio = deFi.providedRatio(possibleLockedCollateral,
                                                          defaultGlobalPrice,
                                                          BigInt.from(_maxStable*100));

        calcWithdraw();

        providedRatio.then((result){
          setState(() {
            _maxCollateralizationRatio = ((result).toDouble() / 100);
          });
        });

        final collateral = BigInt.from(_balanceAmountEther * pow(10,18));
        providedRatio.then((result){
          setState(() {
            _calcCollateralizationRatio = ((result).toDouble() / 100);
          });
        });

        deFi.getPriceETHUSD(collateral).then((collateralUSD) {
          final vaultDebt = BigInt.from(_maxStable*100);
          Future<BigInt> liquidationPrice = deFi.liquidationPrice(vaultDebt, defaultGlobalPrice, collateralUSD);
          liquidationPrice.then((result) {
            setState(() {
              _maxLiquidationPrice = ((result).toDouble() / 100);
            });
          });
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(Config.ethereumUrl, httpClient);
    bool autoGenerateWallet = true;
    _userWalletData = UserData(autoGenerateWallet);
    deFi = USDMDeFiService();
  }

  Future<void> updateBalance() async {
    num amountEther = await _userWalletData.getBalance();
    setState(() {
      _balanceAmountEther = amountEther;
      setupMaxMint(_balanceAmountEther);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    //_gasFree =
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
            reverse: true,
            child: Center(
              child: Column(
                  children: <Widget>[
                    Row(
                      children: [
                        Container(
                          width: screenWidth*0.8,
                          padding: const EdgeInsets.only(left: 20.0, top: 10.0),
                          child:
                          Text(
                            'Balance (ETH): $_balanceAmountEther',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        IconButton(
                          padding: const EdgeInsets.only(top: 10.0),
                          onPressed: (){
                            updateBalance();
                          },
                          icon: const Icon(Icons.refresh),
                          color: Colors.blue,
                        )
                      ],
                    ),
                    // Deposit Ether input
                    TextButton(
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                            padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.only(right: 20.0))
                        ),
                        onPressed: () {
                          _depositETHCtrl.text = '$_balanceAmountEther';
                          setState(() {
                            if(double.tryParse(_depositETHCtrl.text) != null) {
                              setupMaxMint(num.parse(_depositETHCtrl.text));
                            }
                          });
                        },
                        child: const Align(
                          alignment: Alignment.topRight,
                          child: Text('Max ETH balance'),
                        )
                    ),
                    Container(
                        padding: const EdgeInsets.all(20.0),
                        child: TextField(
                          maxLines: null,
                          controller: _depositETHCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (String value) async {
                            setState(() {
                              if(double.tryParse(_depositETHCtrl.text) != null) {
                                setupMaxMint(num.parse(_depositETHCtrl.text));
                              }
                            });
                          },
                          inputFormatters: [
                            // 1*10^18 weis means 1 ether
                            // TODO The supply of ethereum is flexible so need some provide to update it available range
                            FilteringTextInputFormatter.allow(RegExp(r'^[\d+]{0,8}\.?[\d*]{0,18}')),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Deposit ETH (collateral)',
                          ),
                        )
                    ),
                    // Generate USD stable coin
                    TextButton(
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                            padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.only(right: 20.0))
                        ),
                        onPressed: () {
                          _stableToGenerateCtrl.text = '$_maxStable';
                          setState(() {
                            _expectedStable = _maxStable;
                            setupRatios();
                          });
                        },
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text('Max $_maxStable USDM'),
                        )
                    ),
                    Container(
                        padding: const EdgeInsets.all(20.0),
                        child: TextField(
                          maxLines: null,
                          controller: _stableToGenerateCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (String value) async {
                            setState(() {
                              if(double.tryParse(_stableToGenerateCtrl.text) != null) {
                                setupRatios();
                              }
                            });
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^[\d+]{0,10}\.?[\d*]{0,2}')),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Generate USD stable coin',
                          ),
                        )
                    ),
                    // Vault changes title
                    TextButton(
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                            padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.only(top: 35.0, right: 20.0))
                        ),
                        onPressed: () {
                          setState(() {
                            _gasFeeCtrl.text = _estimatedGasFee.toString();
                            updateCollateralLessFess();
                          });
                        },
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text('Estimated gas fee $_estimatedGasFee'),
                        )
                    ),
                    Container(
                        padding: const EdgeInsets.all(20.0),
                        child: TextField(
                          maxLines: null,
                          controller: _gasFeeCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (String value) async {
                            updateCollateralLessFess();
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^[\d+]{0,10}\.?[\d*]{0,18}')),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Consumed gas fee in gweis',
                          ),
                        )
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                          child: Text(
                            'Vault changes',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        )
                      ]
                    ),
                    // Collateral Locked
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                          child: Text(
                            'Collateral Locked (ETH)',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        )
                      ]
                    ),
                    Row(
                      children: [
                        Container(
                          width: screenWidth*0.88,
                          padding: const EdgeInsets.only(right: 25.0, top: 5.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_depositETHCtrl.text} -> $_balanceAmountEther',
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                          )
                        ),
                      ],
                    ),
                    // Collateralization Ratio
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                          child: Text(
                            'Collateralization Ratio',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        Container(
                            width: screenWidth*0.55,
                            padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$_calcCollateralizationRatio% ->  $_maxCollateralizationRatio%',
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                            )
                        ),
                      ],
                    ),
                    // Liquidation Price
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                          child: Text(
                            'Liquidation Price',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        Container(
                            width: screenWidth*0.62,
                            padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '\$$_calcLiquidationPrice ->  \$$_maxLiquidationPrice',
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                            )
                        ),
                      ],
                    ),
                    // Vault USDM Debt
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                          child: Text(
                            'Vault USDM Debt',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        Container(
                            width: screenWidth*0.61,
                            padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$_expectedStable USDM ->  $_maxStable USDM',
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                            )
                        ),
                      ],
                    ),
                    // Available to withdraw
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                          child: Text(
                            'Available to withdraw',
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ),
                        Container(
                            width: screenWidth*0.55,
                            padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$_remainWithdraw ETH ->  $_maxWithdraw ETH',
                                style: Theme.of(context).textTheme.bodyText1,
                              ),
                            )
                        ),
                      ],
                    ),
                    // Available to generate
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                          child: Text(
                            'Available to generate',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        Container(
                            width: screenWidth*0.56,
                            padding: const EdgeInsets.only(left: 15.0, top: 20.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$_availableToGenerateStr USDM ->  $_maxStable USDM',
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                            )
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 25.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      Color(0xFF282A36),
                                      Color(0xFF204799),
                                      Color(0xFF1260CD),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(16.0),
                                primary: Colors.white,
                                textStyle: const TextStyle(fontSize: 20),
                              ),
                              onPressed: () {
                                openCollateral();
                              },
                              icon: const Icon(Icons.star),
                              label: const Text('Open collateral position'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]
              ),
            )
        )
    );
  }

}
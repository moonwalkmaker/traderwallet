import 'package:app/components/widgets/alert.dart';
import 'package:app/config.dart';
import 'package:app/models/user_data.dart';
import 'package:app/services/usdm_defi_service.dart';
import 'package:app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class PocRepayPage extends StatefulWidget {
  const PocRepayPage({Key? key}) : super(key: key);

  @override
  State<PocRepayPage> createState() => _PocRepayPageState();
}

class _PocRepayPageState extends State<PocRepayPage> {
  late num _balanceUSDM = 0.00;
  late USDMDeFiService deFi;
  late Client httpClient;
  late Web3Client ethClient;
  late UserData _userWalletData;
  late List<USDMDeFiCollateral> collaterals;
  final WalletService _walletService = WalletService();
  String _selectedCollateral = "Select a collateral to repay";

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    deFi = USDMDeFiService();
    ethClient = Web3Client(Config.ethereumUrl, httpClient);
    bool autoGenerateWallet = true;
    _userWalletData = UserData(autoGenerateWallet);
  }

  Future<void> reloadData() async {
    deFi.getBalance().then((result){
      setState(() {
        _balanceUSDM = deFi.parseBalance(result);
      });
    }).catchError((handleError) {
      Alert.show(context, "Contract returned an exception", <Widget>[Text(handleError.toString())]);
    });

    deFi.getPositions().then((result){
      setState(() {
        collaterals = deFi.parseCollateral(result);
        // TODO apply new collaterals list to the dropdown button

      });
    }).catchError((handleError) {
      Alert.show(context, "Contract returned an exception", <Widget>[Text(handleError.toString())]);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
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
                          'Balance (USDM): US\$ $_balanceUSDM',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      IconButton(
                        padding: const EdgeInsets.only(top: 10.0),
                        onPressed: (){
                          reloadData();
                        },
                        icon: const Icon(Icons.refresh),
                        color: Colors.blue,
                      )
                    ]
                ),
                Row(
                  children: [
                    Container(
                      width: screenWidth*0.8,
                      padding: const EdgeInsets.only(left: 20.0, top: 10.0),
                      child: DropdownButton<String>(
                          hint: const Text("Select a collateral to repay"),
                          value: _selectedCollateral,
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          style: const TextStyle(color: Colors.deepPurple),
                          underline: Container(
                            height: 2,
                            color: Colors.deepPurpleAccent,
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCollateral = newValue!;
                            });
                          },
                          items: <String>[_selectedCollateral]
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList()
                        )
                    )
                  ],
                )
              ]
          )
        )
      )
    );
  }

}
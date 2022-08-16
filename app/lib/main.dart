import 'package:app/components/pages/poc/poc_bot_page.dart';
import 'package:app/components/pages/poc/poc_ethereum_wallet_page.dart';
import 'package:app/components/pages/poc/poc_scanner_page.dart';
import 'package:app/config.dart';
import 'package:app/models/user_data.dart';
import 'package:app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Config.appTitle,
      debugShowCheckedModeBanner: false, // removes the debug label
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blueGrey,
            bottom: const TabBar(
              tabs: [
                Tab(text: 'TraderWallet', icon: FaIcon(FontAwesomeIcons.wallet)),
                Tab(text: 'Bot', icon: FaIcon(Icons.star)),
                Tab(text: 'Scanner', icon: Icon(Icons.published_with_changes))
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              PocEthereumWalletPage(title: Config.appTitle),
              PocBotPage(),
              PocScannerPage()
            ],
          )
        ),
      )
    );
  }
}

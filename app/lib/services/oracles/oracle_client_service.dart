import 'package:graphql_flutter/graphql_flutter.dart';

class OracleClientService {

  late GraphQLClient compoundClient;
  late GraphQLClient uniSwapClient;
  late GraphQLClient blockClient;
  late GraphQLClient ensClient;

  OracleClientService() {

    // We're using HiveStore for persistence,
    // so we need to initialize Hive.
    initHiveForFlutter();

    compoundClient = GraphQLClient(
      link: HttpLink('https://api.thegraph.com/subgraphs/name/graphprotocol/compound-v2'),
      // The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(store: HiveStore()),
    );

    uniSwapClient = GraphQLClient(
      link: HttpLink('https://api.thegraph.com/subgraphs/name/ianlapham/uniswapv2'),
      // The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(store: HiveStore()),
    );

    blockClient = GraphQLClient(
      link: HttpLink('https://api.thegraph.com/subgraphs/name/blocklytics/ethereum-blocks'),
      // The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(store: HiveStore()),
    );

    ensClient = GraphQLClient(
      link: HttpLink('https://api.thegraph.com/subgraphs/name/ensdomains/ens'),
      // The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(store: HiveStore()),
    );

  }

}
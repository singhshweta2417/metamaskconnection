import 'package:flutter/material.dart';
import 'package:wallet_connect_v2/wallet_connect_v2.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnectWalletScreen extends StatefulWidget {
  const ConnectWalletScreen({super.key});

  @override
  _ConnectWalletScreenState createState() => _ConnectWalletScreenState();
}

class _ConnectWalletScreenState extends State<ConnectWalletScreen> {
  final WalletConnectManager walletConnectManager = WalletConnectManager();
  String? _walletAddress;

  @override
  void initState() {
    super.initState();
    initWalletConnect();
  }

  void initWalletConnect() {
    walletConnectManager.initialize(
      projectId: 'your_project_id', // Replace with your WalletConnect project ID
      walletMetadata: AppMetadata(
        name: 'Flutter Wallet',
        url: 'https://avacus.cc',
        description: 'Flutter Wallet by Avacus',
        icons: ['https://avacus.cc/apple-icon-180x180.png'],
      ),
      onAddressFetched: (address) {
        print('Connected address: $address');
        setState(() {
          _walletAddress = address;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet Connect")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await walletConnectManager.connectToMetaMask();
                } catch (e) {
                  print("Error connecting to MetaMask: $e");
                }
              },
              child: const Text('Connect with MetaMask'),
            ),
            const SizedBox(height: 20),
            Text(
              _walletAddress != null
                  ? 'Connected: ${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}'
                  : 'Not connected',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletConnectManager {
  final WalletConnectV2 _client = WalletConnectV2();
  String? _connectedAddress;

  void initialize({
    required String projectId,
    required AppMetadata walletMetadata,
    Function(String)? onAddressFetched,
  }) {
    _client.init(
      projectId: projectId,
      appMetadata: walletMetadata,
    );
    _client.onSessionSettle = (session) {
      final accounts = session.namespaces['eip155']?.accounts ?? [];
      if (accounts.isNotEmpty) {
        _connectedAddress = accounts.first.split(':').last;
        if (onAddressFetched != null) {
          onAddressFetched(_connectedAddress!);
        }
      }
    };
  }

  Future<void> connectToMetaMask() async {
    try {
      final uri = await _client.createPair(namespaces: {
        'eip155': ProposalNamespace(
            chains: ['eip155:1'],
            methods: [
              "eth_sendTransaction",
              "eth_signTransaction",
              "personal_sign",
              "eth_signTypedData"
            ],
            events: ["chainChanged", "accountsChanged"]
        )
      });
      if (uri != null) {
        print('Pairing URI: $uri');
        await _launchMetaMask(uri);
      } else {
        print('No URI generated, check WalletConnect configuration.');
      }
    } catch (e) {
      print('Error creating pair: $e');
      rethrow; // Re-throw to catch in the UI layer
    }
  }

  Future<void> _launchMetaMask(String uri) async {
    final metaMaskUniversalLink = 'https://metamask.app/wc?uri=$uri';
    try {
      if (await canLaunch(metaMaskUniversalLink)) {
        await launch(metaMaskUniversalLink);
      } else {
        print('MetaMask not installed or unable to launch');
      }
    } catch (e) {
      print('Error launching MetaMask: $e');
      throw Exception('MetaMask launch failed');
    }
  }
}

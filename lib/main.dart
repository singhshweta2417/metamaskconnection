import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:metamask_flutter_mobile_connect/metamask.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetaMaskProvider()..init(), // initialize MetaMask
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF181818),
          body: Stack(
            children: [
              Center(
                child: Consumer<MetaMaskProvider>(
                  builder: (context, provider, child) {
                    late final String text; // Variable to display status
                    String walletAddress = ''; // To hold the wallet address

                    // Check if MetaMask is connected
                    if (provider.isConnected && provider.isInOperatingChain) {
                      text = 'Connected'; // Connection status
                      walletAddress = provider.currentAddress ?? ''; // Get the wallet address
                      print("aa gyaa kyaa bataoa${walletAddress}");
                    } else if (provider.isConnected && !provider.isInOperatingChain) {
                      text =
                      'Wrong chain. Please connect to ${MetaMaskProvider.operatingChain}';
                    } else if (provider.isEnabled) {
                      text = 'Please connect to MetaMask.';
                    } else {
                      text = 'Please use a Web3 supported browser.';
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        if (walletAddress.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Wallet Address: $walletAddress',
                              style: const TextStyle(fontSize: 16, color: Colors.green),
                            ),
                          ),
                        if (!provider.isConnected && provider.isEnabled)
                          CupertinoButton(
                            onPressed: () => context.read<MetaMaskProvider>().connect(),
                            color: Colors.white,
                            padding: const EdgeInsets.all(0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  'https://i0.wp.com/kindalame.com/wp-content/uploads/2021/05/metamask-fox-wordmark-horizontal.png?fit=1549%2C480&ssl=1',
                                  width: 300,
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.network(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTicLAkhCzpJeu9OV-4GOO-BOon5aPGsj_wy9ETkR4g-BdAc8U2-TooYoiMcPcmcT48H7Y&usqp=CAU',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.025),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

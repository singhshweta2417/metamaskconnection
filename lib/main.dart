import 'package:flutter/material.dart';
import 'package:metamask_flutter_mobile_connect/guc_service.dart';
import 'package:metamask_flutter_mobile_connect/metamask.dart';
import 'package:provider/provider.dart';

void main() {
  GUCService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetaMask DCSM Demo',
      theme: ThemeData.dark(),
      home: ChangeNotifierProvider(
        create: (context) => MetaMaskProvider()..initialize(),
        child: const MetaMaskDemoPage(),
      ),
    );
  }
}

class MetaMaskDemoPage extends StatefulWidget {
  const MetaMaskDemoPage({super.key});

  @override
  State<MetaMaskDemoPage> createState() => _MetaMaskDemoPageState();
}

class _MetaMaskDemoPageState extends State<MetaMaskDemoPage> {
  double gucBalance = 0.0;
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isTransferring = false;

  Future<void> _transferETH() async {
    // Get the provider instance
    final metaMaskProvider = context.read<MetaMaskProvider>();

    // Validate connection and network
    if (!metaMaskProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your wallet first')),
      );
      return;
    }

    if (!metaMaskProvider.isInOperatingChain) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please switch to the correct network')),
      );
      return;
    }

    // Get and validate inputs
    final recipient = _recipientController.text.trim();
    final amount = _amountController.text.trim();

    if (recipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipient address')),
      );
      return;
    }

    if (!GUCService.isValidAddress(recipient)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Ethereum address format')),
      );
      return;
    }

    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount')),
      );
      return;
    }

    // Show processing indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing transaction...')),
    );

    try {
      // Send transaction
      final txHash = await metaMaskProvider.sendTransaction(
        toAddress: recipient,
        amountInEth: amount,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction sent! Hash: ${txHash.substring(0, 10)}...'),
          // duration: const Duration(seconds: 5),
          // action: SnackBarAction(
          //   label: 'View',
          //   onPressed: () => _viewOnExplorer(txHash),
          // ),
        ),
      );

      // Clear form on success
      _recipientController.clear();
      _amountController.clear();
    } catch (e) {
      String errorMessage = 'Transaction failed';

      // Parse common MetaMask errors
      if (e.toString().contains('insufficient funds')) {
        errorMessage = 'Insufficient balance for transaction';
      } else if (e.toString().contains('user rejected transaction')) {
        errorMessage = 'Transaction cancelled by user';
      } else if (e.toString().contains('gas')) {
        errorMessage = 'Gas estimation failed';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // void _viewOnExplorer(String txHash) {
  //   // Replace with your chain's explorer URL
  //   const explorerUrl = 'https://explorer.decentraconnect.io/tx/';
  //   final url = '$explorerUrl$txHash';
  //
  //   // Launch URL using url_launcher package
  //   launchUrl(Uri.parse(url));
  // }


  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      _fetchGUCBalance();
    });
  }

  Future<void> _fetchGUCBalance() async {
    final metaMaskProvider = context.read<MetaMaskProvider>();

    if (!metaMaskProvider.isConnected ||
        metaMaskProvider.currentAddress.isEmpty) {
      print("Not connected or no address available");
      return;
    }

    try {
      print("Fetching GUC balance for: ${metaMaskProvider.currentAddress}");
      double balance =
          await GUCService.getGUCBalance(metaMaskProvider.currentAddress);
      print("Fetched GUC Balance: $balance");

      if (mounted) {
        setState(() {
          gucBalance = balance;
        });
      }
    } catch (e) {
      print("Error fetching GUC balance: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching GUC balance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetaMaskProvider>();

    if (provider.isConnected &&
        provider.currentAddress.isNotEmpty &&
        gucBalance == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchGUCBalance();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MetaMask DCSM & GUC Demo')),
      body: Center(
        child: provider.isLoading
            ? const CircularProgressIndicator()
            : _buildContent(provider),
      ),
    );
  }

  Widget _buildContent(MetaMaskProvider provider) {
    if (!provider.isEnabled) {
      return const Text('Please install MetaMask or use a Web3 browser');
    }

    if (!provider.isConnected) {
      return ElevatedButton(
        onPressed: provider.connect,
        child: const Text('Connect with MetaMask'),
      );
    }

    if (!provider.isInOperatingChain) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Wrong network detected!'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.switchToDCSMChain,
            child: const Text('Switch to DCSM Network'),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Connected: ${provider.currentAddress}'),
        const SizedBox(height: 16),
        Text('DCSM Balance: ${provider.ethBalance.toStringAsFixed(4)} DCSM'),
        const SizedBox(height: 16),
        gucBalance == 0.0 && provider.isConnected
            ? const CircularProgressIndicator()
            : Text('GUC Balance: ${gucBalance.toStringAsFixed(4)} GUC'),
        const Divider(),
        const Text('Transfer GUC', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 5),
        TextField(
          controller: _recipientController,
          decoration: const InputDecoration(
            labelText: 'Recipient Address',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 5),
        ElevatedButton(
          onPressed: _isTransferring ? null : _transferETH,
          child: _isTransferring
              ? const CircularProgressIndicator()
              : const Text('Transfer'),
        ),
        const SizedBox(height: 5),
        ElevatedButton(
          onPressed: provider.disconnect,
          child: const Text('Disconnect'),
        ),
      ],
    );
  }
}

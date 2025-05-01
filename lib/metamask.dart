import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';

class MetaMaskProvider extends ChangeNotifier {
  static const int operatingChain = 19224; // DCSM Chain ID

  String _currentAddress = '';
  int _currentChain = -1;
  double _ethBalance = 0;
  bool _isConnected = false;
  bool _isLoading = false;

  String get currentAddress => _currentAddress;
  int get currentChain => _currentChain;
  double get ethBalance => _ethBalance;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isEnabled => ethereum != null;
  bool get isInOperatingChain => _currentChain == operatingChain;

  Future<void> connect() async {
    if (!isEnabled) return;

    _isLoading = true;
    notifyListeners();

    try {
      final accounts = await ethereum!.requestAccount();
      if (accounts.isEmpty) throw Exception("No accounts found");

      _currentAddress = accounts.first;
      _isConnected = true;

      _currentChain = await ethereum!.getChainId();
      await _fetchEthBalance();

      _setupEventListeners();

      if (!isInOperatingChain) {
        await switchToDCSMChain();
      }
    } catch (e) {
      _resetState();
      debugPrint("Connection error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchEthBalance() async {
    try {
      final balanceHex = await ethereum!.request<String>(
        'eth_getBalance',
        [_currentAddress, 'latest'],
      );
      final weiBalance =
          BigInt.parse(balanceHex.replaceFirst('0x', ''), radix: 16);
      _ethBalance = weiBalance / BigInt.from(10).pow(18);
    } catch (e) {
      debugPrint("Balance fetch error: $e");
      _ethBalance = 0;
    }
    notifyListeners();
  }

  Future<void> switchToDCSMChain() async {
    try {
      await ethereum!.walletSwitchChain(operatingChain);
      _currentChain = operatingChain;
    } catch (switchError) {
      if (switchError.toString().contains('4902')) {
        await _addDCSMChain();
      }
    }
    notifyListeners();
  }

  Future<void> _addDCSMChain() async {
    await ethereum!.walletAddChain(
      chainId: operatingChain,
      chainName: 'DecentraConnect Smart Chain',
      nativeCurrency: CurrencyParams(
        name: 'DCSM',
        symbol: 'DCSM',
        decimals: 18,
      ),
      rpcUrls: ['https://rpc.decentraconnect.io/'],
    );
  }

  void _setupEventListeners() {
    ethereum!.onAccountsChanged((accounts) {
      if (accounts.isEmpty) {
        _resetState();
      } else {
        _currentAddress = accounts.first;
        _fetchEthBalance();
      }
      notifyListeners();
    });

    ethereum!.onChainChanged((chainId) {
      _currentChain = chainId;
      if (!isInOperatingChain) {
        switchToDCSMChain();
      }
      notifyListeners();
    });
  }

  bool _isValidEthereumAddress(String address) {
    final pattern = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return pattern.hasMatch(address);
  }

  Future<String> sendTransaction({
    required String toAddress,
    required String amountInEth,
  }) async {
    if (!isEnabled) throw Exception('MetaMask extension not detected');
    if (!isConnected) throw Exception('Please connect your wallet first');

    try {
      final accounts = await ethereum!.requestAccount();
      if (accounts.isEmpty) throw Exception('No accounts available');
      final fromAddress = accounts.first;

      final recipientAddress = toAddress.trim();
      if (!_isValidEthereumAddress(recipientAddress)) {
        throw Exception('Invalid recipient address format');
      }

      // Ensure recipient address is not empty
      if (recipientAddress.isEmpty) {
        throw Exception('Recipient address cannot be empty');
      }

      final amount = double.tryParse(amountInEth);
      if (amount == null || amount <= 0) {
        throw Exception('Amount must be a positive number');
      }

      final weiAmount = BigInt.parse((amount * 1e18).toStringAsFixed(0));
      final valueHex = '0x${weiAmount.toRadixString(16)}';

      final txParams = {
        'from': fromAddress,
        'to': recipientAddress.toLowerCase(),
        'value': valueHex,
        'gas': '0x5208',
      };

      debugPrint('MetaMask TX Params: ${jsonEncode(txParams)}');

      final txHash = await ethereum!.request<String>(
        'eth_sendTransaction',
        [txParams],
      );

      return txHash;
    } catch (e) {
      debugPrint('Transaction Failed: ${e.toString()}');
      throw _parseMetaMaskError(e.toString());
    }
  }


  String _parseMetaMaskError(String error) {
    if (error.contains('Invalid parameters') ||
        error.contains('invalid address')) {
      return 'The recipient address is invalid. Please check and try again.';
    }
    if (error.contains('user rejected')) {
      return 'Transaction was cancelled';
    }
    if (error.contains('insufficient funds')) {
      return 'Not enough ETH for this transaction';
    }
    return 'Transaction failed. Please try again.';
  }

  ///

  void disconnect() {
    _resetState();
    notifyListeners();
  }

  void _resetState() {
    _currentAddress = '';
    _currentChain = -1;
    _ethBalance = 0;
    _isConnected = false;
    _isLoading = false;
  }

  void initialize() {
    if (isEnabled) {
      _setupEventListeners();
      ethereum!.getChainId().then((chainId) {
        _currentChain = chainId;
        notifyListeners();
      });
    }
  }
}

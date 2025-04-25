
import 'package:flutter/services.dart';

class MetaMaskService {
  static const MethodChannel _channel = MethodChannel('walletconnect_channel');

  // Method to connect to MetaMask
  static Future<void> connectToMetaMask(String wcUri) async {
    try {
      final result = await _channel.invokeMethod('connectToMetaMask', {'wcUri': wcUri});
      print("MetaMask opened: $result");
    } on PlatformException catch (e) {
      print("Failed to connect to MetaMask: ${e.message}");
    }
  }

  // Method to fetch wallet address
  static Future<String?> fetchWalletAddress() async {
    try {
      final String? address = await _channel.invokeMethod('fetchWalletAddress');
      return address;
    } on PlatformException catch (e) {
      print("Failed to fetch wallet address: ${e.message}");
      return null;
    }
  }
}

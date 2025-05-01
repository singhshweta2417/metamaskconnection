import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_web3/ethereum.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class GUCService {
  /// GUC Token Address
  static const String gucTokenAddress = '0x873c53Aa460F91f70966f3D6017D7Cf9DE88a811';

  /// RPC URL
  static const String rpcUrl = 'https://rpc.decentraconnect.io/';

  /// Required Chain ID
  static const int requiredChainId = 19224;

  ///erc20Abi
  static const erc20Abi = [
    {
      "type": "constructor",
      "stateMutability": "nonpayable",
      "inputs": [
        {"type": "uint256", "name": "_totalSupply", "internalType": "uint256"}
      ]
    },
    {
      "type": "event",
      "name": "Approval",
      "inputs": [
        {
          "type": "address",
          "name": "owner",
          "internalType": "address",
          "indexed": true
        },
        {
          "type": "address",
          "name": "spender",
          "internalType": "address",
          "indexed": true
        },
        {
          "type": "uint256",
          "name": "value",
          "internalType": "uint256",
          "indexed": false
        }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "Transfer",
      "inputs": [
        {
          "type": "address",
          "name": "from",
          "internalType": "address",
          "indexed": true
        },
        {
          "type": "address",
          "name": "to",
          "internalType": "address",
          "indexed": true
        },
        {
          "type": "uint256",
          "name": "value",
          "internalType": "uint256",
          "indexed": false
        }
      ],
      "anonymous": false
    },
    {
      "type": "function",
      "stateMutability": "view",
      "outputs": [
        {"type": "uint256", "name": "", "internalType": "uint256"}
      ],
      "name": "allowance",
      "inputs": [
        {"type": "address", "name": "owner", "internalType": "address"},
        {"type": "address", "name": "spender", "internalType": "address"}
      ]
    },
    {
      "type": "function",
      "stateMutability": "nonpayable",
      "outputs": [
        {"type": "bool", "name": "", "internalType": "bool"}
      ],
      "name": "approve",
      "inputs": [
        {"type": "address", "name": "spender", "internalType": "address"},
        {"type": "uint256", "name": "amount", "internalType": "uint256"}
      ]
    },
    {
      "type": "function",
      "stateMutability": "view",
      "outputs": [
        {"type": "uint256", "name": "", "internalType": "uint256"}
      ],
      "name": "balanceOf",
      "inputs": [
        {"type": "address", "name": "account", "internalType": "address"}
      ]
    },
    {
      "type": "function",
      "stateMutability": "view",
      "outputs": [
        {"type": "uint8", "name": "", "internalType": "uint8"}
      ],
      "name": "decimals",
      "inputs": []
    },
    {
      "type": "function",
      "stateMutability": "nonpayable",
      "outputs": [
        {"type": "bool", "name": "", "internalType": "bool"}
      ],
      "name": "decreaseAllowance",
      "inputs": [
        {"type": "address", "name": "spender", "internalType": "address"},
        {
          "type": "uint256",
          "name": "subtractedValue",
          "internalType": "uint256"
        }
      ]
    },
    {
      "type": "function",
      "stateMutability": "nonpayable",
      "outputs": [
        {"type": "bool", "name": "", "internalType": "bool"}
      ],
      "name": "increaseAllowance",
      "inputs": [
        {"type": "address", "name": "spender", "internalType": "address"},
        {"type": "uint256", "name": "addedValue", "internalType": "uint256"}
      ]
    },
    {
      "type": "function",
      "stateMutability": "view",
      "outputs": [
        {"type": "string", "name": "", "internalType": "string"}
      ],
      "name": "name",
      "inputs": []
    },
    {
      "type": "function",
      "stateMutability": "view",
      "outputs": [
        {"type": "string", "name": "", "internalType": "string"}
      ],
      "name": "symbol",
      "inputs": []
    },
    {
      "type": "function",
      "stateMutability": "view",
      "outputs": [
        {"type": "uint256", "name": "", "internalType": "uint256"}
      ],
      "name": "totalSupply",
      "inputs": []
    },
    {
      "type": "function",
      "stateMutability": "nonpayable",
      "outputs": [
        {"type": "bool", "name": "", "internalType": "bool"}
      ],
      "name": "transfer",
      "inputs": [
        {"type": "address", "name": "to", "internalType": "address"},
        {"type": "uint256", "name": "amount", "internalType": "uint256"}
      ]
    },
    {
      "type": "function",
      "stateMutability": "nonpayable",
      "outputs": [
        {"type": "bool", "name": "", "internalType": "bool"}
      ],
      "name": "transferFrom",
      "inputs": [
        {"type": "address", "name": "from", "internalType": "address"},
        {"type": "address", "name": "to", "internalType": "address"},
        {"type": "uint256", "name": "amount", "internalType": "uint256"}
      ]
    }
  ];

  static Web3Client? web3client;

  static bool isValidAddress(String address) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  static void initialize() {
    web3client = Web3Client(rpcUrl, Client());
    print("GUCService initialized");
  }

  static Future<Map<String, dynamic>> getTokenInfo() async {
    if (web3client == null) throw Exception("Web3Client not initialized");

    final contract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(erc20Abi), "GUC"),
      EthereumAddress.fromHex(gucTokenAddress),
    );

    final nameFunction = contract.function('name');
    final symbolFunction = contract.function('symbol');
    final decimalsFunction = contract.function('decimals');

    final results = await Future.wait([
      web3client!.call(contract: contract, function: nameFunction, params: []),
      web3client!.call(contract: contract, function: symbolFunction, params: []),
      web3client!.call(contract: contract, function: decimalsFunction, params: []),
    ]);

    return {
      'name': results[0].first as String,
      'symbol': results[1].first as String,
      'decimals': (results[2].first as BigInt).toInt(),
    };
  }

  static Future<double> getGUCBalance(String address) async {
    try {
      if (web3client == null) throw Exception("Web3Client not initialized");
      if (!isValidAddress(address)) throw Exception("Invalid address");

      final contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(erc20Abi), "GUC"),
        EthereumAddress.fromHex(gucTokenAddress),
      );

      final balanceFunction = contract.function('balanceOf');
      final balanceResult = await web3client!.call(
        contract: contract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(address)],
      );

      BigInt rawBalance = balanceResult.first as BigInt;
      return rawBalance / BigInt.from(10).pow(18);
    } catch (e) {
      print("Error in getGUCBalance: $e");
      rethrow;
    }
  }

  static Future<String> transferGUC({
    required String fromPrivateKey,
    required String toAddress,
    required double amount,
    String? walletPassword,
  }) async
  {
    try {
      web3client ??= Web3Client(rpcUrl, Client());

      Credentials credentials;
      if (walletPassword != null) {
        String content = File("wallet.json").readAsStringSync();
        Wallet wallet = Wallet.fromJson(content, walletPassword);
        credentials = wallet.privateKey;
      } else {
        credentials = EthPrivateKey.fromHex(fromPrivateKey);
      }

      final senderAddress = await credentials.extractAddress();
      print("Sender address: ${senderAddress.hex}");

      if (!isValidAddress(toAddress)) {
        throw Exception("Invalid recipient address");
      }

      final contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(erc20Abi), "GUC"),
        EthereumAddress.fromHex(gucTokenAddress),
      );

      final transferFunction = contract.function('transfer');
      final weiAmount = BigInt.from(amount * pow(10, 18));
      final params = [
        EthereumAddress.fromHex(toAddress),
        weiAmount,
      ];

      final estimatedGas = await web3client!.estimateGas(
        sender: senderAddress,
        to: EthereumAddress.fromHex(gucTokenAddress),
        data: transferFunction.encodeCall(params),
      );

      final gasPrice = await web3client!.getGasPrice();

      final txHash = await web3client!.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: transferFunction,
          parameters: params,
          gasPrice: gasPrice,
          maxGas: estimatedGas.toInt(), // Convert BigInt to int
        ),
        chainId: requiredChainId,
      );

      print("Transaction sent. Hash: $txHash");
      return txHash;
    } catch (e) {
      print("Error in transferGUC: $e");
      rethrow;
    }
  }



  static Future<String> transferGUCWithMetaMask({
    required String fromAddress,  // User's connected MetaMask address
    required String toAddress,
    required double amount,
  }) async
  {
    try {
      // 1. Validate addresses
      if (!isValidAddress(fromAddress)) throw Exception("Invalid sender address");
      if (!isValidAddress(toAddress)) throw Exception("Invalid recipient address");

      // 2. Convert amount to Wei (adjust decimals if needed)
      final weiAmount = BigInt.from(amount * pow(10, 18));

      // 3. Prepare the transaction data (ABI-encoded function call)
      final contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(erc20Abi), "GUC"),
        EthereumAddress.fromHex(gucTokenAddress),
      );
      final transferFunction = contract.function('transfer');
      final data = transferFunction.encodeCall([
        EthereumAddress.fromHex(toAddress),
        weiAmount,
      ]);

      // 4. Send transaction via MetaMask
      final txHash = await ethereum!.request<String>('eth_sendTransaction', [
        {
          'from': fromAddress,
          'to': gucTokenAddress,
          'value': '0x0',  // For token transfers, value should be 0
          'data': '0x${data.toSet()}',
          // Let MetaMask handle gas estimation:
          // 'gas': ...,
          // 'gasPrice': ...,
        }
      ]);

      return txHash;
    } catch (e) {
      print("Error in transferGUCWithMetaMask: $e");
      rethrow;
    }
  }



}
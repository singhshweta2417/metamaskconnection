// import 'package:url_launcher/url_launcher.dart';
// import 'package:wallet_connect_v2/wallet_connect_v2.dart';
//
// class WalletConnectManager {
//   final WalletConnectV2 _client = WalletConnectV2();
//   String? _connectedAddress;
//   Function(String)? _onAddressFetched;
//
//   /// Initialize WalletConnect client with projectId and metadata
//   void initialize({
//     required String projectId,
//     required AppMetadata walletMetadata,
//     Function(String)? onAddressFetched,
//   }) {
//     _onAddressFetched = onAddressFetched;
//     _client.init(
//       projectId: projectId,
//       appMetadata: walletMetadata,
//     );
//
//     _registerEventListeners();
//   }
//
//   /// Connect to MetaMask and return the wallet address
//   Future<void> connectToMetaMask() async {
//     try {
//       // Create a new pairing with Ethereum mainnet support
//       final uri = await _client.createPair(namespaces: {
//         'eip155': ProposalNamespace(
//             chains: ['eip155:1'], // Ethereum mainnet
//             methods: [
//               "eth_sendTransaction",
//               "eth_signTransaction",
//               "personal_sign",
//               "eth_signTypedData"
//             ],
//             events: ["chainChanged", "accountsChanged"]
//         )
//       });
//
//       if (uri != null) {
//         // This URI should be displayed as QR code or deep link to MetaMask
//         // For mobile, we can directly launch MetaMask with the URI
//         await _launchMetaMask(uri);
//       }
//     } catch (e) {
//       print('Error connecting to MetaMask: $e');
//     }
//   }
//
//   /// Launch MetaMask with WalletConnect URI
//   Future<void> _launchMetaMask(String uri) async {
//     try {
//       // MetaMask's universal link for WalletConnect
//       final metaMaskUniversalLink = 'https://metamask.app/wc?uri=$uri';
//       await launchUrl(Uri.parse(metaMaskUniversalLink));
//     } catch (e) {
//       print('Error launching MetaMask: $e');
//     }
//   }
//
//   /// Registers all event listeners
//   void _registerEventListeners() {
//     _client.onConnectionStatus = (bool isConnected) {
//       print("Socket connection status: $isConnected");
//     };
//
//     _client.onSessionProposal = (proposal) async {
//       print("Session proposal received: $proposal");
//
//       // Auto-approve the session for MetaMask
//       if (proposal.namespaces?.containsKey('eip155') ?? false) {
//         final approval = SessionApproval(
//           id: proposal.id,
//           namespaces: {
//             'eip155': SessionNamespace(
//               accounts: proposal.namespaces!['eip155']!.chains!
//                   .map((chain) => '$chain:${_connectedAddress ?? ''}')
//                   .toList(),
//               methods: proposal.namespaces!['eip155']!.methods ?? [],
//               events: proposal.namespaces!['eip155']!.events ?? [],
//             )
//           },
//         );
//
//         await _client.approveSession(approval: approval);
//       }
//     };
//
//     _client.onSessionSettle = (session) {
//       print("Session settled: $session");
//
//       // Extract the wallet address from the session
//       final accounts = session.namespaces['eip155']?.accounts ?? [];
//       if (accounts.isNotEmpty) {
//         // Format: "eip155:1:0x..." - we want the last part
//         _connectedAddress = accounts.first.split(':').last;
//         print("Connected address: $_connectedAddress");
//
//         // Notify the caller that we have the address
//         if (_onAddressFetched != null) {
//           _onAddressFetched!(_connectedAddress!);
//         }
//       }
//     };
//
//     _client.onSessionRequest = (request) async {
//       print("Session request received: $request");
//
//       // Handle different request types from dApps
//       switch (request.method) {
//         case 'personal_sign':
//         // MetaMask will handle the signing, we just need to forward the response
//           await _client.approveRequest(
//             topic: request.topic,
//             requestId: request.id,
//             result: '0x', // MetaMask will provide the actual signature
//           );
//           break;
//       // Add other cases as needed
//       }
//     };
//
//     _client.onSessionDelete = (topic) {
//       print("Session deleted for topic: $topic");
//       _connectedAddress = null;
//     };
//   }
//
//   /// Get the connected wallet address
//   String? get connectedAddress => _connectedAddress;
//
//   /// Disconnect from current session
//   Future<void> disconnect() async {
//     if (_connectedAddress != null) {
//       final sessions = await _client.getActivatedSessions();
//       for (final session in sessions) {
//         await _client.disconnectSession(topic: session.topic);
//       }
//       _connectedAddress = null;
//     }
//   }
// }
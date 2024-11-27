// import 'package:flutter/material.dart';
// import 'package:gamers_gram/modules/wallet/controllers/wallet_controller.dart';
// import 'package:get/get.dart';
// import 'package:gamers_gram/modules/arena/controllers/arena_controller.dart';

// class ArenaView extends StatelessWidget {
//   ArenaView({super.key});

//   final ArenaController _controller = Get.find();
//   final TextEditingController _chatController = TextEditingController();
//   WalletController walletbalance = WalletController();

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 4,
//       child: Scaffold(
//         appBar: _buildAppBar(),
//         body: TabBarView(
//           children: [
//             _buildRegistrationTab(),
//             _buildMatchesTab(),
//             _buildChatTab(),
//             _buildProfileTab(),
//           ],
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: const Text('Tournament Arena'),
//       actions: [
//         _buildWalletBalance(),
//       ],
//       bottom: const TabBar(
//         tabs: [
//           Tab(icon: Icon(Icons.app_registration), text: 'Registration'),
//           Tab(icon: Icon(Icons.sports_esports), text: 'Matches'),
//           Tab(icon: Icon(Icons.chat), text: 'Chat'),
//           Tab(icon: Icon(Icons.person), text: 'Profile'),
//         ],
//       ),
//     );
//   }

//   Widget _buildWalletBalance() {
//     return Obx(() => Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Center(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 '\$${walletbalance.balance.value.toStringAsFixed(2)}',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ));
//   }

//   Widget _buildRegistrationTab() {
//     return Obx(() => RefreshIndicator(
//           onRefresh: () async {
//             // Add refresh logic here
//           },
//           child: ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               _buildTournamentInfo(),
//               const SizedBox(height: 16),
//               _buildRegistrationCard(),
//               const SizedBox(height: 16),
//               _buildRegisteredPlayersList(),
//               if (_controller.isAdmin.value) ...[
//                 const SizedBox(height: 16),
//                 _buildAdminControls(),
//               ],
//             ],
//           ),
//         ));
//   }

//   Widget _buildTournamentInfo() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Tournament Information',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: const Icon(Icons.people),
//               title: const Text('Total Players'),
//               trailing: Obx(() => Text(
//                     '${_controller.registeredPlayers.length}',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   )),
//             ),
//             const ListTile(
//               leading: Icon(Icons.attach_money),
//               title: Text('Entry Fee'),
//               trailing: Text(
//                 '\$10.00',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRegistrationCard() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Obx(() {
//           if (!_controller.isRegistered.value) {
//             return ElevatedButton(
//               onPressed: walletbalance.balance.value >= 0.0
//                   ? _controller.registerForTournament
//                   : null,
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 50),
//               ),
//               child: const Text('Register for Tournament'),
//             );
//           }

//           return Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.green.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.check_circle, color: Colors.green),
//                 SizedBox(width: 8),
//                 Text(
//                   'Successfully Registered',
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildRegisteredPlayersList() {
//     return Card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.all(16),
//             child: Text(
//               'Registered Players',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Obx(() => ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _controller.registeredPlayers.length,
//                 itemBuilder: (context, index) {
//                   final player = _controller.registeredPlayers[index];
//                   return ListTile(
//                     leading: CircleAvatar(
//                       child: Text(player.username[0].toUpperCase()),
//                     ),
//                     title: Text(player.username),
//                     subtitle: Text('Stage ${player.currentStage.index + 1}'),
//                   );
//                 },
//               )),
//         ],
//       ),
//     );
//   }

//   Widget _buildAdminControls() {
//     return ElevatedButton(
//       onPressed: _controller.startTournament,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green,
//         minimumSize: const Size(double.infinity, 50),
//       ),
//       child: const Text('Start Tournament'),
//     );
//   }

//   Widget _buildMatchesTab() {
//     return Column(
//       children: [
//         _buildStageSelector(),
//         _buildQueueButton(),
//         Expanded(child: _buildCurrentMatches()),
//       ],
//     );
//   }

//   Widget _buildStageSelector() {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Select Stage',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Obx(() => DropdownButtonFormField<int>(
//                   value: _controller.currentStage.value,
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                   ),
//                   items: List.generate(
//                     5,
//                     (index) => DropdownMenuItem(
//                       value: index + 1,
//                       child: Text('Stage ${index + 1}'),
//                     ),
//                   ),
//                   onChanged: (int? newValue) {
//                     if (newValue != null) {
//                       _controller.setCurrentStage(newValue);
//                     }
//                   },
//                 )),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQueueButton() {
//     return Obx(() => Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: ElevatedButton(
//             onPressed: _controller.isInQueue.value
//                 ? _controller.leaveQueue
//                 : _controller.joinQueue,
//             style: ElevatedButton.styleFrom(
//               backgroundColor:
//                   _controller.isInQueue.value ? Colors.red : Colors.blue,
//               minimumSize: const Size(double.infinity, 50),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(_controller.isInQueue.value
//                     ? Icons.exit_to_app
//                     : Icons.queue_play_next),
//                 const SizedBox(width: 8),
//                 Text(
//                     _controller.isInQueue.value ? 'Leave Queue' : 'Join Queue'),
//               ],
//             ),
//           ),
//         ));
//   }

//   Widget _buildCurrentMatches() {
//     return Obx(() => ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: _controller.currentMatches.length,
//           itemBuilder: (context, index) {
//             final match = _controller.currentMatches[index];
//             final isParticipant =
//                 match.player1Id == _controller.currentPlayer.value?.userId ||
//                     match.player2Id == _controller.currentPlayer.value?.userId;

//             return Card(
//               margin: const EdgeInsets.only(bottom: 8),
//               child: ListTile(
//                 title: Text(
//                   'Match #${match.matchId}',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Stage ${match.stage.index + 1}'),
//                     Text('Status: ${match.status.toString().split('.').last}'),
//                   ],
//                 ),
//                 trailing: isParticipant
//                     ? ElevatedButton(
//                         onPressed: () => _controller.openMatchChat(match),
//                         child: const Text('Open Chat'),
//                       )
//                     : null,
//               ),
//             );
//           },
//         ));
//   }

//   Widget _buildChatTab() {
//     return Column(
//       children: [
//         _buildActiveMatchInfo(),
//         Expanded(child: _buildChatMessages()),
//         _buildChatInput(),
//       ],
//     );
//   }

//   Widget _buildActiveMatchInfo() {
//     return Obx(() {
//       final match = _controller.activeMatch.value;
//       if (match == null) {
//         return const Center(
//           child: Padding(
//             padding: EdgeInsets.all(16),
//             child: Text('No active match selected'),
//           ),
//         );
//       }

//       return Card(
//         margin: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             ListTile(
//               title: Text(
//                 'Match #${match.matchId}',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text('Stage ${match.stage.index + 1}'),
//             ),
//             const Divider(),
//             Padding(
//               padding: const EdgeInsets.all(8),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () =>
//                         _controller.reportMatchResult(match.matchId!, true),
//                     style:
//                         ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                     child: const Text('Won'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () =>
//                         _controller.reportMatchResult(match.matchId!, false),
//                     style:
//                         ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                     child: const Text('Lost'),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildChatMessages() {
//     return Obx(() => ListView.builder(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           reverse: true,
//           itemCount: _controller.currentChatMessages.length,
//           itemBuilder: (context, index) {
//             final message = _controller.currentChatMessages[index];
//             final isCurrentUser =
//                 message.senderId == _controller.currentPlayer.value?.userId;

//             return Align(
//               alignment:
//                   isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
//               child: Container(
//                 margin: EdgeInsets.only(
//                   bottom: 8,
//                   left: isCurrentUser ? 50 : 0,
//                   right: isCurrentUser ? 0 : 50,
//                 ),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: isCurrentUser ? Colors.blue : Colors.grey[300],
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (!isCurrentUser)
//                       Text(
//                         message.senderUsername,
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                           color: isCurrentUser ? Colors.white : Colors.black87,
//                         ),
//                       ),
//                     Text(
//                       message.content,
//                       style: TextStyle(
//                         color: isCurrentUser ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ));
//   }

//   Widget _buildChatInput() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 5,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _chatController,
//               decoration: InputDecoration(
//                 hintText: 'Type a message...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 contentPadding:
//                     const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               ),
//               onSubmitted: (value) {
//                 if (value.isNotEmpty && _controller.activeMatch.value != null) {
//                   _controller.sendMessage(
//                       _controller.activeMatch.value!.matchId!, value);
//                   _chatController.clear();
//                 }
//               },
//             ),
//           ),
//           const SizedBox(width: 8),
//           IconButton(
//             icon: const Icon(Icons.send),
//             onPressed: () {
//               if (_chatController.text.isNotEmpty &&
//                   _controller.activeMatch.value != null) {
//                 _controller.sendMessage(_controller.activeMatch.value!.matchId!,
//                     _chatController.text);
//                 _chatController.clear();
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileTab() {
//     return Obx(() {
//       final player = _controller.currentPlayer.value;
//       if (player == null) {
//         return const Center(child: Text('Profile not loaded'));
//       }

//       return ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 40,
//                         child: Text(
//                           player.username[0].toUpperCase(),
//                           style: const TextStyle(fontSize: 32),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               player.username,
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               'ID: ${player.userId}',
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
//                   _buildStatCard(
//                     'Current Stage',
//                     'Stage ${player.currentStage.index + 1}',
//                     Icons.stairs,
//                   ),
//                   const SizedBox(height: 12),
//                   _buildStatCard(
//                     'Matches Won',
//                     player.matchesWonInCurrentStage.toString(),
//                     Icons.emoji_events,
//                   ),
//                   const SizedBox(height: 12),
//                   _buildStatCard(
//                     'Tokens',
//                     player.tokens.toString(),
//                     Icons.token,
//                   ),
//                   if (player.isDisqualified) ...[
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.red.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Row(
//                         children: [
//                           Icon(Icons.warning, color: Colors.red),
//                           SizedBox(width: 8),
//                           Text(
//                             'Disqualified from Tournament',
//                             style: TextStyle(
//                               color: Colors.red,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Tournament Progress',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   LinearProgressIndicator(
//                     value: (player.currentStage.index + 1) / 5,
//                     backgroundColor: Colors.grey[200],
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       Theme.of(Get.context!).primaryColor,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Stage ${player.currentStage.index + 1} of 5',
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildStatCard(String label, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: Theme.of(Get.context!).primaryColor),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 12,
//                 ),
//               ),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class ArenaView extends StatelessWidget {
  const ArenaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gamers Gram Arena"),
      ),
      body: const Center(
        child: Text("Coming Soon"),
      ),
    );
  }
}

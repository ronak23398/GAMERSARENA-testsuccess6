import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:gamers_gram/modules/challenges/controllers/1v1_challenege_controller.dart';
import 'package:gamers_gram/modules/challenges/controllers/scrim_controller.dart';
import 'package:gamers_gram/modules/challenges/view/1v1_create_challenge_dialogue_view.dart';
import 'package:gamers_gram/modules/challenges/view/challengeAndscrim_chat_page.dart';
import 'package:gamers_gram/modules/challenges/view/scrim_create_dialogue.dart';
import 'package:gamers_gram/data/models/scrim_model.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ChallengeController challengeController =
      Get.find<ChallengeController>();
  final ScrimController scrimController = Get.find<ScrimController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> getUserName(String userId) async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('users/$userId/username')
        .get();
    return snapshot.value?.toString() ?? 'Unknown User';
  }

  void _showCreateDialog(BuildContext context) {
    if (_tabController.index == 0) {
      Get.dialog(CreateChallengeDialog());
    } else {
      Get.dialog(CreateScrimDialog());
    }
  }

  void _showAcceptScrimDialog(ScrimModel scrim) {
    final TextEditingController teamNameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Accept Scrim',
          style: TextStyle(color: Colors.grey[200]),
        ),
        content: TextField(
          controller: teamNameController,
          style: TextStyle(color: Colors.grey[200]),
          decoration: InputDecoration(
            labelText: 'Your Team Name',
            labelStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.group, color: Colors.grey[400]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[500]!),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
            ),
            onPressed: () {
              final teamName = teamNameController.text.trim();
              if (teamName.isNotEmpty) {
                scrimController.acceptScrim(scrim.id, teamName).then((success) {
                  if (success) {
                    Get.back();
                  }
                });
              } else {
                Get.snackbar(
                  'Error',
                  'Please enter a team name',
                  backgroundColor: Colors.grey[900],
                  colorText: Colors.grey[200],
                );
              }
            },
            child: Text('Accept', style: TextStyle(color: Colors.grey[200])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Gaming Challenges',
          style: TextStyle(color: Colors.grey[200]),
        ),
        bottom: TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: Colors.grey[500],
          indicatorWeight: 3,
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                "1v1",
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
            Tab(
              child: Text(
                "Scrims",
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.wallet, color: Colors.grey[300]),
            onPressed: () => Get.toNamed("/wallet"),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.grey[300]),
            onPressed: () {
              AuthService().signOut();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChallengesList(),
          _buildScrimsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: Colors.grey[700],
        child: Icon(Icons.add, color: Colors.grey[200]),
      ),
    );
  }

  Widget _buildChallengesList() {
    return Obx(() => ListView.builder(
          itemCount: challengeController.challenges.length,
          itemBuilder: (context, index) {
            final challenge = challengeController.challenges[index];
            final currentUser = FirebaseAuth.instance.currentUser;

            return Card(
              color: Colors.grey[850],
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  '${challenge.game} - ${challenge.server}',
                  style: TextStyle(color: Colors.grey[200]),
                ),
                subtitle: FutureBuilder<String>(
                  future: getUserName(challenge.creatorId),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Loading...',
                      style: TextStyle(color: Colors.grey[400]),
                    );
                  },
                ),
                trailing: _buildChallengeActions(challenge, currentUser),
              ),
            );
          },
        ));
  }

  Widget _buildScrimsList() {
    return Obx(() => ListView.builder(
          itemCount: scrimController.scrims.length,
          itemBuilder: (context, index) {
            final scrim = scrimController.scrims[index];
            final currentUser = FirebaseAuth.instance.currentUser;

            return Card(
              color: Colors.grey[850],
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  '${scrim.game} - ${scrim.server}',
                  style: TextStyle(color: Colors.grey[200]),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: getUserName(scrim.creatorId),
                      builder: (context, snapshot) {
                        return Text(
                          'Creator: ${snapshot.data ?? 'Loading...'}',
                          style: TextStyle(color: Colors.grey[400]),
                        );
                      },
                    ),
                    Text(
                      'Creator Team: ${scrim.creatorTeamName}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    if (scrim.acceptorTeamName != null)
                      Text(
                        'Acceptor Team: ${scrim.acceptorTeamName}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                  ],
                ),
                trailing: _buildScrimActions(scrim, currentUser),
              ),
            );
          },
        ));
  }

  Widget _buildChallengeActions(dynamic challenge, User? currentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_rupee, size: 16, color: Colors.grey[400]),
            Text(
              challenge.amount.toStringAsFixed(2),
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _getChallengeActionButton(challenge, currentUser),
      ],
    );
  }

  Widget _buildScrimActions(ScrimModel scrim, User? currentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_rupee, size: 16, color: Colors.grey[400]),
            Text(
              scrim.amount.toStringAsFixed(2),
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _getScrimActionButton(scrim, currentUser),
      ],
    );
  }

  Widget _getChallengeActionButton(dynamic challenge, User? currentUser) {
    if (challenge.status == 'accepted' &&
        (currentUser?.uid == challenge.creatorId ||
            currentUser?.uid == challenge.acceptorId)) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
        onPressed: () => Get.to(
          () => ChallengeChatPage(
            challengeId: challenge.id,
            opponentId: currentUser?.uid == challenge.creatorId
                ? challenge.acceptorId ?? challenge.creatorId
                : challenge.creatorId,
          ),
        ),
        child:
            Text('Enter Challenge', style: TextStyle(color: Colors.grey[200])),
      );
    } else if (currentUser?.uid != challenge.creatorId) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
        onPressed: () => challengeController.acceptChallenge(challenge.id),
        child: Text('Accept', style: TextStyle(color: Colors.grey[200])),
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
        onPressed: () => challengeController.cancelChallenge(challenge.id),
        child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
      );
    }
  }

  Widget _getScrimActionButton(ScrimModel scrim, User? currentUser) {
    if (scrim.status == 'accepted' &&
        (currentUser?.uid == scrim.creatorId ||
            currentUser?.uid == scrim.acceptorId)) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
        onPressed: () => Get.to(
          () => ChallengeChatPage(
            challengeId: scrim.id,
            opponentId: currentUser?.uid == scrim.creatorId
                ? scrim.acceptorId ?? scrim.creatorId
                : scrim.creatorId,
          ),
        ),
        child:
            Text('Enter Scrim Chat', style: TextStyle(color: Colors.grey[200])),
      );
    } else if (currentUser?.uid != scrim.creatorId) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
        onPressed: () => _showAcceptScrimDialog(scrim),
        child: Text('Accept', style: TextStyle(color: Colors.grey[200])),
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
        onPressed: () => scrimController.cancelScrim(scrim.id),
        child: Text('Cancel', style: TextStyle(color: Colors.grey[200])),
      );
    }
  }
}

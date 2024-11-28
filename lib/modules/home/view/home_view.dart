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
        title: const Text('Accept Scrim'),
        content: TextField(
          controller: teamNameController,
          decoration: const InputDecoration(
            labelText: 'Your Team Name',
            prefixIcon: Icon(Icons.group),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final teamName = teamNameController.text.trim();
              if (teamName.isNotEmpty) {
                scrimController.acceptScrim(scrim.id, teamName).then((success) {
                  if (success) {
                    Get.back();
                  }
                });
              } else {
                Get.snackbar('Error', 'Please enter a team name');
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gaming Challenges'),
        bottom: TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: Colors.black,
          indicatorWeight: 5,
          controller: _tabController,
          tabs: const [
            Tab(
                child: Text(
              "1v1",
              style: TextStyle(color: Colors.white),
            )),
            Tab(
                child: Text(
              "Scrims",
              style: TextStyle(color: Colors.white),
            )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallet),
            onPressed: () => Get.toNamed("/wallet"),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Obx(() => ListView.builder(
                itemCount: challengeController.challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challengeController.challenges[index];
                  final currentUser = FirebaseAuth.instance.currentUser;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('${challenge.game} - ${challenge.server}'),
                      subtitle: FutureBuilder<String>(
                        future: getUserName(challenge.creatorId),
                        builder: (context, snapshot) {
                          return Text(snapshot.data ?? 'Loading...');
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.currency_rupee, size: 16),
                              Text(challenge.amount.toStringAsFixed(2)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          if (challenge.status == 'accepted' &&
                              (currentUser?.uid == challenge.creatorId ||
                                  currentUser?.uid == challenge.acceptorId))
                            ElevatedButton(
                              onPressed: () => Get.to(
                                () => ChallengeChatPage(
                                    challengeId: challenge.id,
                                    opponentId:
                                        currentUser?.uid == challenge.creatorId
                                            ? challenge.acceptorId ??
                                                challenge.creatorId
                                            : challenge.creatorId),
                              ),
                              child: const Text('Enter Challenge'),
                            )
                          else if (currentUser?.uid != challenge.creatorId)
                            ElevatedButton(
                              onPressed: () => challengeController
                                  .acceptChallenge(challenge.id),
                              child: const Text('Accept'),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => challengeController
                                  .cancelChallenge(challenge.id),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Cancel'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              )),
          Obx(() => ListView.builder(
              itemCount: scrimController.scrims.length,
              itemBuilder: (context, index) {
                final scrim = scrimController.scrims[index];
                final currentUser = FirebaseAuth.instance.currentUser;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('${scrim.game} - ${scrim.server}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: getUserName(scrim.creatorId),
                          builder: (context, snapshot) {
                            return Text(
                                'Creator: ${snapshot.data ?? 'Loading...'}');
                          },
                        ),
                        Text('Creator Team: ${scrim.creatorTeamName}'),
                        if (scrim.acceptorTeamName != null)
                          Text('Acceptor Team: ${scrim.acceptorTeamName}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.currency_rupee, size: 16),
                            Text(scrim.amount.toStringAsFixed(2)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        if (scrim.status == 'accepted' &&
                            (currentUser?.uid == scrim.creatorId ||
                                currentUser?.uid == scrim.acceptorId))
                          ElevatedButton(
                            onPressed: () => Get.to(
                              () => ChallengeChatPage(
                                  challengeId: scrim.id,
                                  opponentId:
                                      currentUser?.uid == scrim.creatorId
                                          ? scrim.acceptorId ?? scrim.creatorId
                                          : scrim.creatorId),
                            ),
                            child: const Text('Enter Challenge'),
                          )
                        else if (currentUser?.uid != scrim.creatorId)
                          ElevatedButton(
                            onPressed: () => _showAcceptScrimDialog(scrim),
                            child: const Text('Accept'),
                          )
                        else
                          ElevatedButton(
                            onPressed: () =>
                                scrimController.cancelScrim(scrim.id),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Cancel'),
                          ),
                      ],
                    ),
                  ),
                );
              })),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}


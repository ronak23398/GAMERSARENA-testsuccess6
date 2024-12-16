import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:gamers_gram/modules/challenges/controllers/1v1_challenege_controller.dart';
import 'package:gamers_gram/modules/challenges/controllers/scrim_controller.dart';
import 'package:gamers_gram/modules/challenges/view/1v1_create_challenge_dialogue_view.dart';
import 'package:gamers_gram/modules/challenges/view/challenge_chat_page.dart';
import 'package:gamers_gram/modules/challenges/view/scrim_chat_page.dart';
import 'package:gamers_gram/modules/challenges/view/scrim_create_dialogue.dart';
import 'package:gamers_gram/data/models/scrim_model.dart';
import 'package:gamers_gram/modules/profile/controllers/team_controller.dart';
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
    final TeamController teamController = Get.find<TeamController>();

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Accept Scrim',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        content: Obx(() {
          final currentTeam = teamController.currentTeam.value;

          if (currentTeam == null) {
            return Text(
              'No team selected',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team: ${currentTeam.name}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 10),
              _buildDetailText('Game: ${scrim.game}'),
              _buildDetailText('Server: ${scrim.server}'),
              _buildDetailText('Amount: ${scrim.amount}'),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Obx(() {
            final currentTeam = teamController.currentTeam.value;

            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: currentTeam == null
                  ? null
                  : () {
                      scrimController
                          .acceptScrim(scrim.id, currentTeam)
                          .then((success) {
                        if (success) {
                          Get.back();
                        }
                      });
                    },
              child: Text(
                'Accept',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailText(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gaming Challenges',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        bottom: TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                "1v1",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
            Tab(
              child: Text(
                "Scrims",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.wallet,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () => Get.toNamed("/wallet"),
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.secondary,
            ),
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
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onSecondary,
        ),
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  '${challenge.game} - ${challenge.server}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: FutureBuilder<String>(
                  future: getUserName(challenge.creatorId),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Loading...',
                      style: Theme.of(context).textTheme.bodySmall,
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  '${scrim.game} - ${scrim.server}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: getUserName(scrim.creatorId),
                      builder: (context, snapshot) {
                        return Text(
                          'Challenger Team: ${scrim.creatorTeamName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                    if (scrim.acceptorTeamName != null)
                      Text(
                        'Acceptor Team: ${scrim.acceptorTeamName}',
                        style: Theme.of(context).textTheme.bodySmall,
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
            Icon(
              Icons.currency_rupee,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            Text(
              challenge.amount.toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodySmall,
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
            Icon(
              Icons.currency_rupee,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            Text(
              scrim.amount.toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(width: 8),
        _getScrimActionButton(scrim, currentUser),
      ],
    );
  }

  Widget _getChallengeActionButton(dynamic challenge, User? currentUser) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: challenge.status == 'accepted'
            ? Theme.of(context).colorScheme.secondary
            : currentUser?.uid != challenge.creatorId
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
      ),
      onPressed: () {
        if (challenge.status == 'accepted' &&
            (currentUser?.uid == challenge.creatorId ||
                currentUser?.uid == challenge.acceptorId)) {
          Get.to(
            () => ChallengeChatPage(
              challengeId: challenge.id,
              opponentId: currentUser?.uid == challenge.creatorId
                  ? challenge.acceptorId ?? challenge.creatorId
                  : challenge.creatorId,
            ),
          );
        } else if (currentUser?.uid != challenge.creatorId) {
          challengeController.acceptChallenge(challenge.id);
        } else {
          challengeController.cancelChallenge(challenge.id);
        }
      },
      child: Text(
        challenge.status == 'accepted'
            ? 'Enter Challenge'
            : currentUser?.uid != challenge.creatorId
                ? 'Accept'
                : 'Cancel',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  Widget _getScrimActionButton(ScrimModel scrim, User? currentUser) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: scrim.status == 'accepted'
            ? Theme.of(context).colorScheme.secondary
            : currentUser?.uid != scrim.creatorId
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
      ),
      onPressed: () {
        if (scrim.status == 'accepted' &&
            (currentUser?.uid == scrim.creatorId ||
                currentUser?.uid == scrim.acceptorId)) {
          Get.to(
            () => ScrimChatPage(scrimId: scrim.id, scrim: scrim),
          );
        } else if (currentUser?.uid != scrim.creatorId) {
          _showAcceptScrimDialog(scrim);
        } else {
          scrimController.cancelScrim(scrim.id);
        }
      },
      child: Text(
        scrim.status == 'accepted'
            ? 'Enter Scrim Chat'
            : currentUser?.uid != scrim.creatorId
                ? 'Accept'
                : 'Cancel',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}

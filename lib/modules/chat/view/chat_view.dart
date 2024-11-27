import 'package:flutter/material.dart';
import 'package:gamers_gram/modules/chat/controllers/chat_controller.dart';
import 'package:gamers_gram/modules/chat/view/direct_chat_view.dart';
import 'package:gamers_gram/modules/chat/view/matches_chat_view.dart';
import 'package:get/get.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final chatController = Get.put(ChatController());
  final TextEditingController messageController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      chatController.isMatchChat.value = _tabController.index == 0;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Match Chats'),
            Tab(text: 'Direct Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MatchChatsTab(),
          DirectChatsTab(),
        ],
      ),
    );
  }
}

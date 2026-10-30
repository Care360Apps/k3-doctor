import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/chat/constants/firestore_constants.dart';
import 'package:doctro/chat/providers/auth_provider.dart';
import 'package:doctro/chat/providers/chat_provider.dart';
import 'package:doctro/chat/providers/home_provider.dart';
import 'package:doctro/chat/utils/utilities.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/screens/home%20page/login_home.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  final int _limitIncrement = 20;

  late AuthProvider authProvider;
  late HomeProvider homeProvider;
  late ChatProvider chatProvider;
  String currentUserId = '';
  StreamController<bool> btnClearController = StreamController<bool>();

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();
    chatProvider = context.read<ChatProvider>();

    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    }
    listScrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    btnClearController.close();
    super.dispose();
  }

  void _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() => _limit += _limitIncrement);
    }
  }

  String _computeGroupChatId(String peerId) {
    if (currentUserId.isEmpty) return '';
    return currentUserId.compareTo(peerId) > 0
        ? '$currentUserId-$peerId'
        : '$peerId-$currentUserId';
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }

  void _handleBack() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => LoginHomeScreen(chat: "")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: hintColor,
            onPressed: _handleBack,
          ),
        ),
        centerTitle: true,
        title: Text(
          getTranslated(context, AppString.chats).toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: hintColor,
          ),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: _buildChatList(),
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: homeProvider.getStreamFireStore(
          FirestoreConstants.pathUserCollection, _limit),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId)
              .toList();

          if (docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: docs.length,
            controller: listScrollController,
            itemBuilder: (ctx, i) => _buildChatTile(ctx, docs[i]),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: loginButton),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: loginButton.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                size: 36, color: loginButton.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            getTranslated(context, AppString.no_user).toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: hintColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Patient conversations will appear here',
            style: TextStyle(
              fontSize: 13,
              color: passwordVisibility.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, DocumentSnapshot document) {
    final userChat = UserChat.fromDocument(document);
    final groupChatId = _computeGroupChatId(userChat.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (Utilities.isKeyboardShowing()) {
              Utilities.closeKeyboard(context);
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  peerId: userChat.id,
                  peerAvatar: userChat.photoUrl,
                  peerNickname: userChat.nickname,
                  token: userChat.token,
                  isNavigate: 'chatHome',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: groupChatId.isEmpty
                ? _buildSimpleTileContent(userChat)
                : StreamBuilder<DocumentSnapshot>(
                    stream:
                        chatProvider.getConversationStream(groupChatId),
                    builder: (ctx, convSnap) {
                      final data = convSnap.data?.data()
                          as Map<String, dynamic>?;
                      final lastMsg =
                          data?['lastMessage'] as String? ?? '';
                      final lastTime =
                          data?['lastTimestamp'] as String? ?? '';
                      final lastBy =
                          data?['lastBy'] as String? ?? '';
                      final unread =
                          (data?['unread_$currentUserId'] ?? 0) as int;

                      return Row(
                        children: [
                          _buildAvatar(userChat.photoUrl, 50),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userChat.nickname.isNotEmpty
                                            ? userChat.nickname
                                            : 'Patient',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: unread > 0
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: hintColor,
                                        ),
                                      ),
                                    ),
                                    if (lastTime.isNotEmpty)
                                      Text(
                                        _formatTime(lastTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: unread > 0
                                              ? loginButton
                                              : passwordVisibility,
                                          fontWeight: unread > 0
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMsg.isNotEmpty
                                            ? (lastBy == currentUserId
                                                ? 'You: $lastMsg'
                                                : lastMsg)
                                            : 'Tap to start chatting',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: unread > 0
                                              ? hintColor
                                              : passwordVisibility
                                                  .withOpacity(0.8),
                                          fontWeight: unread > 0
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    if (unread > 0) ...[
                                      const SizedBox(width: 8),
                                      _buildUnreadBadge(unread),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTileContent(UserChat userChat) {
    return Row(
      children: [
        _buildAvatar(userChat.photoUrl, 50),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userChat.nickname.isNotEmpty ? userChat.nickname : 'Patient',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: hintColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to start chatting',
                style: TextStyle(
                    fontSize: 13,
                    color: passwordVisibility.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded,
            color: passwordVisibility.withOpacity(0.5), size: 22),
      ],
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: loginButton,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAvatar(String url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: loginButton.withOpacity(0.15), width: 2),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _defaultAvatar(size),
              )
            : _defaultAvatar(size),
      ),
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      color: loginButton.withOpacity(0.08),
      child: Icon(Icons.person_rounded,
          size: size * 0.55, color: loginButton.withOpacity(0.5)),
    );
  }
}

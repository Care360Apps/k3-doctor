import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/chat/constants/firestore_constants.dart';
import 'package:doctro/chat/models/message_chat.dart';
import 'package:doctro/chat/providers/auth_provider.dart';
import 'package:doctro/chat/providers/chat_provider.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/screens/home%20page/login_home.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/widgets.dart';
import 'pages.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;
  final String token;
  final String isNavigate;

  const ChatPage({
    Key? key,
    required this.peerId,
    required this.peerAvatar,
    required this.peerNickname,
    required this.token,
    required this.isNavigate,
  }) : super(key: key);

  @override
  State createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  String currentUserId = '';
  String peerNickname = '';

  List<QueryDocumentSnapshot> listMessage = [];
  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId = '';

  File? galleryImageFile;
  File? cameraImageFile;
  bool isLoading = false;
  bool _authReady = false;

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    peerNickname = widget.peerNickname;
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    listScrollController.addListener(_scrollListener);
    _initAndRead();
    _resolvePeerNickname();
  }

  Future<void> _initAndRead() async {
    await authProvider.ensureFirebaseUser();
    if (mounted) {
      readLocal();
      setState(() => _authReady = true);
    }
  }

  void _resolvePeerNickname() async {
    if (peerNickname.trim().isNotEmpty &&
        peerNickname.toLowerCase() != 'null') return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirestoreConstants.pathUserCollection)
          .doc(widget.peerId)
          .get();
      final name = snap.get(FirestoreConstants.nickname);
      if (name != null && name.toString().trim().isNotEmpty && mounted) {
        setState(() => peerNickname = name.toString());
      }
    } catch (_) {}
  }

  void _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange &&
        _limit <= listMessage.length) {
      setState(() => _limit += _limitIncrement);
    }
  }

  void readLocal() {
    final uid = authProvider.getUserFirebaseId();
    if (uid != null && uid.isNotEmpty) currentUserId = uid;
    if (currentUserId.isEmpty) return;

    final newGroupId = currentUserId.compareTo(widget.peerId) > 0
        ? '$currentUserId-${widget.peerId}'
        : '${widget.peerId}-$currentUserId';

    if (kDebugMode) {
      print('ChatPage readLocal -> currentUserId=$currentUserId, peerId=${widget.peerId}, groupChatId=$newGroupId');
    }

    if (mounted) {
      setState(() => groupChatId = newGroupId);
    } else {
      groupChatId = newGroupId;
    }

    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: widget.peerId},
    );

    chatProvider.markAsRead(groupChatId, currentUserId);
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, widget.peerId);
      chatProvider.sendNotification(content, widget.token, currentUserId, type,
          widget.peerAvatar, peerNickname);
      if (listScrollController.hasClients) {
        listScrollController.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    }
  }

  bool isLastMessageLeft(int index) {
    return (index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0;
  }

  bool isLastMessageRight(int index) {
    return (index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) !=
                currentUserId) ||
        index == 0;
  }

  String _formatTimestamp(String timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday ${DateFormat('h:mm a').format(dt)}';
    if (diff.inDays < 7) return DateFormat('EEE h:mm a').format(dt);
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  void _handleBack() {
    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: null},
    );
    if (widget.isNavigate == 'chatHome') {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginHomeScreen(chat: "chat")));
    }
  }

  String _displayName() {
    if (peerNickname.trim().isNotEmpty && peerNickname.toLowerCase() != 'null') {
      return peerNickname;
    }
    return 'Patient';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: hintColor,
        onPressed: _handleBack,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _buildAvatar(widget.peerAvatar, 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(),
                  style: const TextStyle(
                    color: hintColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Patient',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            ? Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatar(size))
            : _defaultAvatar(size),
      ),
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      color: loginButton.withOpacity(0.08),
      child: Icon(Icons.person_rounded,
          size: size * 0.6, color: loginButton.withOpacity(0.5)),
    );
  }

  Widget _buildMessageList() {
    if (!_authReady || groupChatId.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: loginButton));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: chatProvider.getChatStream(groupChatId, _limit),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          listMessage = snapshot.data!.docs;
          if (listMessage.isEmpty) return _buildEmptyState();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: listMessage.length,
            reverse: true,
            controller: listScrollController,
            itemBuilder: (_, i) => _buildMessageItem(i, listMessage[i]),
          );
        }
        return const Center(
            child: CircularProgressIndicator(color: loginButton));
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
            getTranslated(context, AppString.no_message).toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: hintColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(
              fontSize: 13,
              color: passwordVisibility.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(int index, DocumentSnapshot document) {
    final msg = MessageChat.fromDocument(document);
    final isMe = msg.idFrom == currentUserId;
    final showTime = isMe ? isLastMessageRight(index) : isLastMessageLeft(index);

    return Padding(
      padding: EdgeInsets.only(bottom: showTime ? 16 : 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                if (isLastMessageLeft(index))
                  _buildAvatar(widget.peerAvatar, 28)
                else
                  const SizedBox(width: 28),
                const SizedBox(width: 8),
              ],
              Flexible(child: _buildBubble(msg, isMe)),
            ],
          ),
          if (showTime)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isMe ? 0 : 36,
                right: isMe ? 4 : 0,
              ),
              child: Text(
                _formatTimestamp(msg.timestamp),
                style: TextStyle(
                    color: passwordVisibility.withOpacity(0.6), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(MessageChat msg, bool isMe) {
    if (msg.type == TypeMessage.text) {
      return Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? loginButton : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            color: isMe ? Colors.white : hintColor,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      );
    } else if (msg.type == TypeMessage.image) {
      return GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => FullPhotoPage(url: msg.content))),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          child: Image.network(
            msg.content,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 220,
                height: 220,
                color: Colors.grey.shade100,
                child: const Center(
                    child: CircularProgressIndicator(color: loginButton)),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              width: 220,
              height: 220,
              color: Colors.grey.shade100,
              child: const Icon(Icons.broken_image_rounded,
                  size: 40, color: Colors.grey),
            ),
          ),
        ),
      );
    }
    return Image.asset('images/${msg.content}.gif',
        width: 100, height: 100, fit: BoxFit.cover);
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: loginButton.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.photo_library_rounded, size: 20),
                  color: loginButton,
                  padding: EdgeInsets.zero,
                  onPressed: _showImagePicker,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    style: const TextStyle(color: hintColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: getTranslated(context, AppString.type_message)
                          .toString(),
                      hintStyle: TextStyle(
                          color: passwordVisibility.withOpacity(0.7),
                          fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    onSubmitted: (_) => onSendMessage(
                        textEditingController.text, TypeMessage.text),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [loginButton, Color(0xFF0066CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: loginButton.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 20),
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  onPressed: () => onSendMessage(
                      textEditingController.text, TypeMessage.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose Image Source',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600, color: hintColor),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: getTranslated(context, AppString.choose_image_camera)
                        .toString(),
                    onTap: () {
                      Navigator.pop(ctx);
                      _getImageCamera();
                    },
                  ),
                  _imageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: getTranslated(context, AppString.choose_image_gallery)
                        .toString(),
                    onTap: () {
                      Navigator.pop(ctx);
                      _getImageGallery();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceOption(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: loginButton.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: loginButton),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: hintColor)),
        ],
      ),
    );
  }

  Future _getImageGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      galleryImageFile = File(picked.path);
      setState(() => isLoading = true);
      _uploadFile(galleryImageFile!, false);
    }
  }

  Future _getImageCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      cameraImageFile = File(picked.path);
      setState(() => isLoading = true);
      _uploadFile(cameraImageFile!, true);
    }
  }

  Future _uploadFile(File file, bool isCamera) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final snapshot = await chatProvider.uploadFile(file, fileName);
      final url = await snapshot.ref.getDownloadURL();
      if (mounted) {
        setState(() => isLoading = false);
        onSendMessage(url, TypeMessage.image);
      }
    } on FirebaseException catch (e) {
      if (mounted) setState(() => isLoading = false);
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }
}

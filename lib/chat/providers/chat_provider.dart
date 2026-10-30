import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/chat/constants/firestore_constants.dart';
import 'package:doctro/chat/models/message_chat.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/apis.dart';

class ChatProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  ChatProvider({required this.firebaseFirestore, required this.prefs, required this.firebaseStorage});

  String? getPref(String key) {
    return prefs.getString(key);
  }

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, dynamic> dataNeedUpdate) {
    return firebaseFirestore.collection(collectionPath).doc(docPath).set(dataNeedUpdate, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit) {
    return firebaseFirestore.collection(FirestoreConstants.pathMessageCollection).doc(groupChatId).collection(groupChatId).orderBy(FirestoreConstants.timestamp, descending: true).limit(limit).snapshots();
  }

  void sendMessage(String content, int type, String groupChatId, String currentUserId, String peerId) {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    DocumentReference documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(now);

    MessageChat messageChat = MessageChat(
      idFrom: currentUserId,
      idTo: peerId,
      timestamp: now,
      content: content,
      type: type,
    );

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(documentReference, messageChat.toJson());
    });

    firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .set({
      'lastMessage': type == TypeMessage.image ? '📷 Photo' : content,
      'lastTimestamp': now,
      'lastBy': currentUserId,
      'unread_$peerId': FieldValue.increment(1),
    }, SetOptions(merge: true));

    firebaseFirestore
        .collection(FirestoreConstants.pathUserCollection)
        .doc(peerId)
        .set({'totalUnread': FieldValue.increment(1)}, SetOptions(merge: true));
  }

  void markAsRead(String groupChatId, String currentUserId) {
    final convDoc = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId);

    convDoc.get().then((snap) {
      if (snap.exists) {
        final unread = (snap.data()?['unread_$currentUserId'] ?? 0) as int;
        if (unread > 0) {
          convDoc.set({'unread_$currentUserId': 0}, SetOptions(merge: true));
          firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(currentUserId)
              .set({
            'totalUnread': FieldValue.increment(-unread),
          }, SetOptions(merge: true));
        }
      }
    }).catchError((_) {});
  }

  Stream<DocumentSnapshot> getConversationStream(String groupChatId) {
    return firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .snapshots();
  }

  /// Opt-in staging path. Never send Firebase server keys from a client app.
  /// Requires OneSignal subscription IDs and authorization checks to be validated.
  Future<void> sendNotification(String content, String token, String userId,
      int type, String userImage, String userName) async {
    const backendPushEnabled = bool.fromEnvironment(
      'K3_BACKEND_PUSH_ENABLED', defaultValue: false,
    );
    if (!backendPushEnabled || token.trim().isEmpty ||
        token == 'N_A' || token == 'null') {
      return;
    }
    try {
      await RetroApi().dioData().post(
        '${Apis.baseUrl}send_message_to_patient_notification',
        data: {
          // Use generic push content to avoid exposing clinical data on lock screens.
          'content': type == TypeMessage.image ? 'New image message' : 'New chat message',
          'to_device_token': token,
        },
      );
    } catch (_) {
      // Best effort. Chat messages are stored separately in Firestore.
      // Do not log access tokens, recipient tokens, or message contents.
    }
  }
}

class TypeMessage {
  static const text = 0;
  static const image = 1;
  static const sticker = 2;
}

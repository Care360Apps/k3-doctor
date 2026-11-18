import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/chat/constants/firestore_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Status { uninitialized, authenticated, authenticating, authenticateError, authenticateCanceled }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  Status _status = Status.uninitialized;

  Status get status => _status;

  AuthProvider({
    required this.firebaseAuth,
    required this.prefs,
    required this.firebaseFirestore,
  });

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getUserFirebaseId() {
    return prefs.getString(FirestoreConstants.id);
  }
  bool check = false;
  /// Legacy clinician-password Firebase account creation is disabled.
  /// Only the Laravel-issued Firebase custom token may authorize clinical chat.
  @Deprecated('Use signInWithCustomToken with a backend-issued token.')
  Future<bool> handleSignIn({String? email, String? password}) async {
    _status = Status.authenticateError;
    notifyListeners();
    return false;
  }

  Future<void> handleSignOut() async {
    _status = Status.uninitialized;
    await firebaseAuth.signOut();
  }

  /// Ensure an active Firebase Auth session exists.
  /// Does NOT fall back to anonymous auth — users must sign in at login time
  /// via custom token or email/password.
  Future<bool> ensureFirebaseUser() async {
    try {
      User? user = firebaseAuth.currentUser;
      if (kDebugMode) {
        print('ensureFirebaseUser: currentUser=${user?.uid}');
      }

      // Only Firebase's persisted authenticated session is trusted. A user
      // without a session must sign in again instead of replaying a saved password.

      if (user == null) {
        if (kDebugMode) {
          print('ensureFirebaseUser: no session available — user must log in again');
        }
        return false;
      }

      await prefs.setString(FirestoreConstants.id, user.uid);

      _ensureFirestoreUserDoc(user.uid);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ensureFirebaseUser FAILED: $e');
      }
      return false;
    }
  }

  void _ensureFirestoreUserDoc(String uid) {
    final nickname = SharedPreferenceHelper.getString(Preferences.user_name);
    final photoUrl = SharedPreferenceHelper.getString(Preferences.chat_profile);
    final doctorId = SharedPreferenceHelper.getString(Preferences.doctorId);
    final userRole = SharedPreferenceHelper.getString(Preferences.user_role);
    final userType = (userRole.isNotEmpty && userRole != 'N_A') ? userRole : 'doctor';

    firebaseFirestore
        .collection(FirestoreConstants.pathUserCollection)
        .doc(uid)
        .set({
      FirestoreConstants.id: uid,
      FirestoreConstants.nickname: nickname == 'N_A' ? '' : nickname,
      FirestoreConstants.photoUrl: photoUrl == 'N_A' ? '' : photoUrl,
      FirestoreConstants.userType: userType,
      FirestoreConstants.doctorId: doctorId == 'N_A' ? '' : doctorId,
    }, SetOptions(merge: true)).catchError((e) {
      if (kDebugMode) {
        print('_ensureFirestoreUserDoc failed (non-fatal): $e');
      }
    });
  }

  /// Sign into Firebase using the custom token issued by our backend.
  /// Also writes / updates this user's document in the Firestore `users` collection.
  Future<bool> signInWithCustomToken({
    required String customToken,
    required String doctorAppId,
    required String nickname,
    required String photoUrl,
    String userType = 'doctor',
  }) async {
    _status = Status.authenticating;
    notifyListeners();

    try {
      final UserCredential cred = await _auth.signInWithCustomToken(customToken);
      final User? user = cred.user;
      if (user == null) {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }

      // Store Firebase UID in prefs IMMEDIATELY so the session is usable
      // even if the Firestore write below fails.
      await prefs.setString(FirestoreConstants.id, user.uid);
      await prefs.setString(FirestoreConstants.nickname, nickname);
      await prefs.setString(FirestoreConstants.photoUrl, photoUrl);
      await prefs.setString(FirestoreConstants.userType, userType);
      await prefs.setString(FirestoreConstants.doctorId, doctorAppId);

      try {
        final docRef = firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .doc(user.uid);
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          await docRef.set({
            FirestoreConstants.id: user.uid,
            FirestoreConstants.doctorId: doctorAppId,
            FirestoreConstants.nickname: nickname,
            FirestoreConstants.photoUrl: photoUrl,
            FirestoreConstants.userType: userType,
            FirestoreConstants.chattingWith: null,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          });
        } else {
          await docRef.update({
            FirestoreConstants.nickname: nickname,
            FirestoreConstants.photoUrl: photoUrl,
            FirestoreConstants.doctorId: doctorAppId,
          });
        }
      } catch (_) {
        // Non-fatal — Firebase Auth session is active even if the profile write fails.
      }

      _status = Status.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('signInWithCustomToken failed: $e');
      }
      _status = Status.authenticateError;
      notifyListeners();
      return false;
    }
  }
}

import '../../brand/care360_services_roadmap.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/chat/pages/chat_page.dart';
import 'package:doctro/chat/providers/auth_provider.dart' as provider;
import 'package:doctro/chat/providers/home_provider.dart';
import 'package:doctro/main.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/base_model.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/constant/common_function.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/model/appointment_history.dart' as history;
import 'package:doctro/model/today_appointment.dart';
import 'package:doctro/retrofit/server_error.dart';
import 'package:doctro/screens/home%20page/patient_information.dart';
import 'package:doctro/screens/videoCall/PhoneScreen.dart';
import 'package:doctro/screens/auth/SignIn.dart';
import '../setting/professional_availability.dart';
import '../../brand/care360_professional_quick_actions.dart';
import '../../brand/care360_professional_role.dart';
import '../appointment/doctor_practice_screen.dart';
import 'package:doctro/screens/subscription/Subscription.dart';
import 'package:doctro/screens/videoCall/video_Call.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:doctro/chat/constants/firestore_constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../../model/setting.dart';
class LoginHomeScreen extends StatefulWidget {
  final String? chat;

  LoginHomeScreen({
    this.chat,
  });

  @override
  _LoginHomeScreenState createState() => _LoginHomeScreenState();
}

class _LoginHomeScreenState extends State<LoginHomeScreen> {
  var appointment;

  //Set Loader
  Future? todayAppointment;
  Timer? timer;

  //Set Open Drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  //Set Preferences Data
  String? dName;
  String? dFullImage;
  int? isFilled;
  int? subscription;
  String? phone;

  String? approvalStatus;
  bool hideApprovedBanner = false;

  late HomeProvider homeProvider;
  late provider.AuthProvider authProvider;

  String messageImage = '';
  String messageName = '';
  String messageId = '';
  String token = '';
  String userToken = '';

  List<history.UpcomingAppointment> historyUpcoming = [];
  Future? historyFuture;

  //Search Data
  TextEditingController _search = TextEditingController();
  List<Today> _searchResult = [];
  List<Tomorrow> _tomorrowSearchResult = [];
  List<Upcoming> _upcomingSearchResult = [];

  List<String> _drawer = [];
  List<String> _drawerMenu = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Set Drawer Menu Item List
    final drawerHome = getTranslated(context, AppString.drawer_home) ?? 'Home';
    final drawerPayments = getTranslated(context, AppString.drawer_payments) ?? 'Payments';
    final drawerWithdrawal = getTranslated(context, AppString.drawer_withdrawal) ?? 'Withdrawal';
    final drawerCanceled = getTranslated(context, AppString.drawer_canceled_appointment) ?? 'Canceled';
    final drawerAppointments = getTranslated(context, AppString.drawer_appointments) ?? 'Appointments';
    final drawerChats = getTranslated(context, AppString.chats) ?? 'Chats';
    final drawerReview = getTranslated(context, AppString.drawer_review) ?? 'Review';
    final drawerNotification = getTranslated(context, AppString.drawer_notification) ?? 'Notifications';
    final drawerCallHistory = getTranslated(context, AppString.drawer_callHistory) ?? 'Call History';
    final drawerSchedule = getTranslated(context, AppString.drawer_schedule_timing) ?? 'Schedule Timings';
    final drawerNotes = getTranslated(context, AppString.drawer_notes) ?? 'Notes';
    final drawerSetting = getTranslated(context, AppString.drawer_setting) ?? 'Settings';
    final drawerLogout = getTranslated(context, AppString.drawer_logout) ?? 'Logout';

    _drawer = [
      drawerHome,
      drawerPayments,
      drawerWithdrawal,
      drawerCanceled,
      drawerAppointments,
      drawerChats,
      drawerReview,
      drawerNotification,
      drawerCallHistory,
      drawerSchedule,
      drawerNotes,
      drawerSetting,
      drawerLogout,
    ];

    _drawerMenu = [
      drawerHome,
      drawerPayments,
      drawerWithdrawal,
      drawerCanceled,
      drawerAppointments,
      drawerChats,
      drawerReview,
      drawerNotification,
      drawerCallHistory,
      drawerSchedule,
      drawerNotes,
      drawerSetting,
      drawerLogout,
    ];
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      settingRequest();
      await getOneSingleToken();
      todayAppointment = todayAppointmentsFunction();
      historyFuture = fetchHistoryUpcoming();
      dName = SharedPreferenceHelper.getString(Preferences.name);
      dFullImage = SharedPreferenceHelper.getString(Preferences.image);
      isFilled = SharedPreferenceHelper.getInt(Preferences.is_filled);
      subscription = SharedPreferenceHelper.getInt(Preferences.subscription_status);
      phone = SharedPreferenceHelper.getString(Preferences.phone_no);
      approvalStatus = SharedPreferenceHelper.getString(Preferences.approval_status);
      hideApprovedBanner = SharedPreferenceHelper.getBoolean(Preferences.hide_approved_banner);
    });
    Future.delayed(Duration(seconds: 5), () {
      if (FirebaseAuth.instance.currentUser != null) {
        homeProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, FirebaseAuth.instance.currentUser!.uid, {'pushToken': SharedPreferenceHelper.getString(Preferences.device_token)});
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Map<String, dynamic> dataValue = message.data;
        messageImage = dataValue['userImage'].toString();
        messageName = dataValue['userName'].toString();
        messageId = dataValue['userId'].toString();
        userToken = dataValue['userToken'].toString();

        if (widget.chat == "") {
          if (SharedPreferenceHelper.getString(Preferences.email).isNotEmpty) {
            Navigator.of(navigatorKey.currentContext!).pushReplacement(MaterialPageRoute(
                builder: (context) => ChatPage(
                      peerNickname: messageName,
                      peerAvatar: messageImage,
                      peerId: messageId,
                      token: userToken,
                      isNavigate: '',
                    )));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
          }
        }
      }
      Future.delayed(Duration(seconds: 5), () {
        if (FirebaseAuth.instance.currentUser != null) {
          homeProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, FirebaseAuth.instance.currentUser!.uid, {'pushToken': SharedPreferenceHelper.getString(Preferences.device_token)});
        }
      });
    });

    authProvider = Provider.of<provider.AuthProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);

    SharedPreferenceHelper.setBoolean(
        Preferences.notificationPermissionDialog, OneSignal.Notifications.permission == false ? true : false);
  }

  //Set Double Tap to exit value //
  DateTime? currentBackPressTime;

  //Set Double Tap exit //
  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null || now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(gravity: ToastGravity.BOTTOM, msg: getTranslated(context, AppString.tap_again_to_exit_app).toString());
      return Future.value(false);
    }
    return Future.value(true);
  }

  // Add List Data //
  List<Today> todayAppointments = [];
  List<Tomorrow> tomorrowAppointments = [];
  List<Upcoming> upcomingAppointments = [];

  bool todayView = false;
  bool tomorrowView = false;
  bool upcomingView = false;

  // Set MediaQuery Size //
  late double width;
  late double height;

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    final drawerHome = getTranslated(context, AppString.drawer_home).toString();
    final drawerPayments = getTranslated(context, AppString.drawer_payments).toString();
    final drawerWithdrawal = getTranslated(context, AppString.drawer_withdrawal) ?? 'Withdrawal';
    final drawerCanceled = getTranslated(context, AppString.drawer_canceled_appointment).toString();
    final drawerAppointments = getTranslated(context, AppString.drawer_appointments).toString();
    final drawerReview = getTranslated(context, AppString.drawer_review).toString();
    final drawerNotification = getTranslated(context, AppString.drawer_notification).toString();
    final drawerCallHistory = getTranslated(context, AppString.drawer_callHistory).toString();
    final drawerSchedule = getTranslated(context, AppString.drawer_schedule_timing).toString();
    final drawerNotes = getTranslated(context, AppString.drawer_notes) ?? 'Notes';
    final drawerSetting = getTranslated(context, AppString.drawer_setting).toString();
    final drawerChats = getTranslated(context, AppString.chats).toString();
    final drawerLogout = getTranslated(context, AppString.drawer_logout).toString();

    Color colorWithOpacity(Color color, double opacity) {
      return color.withValues(alpha: opacity);
    }

    String statusLabel(String? statusText, {String? fallback}) {
      final value = (statusText ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
      return (fallback ?? '').trim();
    }

    bool hasStatus(String? statusText, {String? fallback}) {
      return statusLabel(statusText, fallback: fallback).isNotEmpty;
    }

    Color statusColorFor(String? statusText) {
      final value = (statusText ?? '').toLowerCase();
      if (value.contains('cancel')) {
        return statusCancel;
      }
      if (value.contains('upcoming') || value.contains('pending')) {
        return orange;
      }
      if (value.contains('complete') || value.contains('approve')) {
        return status;
      }
      return hintColor;
    }

    String _visitTypeLabel(String? visitType) {
      if (visitType == null || visitType.isEmpty) return '';
      if (visitType == 'home_visit') return getTranslated(context, AppString.visit_type_home_visit).toString();
      return getTranslated(context, AppString.visit_type_video_call).toString();
    }

    Widget buildStatusChip(String? statusText, {String? fallback}) {
      final label = statusLabel(statusText, fallback: fallback);
      if (label.isEmpty) {
        return const SizedBox.shrink();
      }
      final chipColor = statusColorFor(label);
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colorWhite),
        ),
      );
    }

    void handleDrawerSelection(String label) {
      if (label == drawerHome) {
        Navigator.popAndPushNamed(context, "loginHome");
      } else if (label == drawerPayments) {
        Navigator.popAndPushNamed(context, 'payment');
      } else if (label == drawerWithdrawal) {
        Navigator.popAndPushNamed(context, 'withdrawal');
      } else if (label == drawerCanceled) {
        Navigator.popAndPushNamed(context, 'cancelAppoitmentRoutes');
      } else if (label == drawerAppointments) {
        Navigator.popAndPushNamed(context, 'AppointmentHistoryScreen');
      } else if (label == drawerReview) {
        Navigator.popAndPushNamed(context, 'rateAndReviewRoutes');
      } else if (label == drawerNotification) {
        Navigator.popAndPushNamed(context, 'notifications');
      } else if (label == drawerCallHistory) {
        Navigator.popAndPushNamed(context, 'VideoCallHistory');
      } else if (label == drawerSchedule) {
        Navigator.popAndPushNamed(context, 'Schedule Timings');
      } else if (label == drawerNotes) {
        Navigator.popAndPushNamed(context, 'Notes');
      } else if (label == drawerSetting) {
        Navigator.popAndPushNamed(context, 'Settings');
      } else if (label == drawerChats) {
        Navigator.popAndPushNamed(context, 'ChatHome');
      } else if (label == drawerLogout) {
        showAlertDialog(context);
      }
    }

    IconData drawerIcon(String label) {
      if (label == drawerHome) return Icons.home_rounded;
      if (label == drawerPayments) return Icons.payments_rounded;
      if (label == drawerWithdrawal) return Icons.account_balance_wallet_rounded;
      if (label == drawerCanceled) return Icons.event_busy_rounded;
      if (label == drawerAppointments) return Icons.event_note_rounded;
      if (label == drawerReview) return Icons.star_rate_rounded;
      if (label == drawerNotification) return Icons.notifications_rounded;
      if (label == drawerCallHistory) return Icons.call_rounded;
      if (label == drawerSchedule) return Icons.schedule_rounded;
      if (label == drawerNotes) return Icons.note_alt_rounded;
      if (label == drawerSetting) return Icons.settings_rounded;
      if (label == drawerChats) return Icons.chat_bubble_outline_rounded;
      if (label == drawerLogout) return Icons.logout_rounded;
      return Icons.circle;
    }

    Widget buildDrawerList(List<String> items) {
      final chatUid = authProvider.getUserFirebaseId() ?? '';

      return ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (context, index) => SizedBox(height: 10),
        itemBuilder: (context, index) {
          final label = items[index];
          final isLogout = label == drawerLogout;
          final isChat = label == drawerChats;
          final iconColor = isLogout ? red : loginButton;
          final textColor = isLogout ? red : hintColor;

          Widget trailing = Icon(Icons.chevron_right_rounded, color: passwordVisibility);
          if (isChat && chatUid.isNotEmpty) {
            trailing = StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirestoreConstants.pathUserCollection)
                  .doc(chatUid)
                  .snapshots(),
              builder: (ctx, snap) {
                final total =
                    ((snap.data?.data() as Map<String, dynamic>?)?['totalUnread'] ?? 0) as int;
                if (total > 0) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          total > 99 ? '99+' : '$total',
                          style: TextStyle(color: colorWhite, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: passwordVisibility),
                    ],
                  );
                }
                return Icon(Icons.chevron_right_rounded, color: passwordVisibility);
              },
            );
          }

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => handleDrawerSelection(label),
            child: Container(
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: divider),
                boxShadow: [
                  BoxShadow(
                    color: colorWithOpacity(black, 0.06),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: colorWithOpacity(iconColor, 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(drawerIcon(label), color: iconColor, size: 20),
                ),
                title: Text(
                  label,
                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                trailing: trailing,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                horizontalTitleGap: 12,
              ),
            ),
          );
        },
      );
    }

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('professional-availability-shortcut'),
          backgroundColor: const Color(0xFF08785E),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.location_on_outlined),
          label: const Text('Nearby Care'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const ProfessionalAvailabilityScreen(),
          )),
        ),
        drawer: Drawer(
          child: Container(
            color: back,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: divider),
                      boxShadow: [
                        BoxShadow(
                          color: colorWithOpacity(black, 0.06),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colorWithOpacity(loginButton, 0.4), width: 2),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: '$dFullImage',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg", fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$dName',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(fontSize: 16, color: hintColor, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "$phone",
                                style: TextStyle(fontSize: 12, color: passwordVisibility),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.popAndPushNamed(context, "profile");
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tabBar,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/edit.svg',
                              height: height * 0.022,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: subscription == -1 ? buildDrawerList(_drawerMenu) : buildDrawerList(_drawer),
                  ),
                ],
              ),
            ),
          ),
        ),
        appBar: PreferredSize(
            preferredSize: Size(20, 170),
            child: SafeArea(
                top: true,
                child: Container(
                  padding: EdgeInsets.only(bottom: height * 0.01),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorWithOpacity(loginButton, 0.12),
                        colorWithOpacity(tabBar, 0.2),
                        back,
                      ],
                    ),
                  ),
                  child: Column(children: [
                    Container(
                      margin: EdgeInsets.only(left: width * 0.06, right: width * 0.04, top: height * 0.01),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getTranslated(context, AppString.upcoming_title).toString(),
                            style: TextStyle(fontSize: 20, color: hintColor, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: colorWhite,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colorWithOpacity(black, 0.06),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                _scaffoldKey.currentState!.openDrawer();
                              },
                              icon: SvgPicture.asset(
                                "assets/icons/dMenuBar.svg",
                                height: 16.0,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: height * 0.012),
                      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                      child: Container(
                        height: height * 0.058,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: divider),
                          boxShadow: [
                            BoxShadow(
                              color: colorWithOpacity(black, 0.08),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _search,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: getTranslated(context, AppString.home_search_hint).toString(),
                                  hintStyle: TextStyle(
                                    fontSize: width * 0.042,
                                    color: colorWithOpacity(hintColor, 0.4),
                                  ),
                                ),
                                onChanged: onSearchTextChanged,
                                textAlign: TextAlign.left,
                              ),
                            ),
                            Container(
                              height: 34,
                              width: 34,
                              decoration: BoxDecoration(
                                color: colorWithOpacity(loginButton, 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/icons/dSearch.svg',
                                  height: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ))),
        body: RefreshIndicator(
          onRefresh: () async {
            await todayAppointmentsFunction();
            await fetchHistoryUpcoming();
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            child: FutureBuilder(
                future: todayAppointment,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        FocusScope.of(context).requestFocus(new FocusNode());
                      },
                      child: subscription == 0
                          ? dialog()
                          : Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (Care360ProfessionalRole.canCreatePrescription(SharedPreferenceHelper.getString(Preferences.user_role)))
                                    Card(margin: const EdgeInsets.all(16), child: ListTile(
                                      leading: const Icon(Icons.local_hospital_outlined),
                                      title: const Text('My medical practice'),
                                      subtitle: const Text('Profile, schedule and clinical consultations'),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const DoctorPracticeScreen())),
                                    )),
                                  Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: ListTile(leading: const Icon(Icons.school_outlined), title: const Text('Professional services'), subtitle: const Text('Training & CPD, Workforce and organizations roadmap'), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const Care360ServicesRoadmap(professional: true))))),
                                  Care360ProfessionalQuickActions(
                                    onOpen: (destination) {
                                      switch (destination) {
                                        case Care360ProfessionalDestination.appointments:
                                          Navigator.pushNamed(context, 'AppointmentHistoryScreen');
                                          break;
                                        case Care360ProfessionalDestination.schedule:
                                          Navigator.pushNamed(context, 'Schedule Timings');
                                          break;
                                        case Care360ProfessionalDestination.notes:
                                          Navigator.pushNamed(context, 'Notes');
                                          break;
                                        case Care360ProfessionalDestination.messages:
                                          Navigator.pushNamed(context, 'ChatHome');
                                          break;
                                      }
                                    },
                                  ),
                                  isFilled == 0
                                      ? GestureDetector(
                                          onTap: () => Navigator.pushNamed(context, "profile"),
                                          child: Container(
                                              width: width * 1.0,
                                              margin: EdgeInsets.only(left: width * 0.06, right: width * 0.06, bottom: height * 0.02),
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: colorWithOpacity(purple, 0.06),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: colorWithOpacity(purple, 0.25)),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: colorWithOpacity(purple, 0.08),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.info_outline,
                                                      size: 20,
                                                      color: purple,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          getTranslated(context, AppString.home_please_update_profile).toString(),
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: purple,
                                                            fontWeight: FontWeight.w600,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        SizedBox(height: 6),
                                                        Text(
                                                          getTranslated(context, AppString.home_click_here).toString(),
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: purple,
                                                            fontWeight: FontWeight.w600,
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )))
                                      : Container(),
                                  if (isFilled == 1 && (approvalStatus ?? '').toLowerCase() == 'pending')
                                    Container(
                                      width: width * 1.0,
                                      margin: EdgeInsets.only(left: width * 0.06, right: width * 0.06, bottom: height * 0.02),
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: colorWithOpacity(Colors.orange, 0.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: colorWithOpacity(Colors.orange, 0.25)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: colorWithOpacity(Colors.orange, 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.hourglass_top,
                                              size: 20,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              getTranslated(context, AppString.home_account_pending).toString(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.orange[900],
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isFilled == 1 &&
                                      (approvalStatus ?? '').toLowerCase() == 'approved' &&
                                      hideApprovedBanner == false)
                                    Container(
                                      width: width * 1.0,
                                      margin: EdgeInsets.only(left: width * 0.06, right: width * 0.06, bottom: height * 0.02),
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: colorWithOpacity(Colors.green, 0.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: colorWithOpacity(Colors.green, 0.25)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: colorWithOpacity(Colors.green, 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check_circle_outline,
                                              size: 20,
                                              color: Colors.green,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              getTranslated(context, AppString.home_account_approved).toString(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.green[900],
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                hideApprovedBanner = true;
                                              });
                                              SharedPreferenceHelper.setBoolean(Preferences.hide_approved_banner, true);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 8.0, top: 2),
                                              child: Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (historyUpcoming.isNotEmpty)
                                    _buildHistoryUpcomingSection(),
                                  todayAppointments.length < 1 && tomorrowAppointments.length < 1 && upcomingAppointments.length < 1 && historyUpcoming.isEmpty
                                      ? Container(
                                          child: Container(height: height * 0.6, child: Image.asset("assets/images/no-data.png")),
                                        )
                                      : Column(
                                          children: [
                                            todayAppointments.length > 0
                                                ? Container(
                                                    margin: EdgeInsets.symmetric(horizontal: width * 0.05),
                                                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: colorWithOpacity(tabBar, 0.6),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(color: divider),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          getTranslated(context, AppString.home_title).toString(),
                                                          style: TextStyle(fontSize: 16, color: hintColor, fontWeight: FontWeight.w600),
                                                        ),
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: colorWithOpacity(loginButton, 0.12),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            getTranslated(context, AppString.payment_total).toString() + " ${todayAppointments.length}",
                                                            style: TextStyle(fontSize: width * 0.030, color: hintColor, fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : Container(),
                                            SizedBox(height: 10),
                                            _search.text.isNotEmpty
                                                ? _searchResult.length > 0
                                                    ? ListView.builder(
                                                        shrinkWrap: true,
                                                        physics: NeverScrollableScrollPhysics(),
                                                        itemCount: _searchResult.length,
                                                        itemBuilder: (context, index) {
                                                          final statusText = _searchResult[index].appointmentStatus;
                                                          return Column(
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    margin: EdgeInsets.only(left: width * 0.06, right: width * 0.02),
                                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                decoration: BoxDecoration(
                                                                  color: colorWithOpacity(tabBar, 0.6),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(color: divider),
                                                                ),
                                                                child: Text(
                                                                  _searchResult[index].time!,
                                                                  style: TextStyle(fontSize: 13, color: hintColor, fontWeight: FontWeight.w600),
                                                                ),
                                                                  ),
                                                                  Expanded(
                                                                    child: Container(
                                                                        margin: EdgeInsets.only(left: width * 0.02, right: width * 0.02),
                                                                        height: 100,
                                                                        width: width * 0.70,
                                                                        child: GestureDetector(
                                                                          onTap: () {
                                                                            Navigator.push(context, MaterialPageRoute(builder: (context) => patientDetailsScreen(id: _searchResult[index].id)));
                                                                          },
                                                                          child: Card(
                                                                              elevation: 1.5,
                                                                              shadowColor: colorWithOpacity(black, 0.08),
                                                                              margin: EdgeInsets.zero,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(16.0),
                                                                                side: BorderSide(color: divider),
                                                                              ),
                                                                              clipBehavior: Clip.antiAlias,
                                                                              child: Column(children: <Widget>[
                                                                                Container(
                                                                                  child: ListTile(
                                                                                    isThreeLine: true,
                                                                                    leading: SizedBox(
                                                                                      height: height * 0.20,
                                                                                      width: width * 0.15,
                                                                                      child: ClipRRect(
                                                                                        borderRadius: BorderRadius.circular(12),
                                                                                        child: Container(decoration: new BoxDecoration(image: new DecorationImage(fit: BoxFit.fitHeight, image: NetworkImage(_searchResult[index].user!.fullImage!)))),
                                                                                      ),
                                                                                    ),
                                                                                    title: Container(
                                                                                      alignment: AlignmentDirectional.topStart,
                                                                                      margin: EdgeInsets.only(
                                                                                        top: height * 0.01,
                                                                                      ),
                                                                                      child: Text(
                                                                                        _searchResult[index].patientName!,
                                                                                        style: TextStyle(fontSize: 16.0),
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        maxLines: 1,
                                                                                      ),
                                                                                    ),
                                                                                    trailing: Container(
                                                                                        child: Column(
                                                                                          mainAxisSize: MainAxisSize.min,
                                                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                                                          children: [
                                                                                            Text(
                                                                                              SharedPreferenceHelper.getString(Preferences.currency_symbol) + _searchResult[index].amount.toString(),
                                                                                              style: TextStyle(fontSize: 16, color: hintColor),
                                                                                            ),
                                                                                            SizedBox(height: 6),
                                                                                            buildStatusChip(statusText, fallback: 'PENDING'),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    subtitle: Column(
                                                                                      children: <Widget>[
                                                                                        Container(
                                                                                            alignment: AlignmentDirectional.topStart,
                                                                                            child: Text(
                                                                                              getTranslated(context, AppString.home_age_data).toString() + " : " + _searchResult[index].age.toString(),
                                                                                              style: TextStyle(fontSize: 12, color: hintColor),
                                                                                            )),
                                                                                        if (_searchResult[index].hospital!.name != null)
                                                                                          Container(
                                                                                            alignment: AlignmentDirectional.topStart,
                                                                                            child: Text(
                                                                                              getTranslated(context, AppString.hospital_title).toString() + _searchResult[index].hospital!.name!,
                                                                                              style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                              maxLines: 2,
                                                                                            ),
                                                                                          ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                )
                                                                              ])),
                                                                        )),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      )
                                                    : SizedBox()
                                                : ListView.builder(
                                                    physics: NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    scrollDirection: Axis.vertical,
                                                    itemCount: todayView == false && todayAppointments.length > 3 ? 3 : todayAppointments.length,
                                                    itemBuilder: (context, index) {
                                                      final statusText = todayAppointments[index].appointmentStatus;
                                                      return Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                margin: EdgeInsets.only(left: width * 0.06, right: width * 0.02),
                                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                decoration: BoxDecoration(
                                                                  color: colorWithOpacity(tabBar, 0.6),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(color: divider),
                                                                ),
                                                                child: Text(
                                                                  todayAppointments[index].time!,
                                                                  style: TextStyle(fontSize: 13, color: hintColor, fontWeight: FontWeight.w600),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Container(
                                                                    margin: EdgeInsets.only(left: width * 0.02, right: width * 0.02),
                                                                    width: width * 0.70,
                                                                    child: GestureDetector(
                                                                      onTap: () {
                                                                        Navigator.push(context, MaterialPageRoute(builder: (context) => patientDetailsScreen(id: todayAppointments[index].id)));
                                                                      },
                                                                      child: Card(
                                                                          elevation: 1.5,
                                                                          shadowColor: colorWithOpacity(black, 0.08),
                                                                          margin: EdgeInsets.zero,
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(16.0),
                                                                            side: BorderSide(color: divider),
                                                                          ),
                                                                          clipBehavior: Clip.antiAlias,
                                                                          child: Padding(
                                                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                                                            child: Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                ClipRRect(
                                                                                  borderRadius: BorderRadius.circular(10),
                                                                                  child: SizedBox(
                                                                                    height: 48,
                                                                                    width: 48,
                                                                                    child: CachedNetworkImage(
                                                                                      imageUrl: todayAppointments[index].user!.fullImage ?? '',
                                                                                      fit: BoxFit.cover,
                                                                                      placeholder: (_, __) => Container(color: colorWithOpacity(loginButton, 0.08), child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
                                                                                      errorWidget: (_, __, ___) => Container(color: colorWithOpacity(loginButton, 0.08), child: Icon(Icons.person, color: hintColor, size: 24)),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                SizedBox(width: 12),
                                                                                Expanded(
                                                                                  child: Column(
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        todayAppointments[index].patientName!,
                                                                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: hintColor),
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                      ),
                                                                                      SizedBox(height: 2),
                                                                                      Text(
                                                                                        getTranslated(context, AppString.home_age_data).toString() + " " + todayAppointments[index].age.toString(),
                                                                                        style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                      ),
                                                                                      if (todayAppointments[index].hospital!.name != null) ...[
                                                                                        SizedBox(height: 1),
                                                                                        Text(
                                                                                          todayAppointments[index].hospital!.name!,
                                                                                          style: TextStyle(fontSize: 11, color: passwordVisibility),
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          maxLines: 1,
                                                                                        ),
                                                                                      ],
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                Column(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                                                  children: [
                                                                                    Text(
                                                                                      SharedPreferenceHelper.getString(Preferences.currency_symbol) != "N_A"
                                                                                          ? SharedPreferenceHelper.getString(Preferences.currency_symbol)! + todayAppointments[index].amount.toString()
                                                                                          : todayAppointments[index].amount.toString(),
                                                                                      style: TextStyle(fontSize: 14, color: hintColor, fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                    SizedBox(height: 4),
                                                                                    buildStatusChip(statusText, fallback: 'PENDING'),
                                                                                    if (_visitTypeLabel(todayAppointments[index].visitType).isNotEmpty) ...[
                                                                                      SizedBox(height: 2),
                                                                                      Text(
                                                                                        _visitTypeLabel(todayAppointments[index].visitType),
                                                                                        style: TextStyle(fontSize: 10, color: passwordVisibility),
                                                                                      ),
                                                                                    ],
                                                                                  ],
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          )),
                                                                    )),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                            SizedBox(height: 10),
                                            todayAppointments.length <= 3
                                                ? Container()
                                                : Visibility(
                                                    visible: todayView == true ? false : true,
                                                    child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            todayView = true;
                                                          });
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: colorWithOpacity(loginButton, 0.12),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            getTranslated(context, AppString.view_more).toString(),
                                                            style: TextStyle(fontSize: 12, color: hintColor, fontWeight: FontWeight.w600),
                                                          ),
                                                        )),
                                                  ),
                                            SizedBox(height: 10),
                                            historyUpcoming.isEmpty && tomorrowAppointments.length > 0
                                                ? Container(
                                                    margin: EdgeInsets.symmetric(horizontal: width * 0.05),
                                                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: colorWithOpacity(tabBar, 0.6),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(color: divider),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          getTranslated(context, AppString.tomorrow_appointment).toString(),
                                                          style: TextStyle(fontSize: 16, color: hintColor, fontWeight: FontWeight.w600),
                                                        ),
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: colorWithOpacity(loginButton, 0.12),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            getTranslated(context, AppString.payment_total).toString() + " ${tomorrowAppointments.length}",
                                                            style: TextStyle(fontSize: width * 0.030, color: hintColor, fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : Container(),
                                            historyUpcoming.isEmpty && _search.text.isNotEmpty
                                                ? _tomorrowSearchResult.length > 0
                                                    ? ListView.builder(
                                                        shrinkWrap: true,
                                                        physics: NeverScrollableScrollPhysics(),
                                                        itemCount: _tomorrowSearchResult.length,
                                                        itemBuilder: (context, i) {
                                                          final statusText = _tomorrowSearchResult[i].appointmentStatus;
                                                          final statusLabelText = statusLabel(statusText, fallback: 'UPCOMING');
                                                          final statusColor = statusColorFor(statusLabelText);
                                                          final cardTint = hasStatus(statusText, fallback: 'UPCOMING') ? colorWithOpacity(statusColor, 0.08) : colorWhite;
                                                          return Column(
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    margin: EdgeInsets.only(left: width * 0.06, right: width * 0.02),
                                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                decoration: BoxDecoration(
                                                                  color: colorWithOpacity(tabBar, 0.6),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(color: divider),
                                                                ),
                                                                child: Text(
                                                                  _tomorrowSearchResult[i].time!,
                                                                  style: TextStyle(fontSize: 13, color: hintColor, fontWeight: FontWeight.w600),
                                                                ),
                                                                  ),
                                                                  Expanded(
                                                                    child: Container(
                                                                        margin: EdgeInsets.only(left: width * 0.02, right: width * 0.02),
                                                                        height: 100,
                                                                        width: width * 0.70,
                                                                        child: GestureDetector(
                                                                          onTap: () {
                                                                            Navigator.push(context, MaterialPageRoute(builder: (context) => patientDetailsScreen(id: _tomorrowSearchResult[i].id)));
                                                                          },
                                                                          child: Card(
                                                                              elevation: 1.5,
                                                                              shadowColor: colorWithOpacity(black, 0.08),
                                                                              color: cardTint,
                                                                              margin: EdgeInsets.zero,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(16.0),
                                                                                side: BorderSide(color: divider),
                                                                              ),
                                                                              clipBehavior: Clip.antiAlias,
                                                                              child: Column(children: <Widget>[
                                                                                Container(
                                                                                  child: ListTile(
                                                                                    isThreeLine: true,
                                                                                    leading: SizedBox(
                                                                                      height: height * 0.20,
                                                                                      width: width * 0.15,
                                                                                      child: ClipRRect(
                                                                                        borderRadius: BorderRadius.circular(12),
                                                                                        child:
                                                                                            Container(decoration: new BoxDecoration(image: new DecorationImage(fit: BoxFit.fitHeight, image: NetworkImage(_tomorrowSearchResult[i].user!.fullImage!)))),
                                                                                      ),
                                                                                    ),
                                                                                    title: Container(
                                                                                      alignment: AlignmentDirectional.topStart,
                                                                                      margin: EdgeInsets.only(
                                                                                        top: height * 0.01,
                                                                                      ),
                                                                                      child: Text(
                                                                                        _tomorrowSearchResult[i].patientName!,
                                                                                        style: TextStyle(fontSize: 16.0),
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        maxLines: 1,
                                                                                      ),
                                                                                    ),
                                                                                    trailing: Container(
                                                                                        child: Column(
                                                                                          mainAxisSize: MainAxisSize.min,
                                                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                                                          children: [
                                                                                            Text(
                                                                                              SharedPreferenceHelper.getString(Preferences.currency_symbol) + _tomorrowSearchResult[i].amount.toString(),
                                                                                              style: TextStyle(fontSize: 16, color: hintColor),
                                                                                            ),
                                                                                            SizedBox(height: 6),
                                                                                            buildStatusChip(statusText, fallback: 'UPCOMING'),
                                                                                          if (_visitTypeLabel(_tomorrowSearchResult[i].visitType).isNotEmpty)
                                                                                            Padding(
                                                                                              padding: EdgeInsets.only(top: 4),
                                                                                              child: Text(_visitTypeLabel(_tomorrowSearchResult[i].visitType), style: TextStyle(fontSize: 11, color: hintColor)),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    subtitle: Column(
                                                                                      children: <Widget>[
                                                                                        Container(
                                                                                            alignment: AlignmentDirectional.topStart,
                                                                                            child: Text(
                                                                                              getTranslated(context, AppString.home_age_data).toString() + " : " + _tomorrowSearchResult[i].age.toString(),
                                                                                              style: TextStyle(fontSize: 12, color: hintColor),
                                                                                            )),
                                                                                        if (_tomorrowSearchResult[i].hospital!.name != null)
                                                                                          Container(
                                                                                            alignment: AlignmentDirectional.topStart,
                                                                                            child: Text(
                                                                                              getTranslated(context, AppString.hospital_title).toString() + _tomorrowSearchResult[i].hospital!.name!,
                                                                                              style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                              maxLines: 2,
                                                                                            ),
                                                                                          ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                )
                                                                              ])),
                                                                        )),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      )
                                                    : SizedBox()
                                                : historyUpcoming.isEmpty
                                                    ? ListView.builder(
                                                    physics: NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    scrollDirection: Axis.vertical,
                                                    itemCount: tomorrowView == false && tomorrowAppointments.length > 3 ? 3 : tomorrowAppointments.length,
                                                    itemBuilder: (context, index) {
                                                      final statusText = tomorrowAppointments[index].appointmentStatus;
                                                      return Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                margin: EdgeInsets.only(left: width * 0.06, right: width * 0.02),
                                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                decoration: BoxDecoration(
                                                                  color: colorWithOpacity(tabBar, 0.6),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(color: divider),
                                                                ),
                                                                child: Text(
                                                                  tomorrowAppointments[index].time!,
                                                                  style: TextStyle(fontSize: 13, color: hintColor, fontWeight: FontWeight.w600),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Container(
                                                                    margin: EdgeInsets.only(left: width * 0.02, right: width * 0.02),
                                                                    height: 100,
                                                                    width: width * 0.70,
                                                                    child: GestureDetector(
                                                                      onTap: () {
                                                                        Navigator.push(context, MaterialPageRoute(builder: (context) => patientDetailsScreen(id: tomorrowAppointments[index].id)));
                                                                      },
                                                                      child: Card(
                                                                          elevation: 1.5,
                                                                          shadowColor: colorWithOpacity(black, 0.08),
                                                                          margin: EdgeInsets.zero,
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(16.0),
                                                                            side: BorderSide(color: divider),
                                                                          ),
                                                                          clipBehavior: Clip.antiAlias,
                                                                          child: Column(children: <Widget>[
                                                                            Container(
                                                                              child: ListTile(
                                                                                isThreeLine: true,
                                                                                leading: SizedBox(
                                                                                  height: height * 0.20,
                                                                                  width: width * 0.15,
                                                                                  child: ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                    child: Container(decoration: new BoxDecoration(image: new DecorationImage(fit: BoxFit.fitHeight, image: NetworkImage(tomorrowAppointments[index].user!.fullImage!)))),
                                                                                  ),
                                                                                ),
                                                                                title: Container(
                                                                                  alignment: AlignmentDirectional.topStart,
                                                                                  margin: EdgeInsets.only(top: height * 0.01),
                                                                                  child: Text(tomorrowAppointments[index].patientName!, style: TextStyle(fontSize: 16.0), overflow: TextOverflow.ellipsis),
                                                                                ),
                                                                                trailing: SharedPreferenceHelper
                                                                                            .getString(Preferences
                                                                                                .currency_symbol) !=
                                                                                        "N_A"
                                                                                    ? Column(
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                                                        children: [
                                                                                          Text(
                                                                                            SharedPreferenceHelper.getString(Preferences.currency_symbol) + tomorrowAppointments[index].amount.toString(),
                                                                                            style: TextStyle(fontSize: 16, color: hintColor),
                                                                                          ),
                                                                                          SizedBox(height: 6),
                                                                                          buildStatusChip(statusText, fallback: 'UPCOMING'),
                                                                                          if (_visitTypeLabel(tomorrowAppointments[index].visitType).isNotEmpty)
                                                                                            Padding(
                                                                                              padding: EdgeInsets.only(top: 4),
                                                                                              child: Text(_visitTypeLabel(tomorrowAppointments[index].visitType), style: TextStyle(fontSize: 11, color: hintColor)),
                                                                                            ),
                                                                                        ],
                                                                                      )
                                                                                    : Column(
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                                                        children: [
                                                                                          Text(
                                                                                            tomorrowAppointments[index].amount.toString(),
                                                                                            style: TextStyle(fontSize: 16, color: hintColor),
                                                                                          ),
                                                                                          SizedBox(height: 6),
                                                                                          buildStatusChip(statusText, fallback: 'UPCOMING'),
                                                                                          if (_visitTypeLabel(tomorrowAppointments[index].visitType).isNotEmpty)
                                                                                            Padding(
                                                                                              padding: EdgeInsets.only(top: 4),
                                                                                              child: Text(_visitTypeLabel(tomorrowAppointments[index].visitType), style: TextStyle(fontSize: 11, color: hintColor)),
                                                                                            ),
                                                                                        ],
                                                                                      ),
                                                                                subtitle: Column(
                                                                                  children: <Widget>[
                                                                                    Container(
                                                                                        alignment: AlignmentDirectional.topStart,
                                                                                        child: Text(
                                                                                          getTranslated(context, AppString.home_age_data).toString() + " : " + tomorrowAppointments[index].age.toString(),
                                                                                          style: TextStyle(fontSize: 12, color: hintColor),
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                        )),
                                                                                    if (tomorrowAppointments[index].hospital!.name != null)
                                                                                      Container(
                                                                                        alignment: AlignmentDirectional.topStart,
                                                                                        child: Text(
                                                                                          getTranslated(context, AppString.hospital_title).toString() + ' ' + tomorrowAppointments[index].hospital!.name!,
                                                                                          style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          maxLines: 2,
                                                                                        ),
                                                                                      ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            )
                                                                          ])),
                                                                    )),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                    )
                                                    : SizedBox.shrink(),
                                            SizedBox(height: 10),
                                            tomorrowAppointments.length <= 3
                                                ? Container()
                                                : Visibility(
                                                    visible: tomorrowView == true ? false : true,
                                                    child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            tomorrowView = true;
                                                          });
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: colorWithOpacity(loginButton, 0.12),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            getTranslated(context, AppString.view_more).toString(),
                                                            style: TextStyle(fontSize: 12, color: hintColor, fontWeight: FontWeight.w600),
                                                          ),
                                                        )),
                                                  ),
                                            SizedBox(height: 10),
                                            historyUpcoming.isEmpty && upcomingAppointments.length > 0
                                                ? Container(
                                                    margin: EdgeInsets.symmetric(horizontal: width * 0.05),
                                                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: colorWithOpacity(tabBar, 0.6),
                                                      borderRadius: BorderRadius.circular(14),
                                                      border: Border.all(color: divider),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          getTranslated(context, AppString.up_coming_appointment).toString(),
                                                          style: TextStyle(fontSize: 16, color: hintColor, fontWeight: FontWeight.w600),
                                                        ),
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: colorWithOpacity(loginButton, 0.12),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            getTranslated(context, AppString.payment_total).toString() + " ${upcomingAppointments.length}",
                                                            style: TextStyle(fontSize: width * 0.030, color: hintColor, fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : Container(),
                                            SizedBox(height: 10),
                                            _search.text.isNotEmpty
                                                ? _upcomingSearchResult.length > 0
                                                    ? ListView.builder(
                                                        shrinkWrap: true,
                                                        physics: NeverScrollableScrollPhysics(),
                                                        itemCount: _upcomingSearchResult.length,
                                                        itemBuilder: (context, i) {
                                                          final statusText = _upcomingSearchResult[i].appointmentStatus;
                                                          return Column(
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    margin: EdgeInsets.only(left: width * 0.06, right: width * 0.02),
                                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                decoration: BoxDecoration(
                                                                  color: colorWithOpacity(tabBar, 0.6),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(color: divider),
                                                                ),
                                                                child: Text(
                                                                  _upcomingSearchResult[i].time!,
                                                                  style: TextStyle(fontSize: 13, color: hintColor, fontWeight: FontWeight.w600),
                                                                ),
                                                                  ),
                                                                  Expanded(
                                                                    child: Container(
                                                                        margin: EdgeInsets.only(left: width * 0.02, right: width * 0.02),
                                                                        height: 100,
                                                                        width: width * 0.70,
                                                                        child: GestureDetector(
                                                                          onTap: () {
                                                                            Navigator.push(context, MaterialPageRoute(builder: (context) => patientDetailsScreen(id: _upcomingSearchResult[i].id)));
                                                                          },
                                                                          child: Card(
                                                                              elevation: 1.5,
                                                                              shadowColor: colorWithOpacity(black, 0.08),
                                                                              margin: EdgeInsets.zero,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(16.0),
                                                                                side: BorderSide(color: divider),
                                                                              ),
                                                                              clipBehavior: Clip.antiAlias,
                                                                              child: Column(children: <Widget>[
                                                                                Container(
                                                                                  child: ListTile(
                                                                                    isThreeLine: true,
                                                                                    leading: SizedBox(
                                                                                      height: height * 0.20,
                                                                                      width: width * 0.15,
                                                                                      child: ClipRRect(
                                                                                        borderRadius: BorderRadius.circular(12),
                                                                                        child:
                                                                                            Container(decoration: new BoxDecoration(image: new DecorationImage(fit: BoxFit.fitHeight, image: NetworkImage(_upcomingSearchResult[i].user!.fullImage!)))),
                                                                                      ),
                                                                                    ),
                                                                                    title: Container(
                                                                                      alignment: AlignmentDirectional.topStart,
                                                                                      margin: EdgeInsets.only(
                                                                                        top: height * 0.01,
                                                                                      ),
                                                                                      child: Text(
                                                                                        _upcomingSearchResult[i].patientName!,
                                                                                        style: TextStyle(fontSize: 16.0),
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        maxLines: 1,
                                                                                      ),
                                                                                    ),
                                                                                    trailing: Container(
                                                                                        child: Column(
                                                                                          mainAxisSize: MainAxisSize.min,
                                                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                                                          children: [
                                                                                            Text(
                                                                                              SharedPreferenceHelper.getString(Preferences.currency_symbol) + _upcomingSearchResult[i].amount.toString(),
                                                                                              style: TextStyle(fontSize: 16, color: hintColor),
                                                                                            ),
                                                                                            SizedBox(height: 6),
                                                                                            buildStatusChip(statusText, fallback: 'UPCOMING'),
                                                                                            if (_visitTypeLabel(_upcomingSearchResult[i].visitType).isNotEmpty)
                                                                                              Padding(
                                                                                                padding: EdgeInsets.only(top: 4),
                                                                                                child: Text(_visitTypeLabel(_upcomingSearchResult[i].visitType), style: TextStyle(fontSize: 11, color: hintColor)),
                                                                                              ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    subtitle: Column(
                                                                                      children: <Widget>[
                                                                                        Container(
                                                                                            alignment: AlignmentDirectional.topStart,
                                                                                            child: Text(
                                                                                              getTranslated(context, AppString.home_age_data).toString() + " : " + _upcomingSearchResult[i].age.toString(),
                                                                                              style: TextStyle(fontSize: 12, color: hintColor),
                                                                                            )),
                                                                                        if (_upcomingSearchResult[i].hospital!.name != null)
                                                                                          Container(
                                                                                            alignment: AlignmentDirectional.topStart,
                                                                                            child: Text(
                                                                                              getTranslated(context, AppString.hospital_title).toString() + _upcomingSearchResult[i].hospital!.name!,
                                                                                              style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                              maxLines: 2,
                                                                                            ),
                                                                                          ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                )
                                                                              ])),
                                                                        )),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      )
                                                    : SizedBox()
                                                : ListView.builder(
                                                    physics: NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    scrollDirection: Axis.vertical,
                                                    itemCount: upcomingView == false && upcomingAppointments.length > 3 ? 3 : upcomingAppointments.length,
                                                    itemBuilder: (context, index) {
                                                      final statusText = upcomingAppointments[index].appointmentStatus;
                                                      return Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Column(
                                                                children: [
                                                                  Container(
                                                                    margin: EdgeInsets.only(left: width * 0.06, right: width * 0.02),
                                                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                    decoration: BoxDecoration(
                                                                      color: colorWithOpacity(tabBar, 0.6),
                                                                      borderRadius: BorderRadius.circular(12),
                                                                      border: Border.all(color: divider),
                                                                    ),
                                                                    child: Text(
                                                                      DateFormat.MMMd().format(DateTime.parse(upcomingAppointments[index].date!)),
                                                                      style: TextStyle(fontSize: 12, color: hintColor, fontWeight: FontWeight.w600),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    margin: EdgeInsets.only(left: width * 0.06, right: width * 0.02),
                                                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                    decoration: BoxDecoration(
                                                                      color: colorWithOpacity(tabBar, 0.6),
                                                                      borderRadius: BorderRadius.circular(12),
                                                                      border: Border.all(color: divider),
                                                                    ),
                                                                    child: Text(
                                                                      upcomingAppointments[index].time!,
                                                                      style: TextStyle(fontSize: 12, color: hintColor, fontWeight: FontWeight.w600),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Expanded(
                                                                child: Container(
                                                                    margin: EdgeInsets.only(left: width * 0.02, right: width * 0.02),
                                                                    height: 100,
                                                                    width: width * 0.70,
                                                                    child: GestureDetector(
                                                                      onTap: () {
                                                                        Navigator.push(context, MaterialPageRoute(builder: (context) => patientDetailsScreen(id: upcomingAppointments[index].id)));
                                                                      },
                                                                      child: Card(
                                                                          elevation: 1.5,
                                                                          shadowColor: colorWithOpacity(black, 0.08),
                                                                          margin: EdgeInsets.zero,
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(16.0),
                                                                            side: BorderSide(color: divider),
                                                                          ),
                                                                          clipBehavior: Clip.antiAlias,
                                                                          child: Column(children: <Widget>[
                                                                            Container(
                                                                              child: ListTile(
                                                                                isThreeLine: true,
                                                                                leading: SizedBox(
                                                                                  height: height * 0.20,
                                                                                  width: width * 0.15,
                                                                                  child: ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                    child: Container(decoration: new BoxDecoration(image: new DecorationImage(fit: BoxFit.fitHeight, image: NetworkImage(upcomingAppointments[index].user!.fullImage!)))),
                                                                                  ),
                                                                                ),
                                                                                title: Container(
                                                                                  alignment: AlignmentDirectional.topStart,
                                                                                  margin: EdgeInsets.only(top: height * 0.01),
                                                                                  child: Text(upcomingAppointments[index].patientName!, style: TextStyle(fontSize: 16.0), overflow: TextOverflow.ellipsis),
                                                                                ),
                                                                                trailing: SharedPreferenceHelper
                                                                                            .getString(Preferences
                                                                                                .currency_symbol) !=
                                                                                        "N_A"
                                                                                    ? Column(
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                                                        children: [
                                                                                          Text(
                                                                                            SharedPreferenceHelper.getString(Preferences.currency_symbol) + upcomingAppointments[index].amount.toString(),
                                                                                            style: TextStyle(fontSize: 16, color: hintColor),
                                                                                          ),
                                                                                          SizedBox(height: 6),
                                                                                          buildStatusChip(statusText, fallback: 'UPCOMING'),
                                                                                          if (_visitTypeLabel(upcomingAppointments[index].visitType).isNotEmpty)
                                                                                            Padding(
                                                                                              padding: EdgeInsets.only(top: 4),
                                                                                              child: Text(_visitTypeLabel(upcomingAppointments[index].visitType), style: TextStyle(fontSize: 11, color: hintColor)),
                                                                                            ),
                                                                                        ],
                                                                                      )
                                                                                    : Column(
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                                                        children: [
                                                                                          Text(
                                                                                            upcomingAppointments[index].amount.toString(),
                                                                                            style: TextStyle(fontSize: 16, color: hintColor),
                                                                                          ),
                                                                                          SizedBox(height: 6),
                                                                                          buildStatusChip(statusText, fallback: 'UPCOMING'),
                                                                                          if (_visitTypeLabel(upcomingAppointments[index].visitType).isNotEmpty)
                                                                                            Padding(
                                                                                              padding: EdgeInsets.only(top: 4),
                                                                                              child: Text(_visitTypeLabel(upcomingAppointments[index].visitType), style: TextStyle(fontSize: 11, color: hintColor)),
                                                                                            ),
                                                                                        ],
                                                                                      ),
                                                                                subtitle: Column(
                                                                                  children: <Widget>[
                                                                                    Container(
                                                                                        alignment: AlignmentDirectional.topStart,
                                                                                        child: Text(
                                                                                          getTranslated(context, AppString.home_age_data).toString() + " : " + upcomingAppointments[index].age.toString(),
                                                                                          style: TextStyle(fontSize: 12, color: hintColor),
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                        )),
                                                                                    if (upcomingAppointments[index].hospital!.name != null)
                                                                                      Container(
                                                                                        alignment: AlignmentDirectional.topStart,
                                                                                        child: Text(
                                                                                          getTranslated(context, AppString.hospital_title).toString() + ' ' + upcomingAppointments[index].hospital!.name!,
                                                                                          style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          maxLines: 2,
                                                                                        ),
                                                                                      ),
                                                                                    Container(
                                                                                      alignment: AlignmentDirectional.topStart,
                                                                                      margin: EdgeInsets.only(top: 6),
                                                                                      child: buildStatusChip(statusText, fallback: 'UPCOMING'),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            )
                                                                          ])),
                                                                    )),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                            SizedBox(height: 10),
                                            upcomingAppointments.length <= 3
                                                ? Container()
                                                : Visibility(
                                                    visible: upcomingView == true ? false : true,
                                                    child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            upcomingView = true;
                                                          });
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: colorWithOpacity(loginButton, 0.12),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            getTranslated(context, AppString.view_more).toString(),
                                                            style: TextStyle(fontSize: 12, color: hintColor, fontWeight: FontWeight.w600),
                                                          ),
                                                        )),
                                                  ),
                                            SizedBox(height: 10),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                    );
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryUpcomingSection() {
    Color colorWithOpacity(Color color, double opacity) {
      return color.withValues(alpha: opacity);
    }

    String visitTypeLabel(String? visitType) {
      if (visitType == null || visitType.isEmpty) return '';
      if (visitType == 'home_visit') return getTranslated(context, AppString.visit_type_home_visit).toString();
      return getTranslated(context, AppString.visit_type_video_call).toString();
    }

    Color _statusColor(String? appointmentStatus) {
      final upper = (appointmentStatus ?? '').toUpperCase();
      final pendingLabel = getTranslated(context, AppString.status_pending).toString();
      final cancelLabel = getTranslated(context, AppString.status_cancel).toString();
      if (upper == pendingLabel) return colorWithOpacity(hintColor, 0.6);
      if (upper == cancelLabel) return statusCancel;
      return status;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(width * 0.06, 4, width * 0.06, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: colorWithOpacity(loginButton, 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.event_note_rounded, color: loginButton, size: 18),
                  ),
                  SizedBox(width: 10),
                  Text(
                    getTranslated(context, AppString.up_coming_appointment).toString(),
                    style: TextStyle(fontSize: 16, color: hintColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, 'AppointmentHistoryScreen'),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorWithOpacity(loginButton, 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getTranslated(context, AppString.home_show_all).toString(),
                    style: TextStyle(fontSize: 12, color: loginButton, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            itemCount: historyUpcoming.length,
            itemBuilder: (context, index) {
              final a = historyUpcoming[index];
              final sColor = _statusColor(a.appointmentStatus);
              final statusText = (a.appointmentStatus ?? '').toUpperCase();

              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => patientDetailsScreen(id: a.id)));
                },
                child: Container(
                width: width * 0.78,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: colorWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorWithOpacity(divider, 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: colorWithOpacity(black, 0.06),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colorWithOpacity(loginButton, 0.2), width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: a.user?.fullImage != null && a.user!.fullImage!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: a.user!.fullImage!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: colorWithOpacity(loginButton, 0.06),
                                        child: Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: colorWithOpacity(loginButton, 0.06),
                                        child: Icon(Icons.person, color: hintColor, size: 24),
                                      ),
                                    )
                                  : Container(
                                      color: colorWithOpacity(loginButton, 0.06),
                                      child: Icon(Icons.person, color: hintColor, size: 24),
                                    ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.patientName ?? '-',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: hintColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  a.treatment ?? '-',
                                  style: TextStyle(fontSize: 12, color: passwordVisibility),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorWithOpacity(sColor, 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              statusText.isEmpty ? '-' : statusText,
                              style: TextStyle(color: sColor, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorWithOpacity(tabBar, 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: loginButton),
                            SizedBox(width: 6),
                            Text(
                              '${a.date ?? '-'}  ${a.time ?? '-'}',
                              style: TextStyle(fontSize: 12, color: hintColor, fontWeight: FontWeight.w600),
                            ),
                            Spacer(),
                            if (visitTypeLabel(a.visitType).isNotEmpty) ...[
                              Icon(
                                a.visitType == 'home_visit' ? Icons.home_rounded : Icons.videocam_rounded,
                                size: 14,
                                color: loginButton,
                              ),
                              SizedBox(width: 4),
                              Text(
                                visitTypeLabel(a.visitType),
                                style: TextStyle(fontSize: 11, color: loginButton, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          if (a.hospital?.name != null && a.hospital!.name!.isNotEmpty) ...[
                            Icon(Icons.local_hospital_rounded, size: 13, color: passwordVisibility),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                a.hospital!.name!,
                                style: TextStyle(fontSize: 11, color: passwordVisibility),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (a.doctorName != null && a.doctorName!.isNotEmpty) ...[
                            SizedBox(width: 8),
                            Icon(Icons.person_outline_rounded, size: 13, color: passwordVisibility),
                            SizedBox(width: 4),
                            Text(
                              a.doctorName!,
                              style: TextStyle(fontSize: 11, color: passwordVisibility),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Future<BaseModel<TodayAppointment>> todayAppointmentsFunction() async {
    TodayAppointment response;

    try {
      todayAppointments.clear();
      tomorrowAppointments.clear();
      upcomingAppointments.clear();

      response = await RestClient(RetroApi().dioData()).todayAppointments();

      setState(() {
        if (response.data!.today!.isNotEmpty) {
          response.data!.today!.sort((a, b) =>
              DateFormat("yyyy-MM-dd h:mm a").parse(DateTime.now().toString().split(" ")[0] + " " + a.time!.toUpperCase()).compareTo(DateFormat("yyyy-MM-dd h:mm a").parse(DateTime.now().toString().split(" ")[0] + " " + b.time!.toUpperCase())));
          todayAppointments.addAll(response.data!.today!);
        }

        if (response.data!.tomorrow!.isNotEmpty) {
          response.data!.tomorrow!.sort((a, b) =>
              DateFormat("yyyy-MM-dd h:mm a").parse(DateTime.now().toString().split(" ")[0] + " " + a.time!.toUpperCase()).compareTo(DateFormat("yyyy-MM-dd h:mm a").parse(DateTime.now().toString().split(" ")[0] + " " + b.time!.toUpperCase())));
          tomorrowAppointments.addAll(response.data!.tomorrow!);
        }

        if (response.data!.upcoming!.isNotEmpty) {
          response.data!.upcoming!.sort((a, b) =>
              DateFormat("yyyy-MM-dd h:mm a").parse(DateTime.now().toString().split(" ")[0] + " " + a.time!.toUpperCase()).compareTo(DateFormat("yyyy-MM-dd h:mm a").parse(DateTime.now().toString().split(" ")[0] + " " + b.time!.toUpperCase())));
          upcomingAppointments.addAll(response.data!.upcoming!);
        }
      });
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<void> fetchHistoryUpcoming() async {
    try {
      final response = await RestClient(RetroApi().dioData())
          .appointmentHistoryScreenRequest();
      if (mounted) {
        setState(() {
          historyUpcoming.clear();
          if (response.data?.upcomingAppointment != null) {
            historyUpcoming.addAll(response.data!.upcomingAppointment!);
          }
        });
      }
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
    }
  }

  Future<void> logoutUser() async {
    await SharedPreferenceHelper.clearPrefSecurely();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (BuildContext context) => SignIn()),
      ModalRoute.withName('SignIn'),
    );
  }

  Widget dialog() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.1),
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(40),
      ),
      width: width * 0.8,
      child: Container(
        height: 280,
        child: Align(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: width * 0.15,
                child: SizedBox.expand(
                  child: Image.asset(
                    'assets/images/alert.png',
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                  child: Text(
                getTranslated(context, AppString.home_subscription_deActive).toString(),
                style: TextStyle(fontSize: 20, color: hintColor, decoration: TextDecoration.none),
                textAlign: TextAlign.center,
              )),
              GestureDetector(
                onTap: () {
                  SubSubscription();
                },
                child: Container(
                    margin: EdgeInsets.only(top: height * 0.02),
                    child: Text(
                      getTranslated(context, AppString.home_please_active_plan).toString(),
                      style: TextStyle(fontSize: 14, color: darkGrey, decoration: TextDecoration.none),
                      textAlign: TextAlign.center,
                    )),
              ),
              SizedBox(
                height: 10,
              ),
              Container(margin: EdgeInsets.only(left: 12, right: 12), child: ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, "subscription"), child: Text(getTranslated(context, AppString.home_activate_subscription).toString())))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getOneSingleToken() async {
    try {
      OneSignal.Notifications.addClickListener((event) async {
        if (event.result.actionId == "") {
        } else if (event.result.actionId == "decline") {
          setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoCall(
                  callEnd: true,
                  id: event.notification.additionalData!["id"],
                ),
              ),
            );
          });

          setState(() {});
        } else if (event.result.actionId == "accept") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCall(
                callEnd: false,
                id: event.notification.additionalData!["id"],
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PhoneScreen(event.notification.additionalData)),
          );
        }
      });
    } catch (error) {
      print(error);
    }
  }

  showAlertDialog(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: loginButton.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: loginButton,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  getTranslated(context, AppString.logout_button).toString(),
                  style: TextStyle(
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getTranslated(context, AppString.are_you_sure_logout).toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width * 0.038,
                    color: subheading,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: divider),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          getTranslated(context, AppString.cancel_button).toString(),
                          style: TextStyle(
                            fontSize: width * 0.038,
                            color: hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: loginButton,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          CommonFunction.checkNetwork().then((value) {
                            if (value == true) {
                              Navigator.pop(dialogContext);
                              logoutUser();
                            }
                          });
                        },
                        child: Text(
                          getTranslated(context, AppString.logout_button).toString(),
                          style: TextStyle(
                            fontSize: width * 0.038,
                            color: colorWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    _tomorrowSearchResult.clear();
    _upcomingSearchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    todayAppointments.forEach((appointmentData) {
      if (appointmentData.patientName!.toLowerCase().contains(text.toLowerCase())) {
        _searchResult.add(appointmentData);
      }
    });

    tomorrowAppointments.forEach((tomorrowData) {
      if (tomorrowData.patientName!.toLowerCase().contains(text.toLowerCase())) {
        _tomorrowSearchResult.add(tomorrowData);
      }
    });
    upcomingAppointments.forEach((upcomingData) {
      if (upcomingData.patientName!.toLowerCase().contains(text.toLowerCase())) {
        _upcomingSearchResult.add(upcomingData);
      }
    });

    setState(() {});
  }

  Future<BaseModel<Setting>> settingRequest() async {
    Setting response;
    try {
      response = await RestClient(RetroApi().dioData()).settingRequest();
      setState(() {
        if (response.data?.agoraAppId != null) {
        SharedPreferenceHelper.setString(Preferences.agoraAppId, response.data!.agoraAppId!);
        }
        if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
          if (response.data!.stripePublicKey != null) {
            SharedPreferenceHelper.setString(Preferences.stripPublicKey, response.data!.stripePublicKey!);
          }

          if (response.data!.flutterwaveKey != null) {
            SharedPreferenceHelper.setString(Preferences.flutterWave_key, response.data!.flutterwaveKey!);
          }

          if (response.data!.paystackPublicKey != null) {
            SharedPreferenceHelper.setString(Preferences.payStack_public_key, response.data!.paystackPublicKey!);
          }

          if (response.data!.razorKey != null) {
            SharedPreferenceHelper.setString(Preferences.razor_key, response.data!.razorKey!);
          }

          if (response.data!.paypalProducationKey != null) {
            SharedPreferenceHelper.setString(Preferences.payPal_production_key, response.data!.paypalProducationKey!);
          }

          if (response.data!.paypalSandboxKey != null) {
            SharedPreferenceHelper.setString(Preferences.payPal_sandbox_key, response.data!.paypalSandboxKey!);
          }

          if (response.data!.paypalClientId != null) {
            SharedPreferenceHelper.setString(Preferences.paypal_client_key, response.data!.paypalClientId!);
          }

          if (response.data!.currencySymbol != null) {
            SharedPreferenceHelper.setString(Preferences.currency_symbol, response.data!.currencySymbol!);
          }

          if (response.data!.currencyCode != null) {
            SharedPreferenceHelper.setString(Preferences.currency_code, response.data!.currencyCode!);
          }

          if (response.data!.doctorAppId != null) {
            setState(() {
              SharedPreferenceHelper.setString(Preferences.doctorAppId, response.data!.doctorAppId!);
            });
          }
        }
      });
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}

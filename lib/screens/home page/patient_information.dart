import 'dart:collection';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/chat/providers/home_provider.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/brand/care360_professional_role.dart';
import 'package:doctro/model/AllMedicines.dart';
import 'package:doctro/model/DoctorStatusChange.dart';
import 'package:doctro/model/appointment_details.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/base_model.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/pdf_creation/report_pdf.dart';
import 'package:doctro/retrofit/server_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:full_screen_image_null_safe/full_screen_image_null_safe.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../VideoCall/overlay_service.dart';
import '../../chat/constants/firestore_constants.dart';
import '../../chat/models/user_chat.dart';
import '../../chat/pages/chat_page.dart';
import '../../chat/providers/auth_provider.dart' as chatAuth;
import '../videoCall/video_Call.dart';

class patientDetailsScreen extends StatefulWidget {
  final int? id;

  patientDetailsScreen({this.id});

  @override
  _patientDetailsScreenState createState() => _patientDetailsScreenState();
}

//Pass Medicine list in pdf
List medicineData = [];
List<Map<String, dynamic>> listOfMedicine = [];

//Add Medicine List
List<String> medicineReq = [];

class _patientDetailsScreenState extends State<patientDetailsScreen> with TickerProviderStateMixin {
  bool get _canPrescribe => Care360ProfessionalRole.canCreatePrescription(
    SharedPreferenceHelper.getString(Preferences.user_role),
  );
  //Set Loader
  Future? appointmentDetail;

  //Pdf Pass Data
  String? valueDays;
  bool? alertValueFirst = false;
  bool? alertValueSecond = false;
  bool? alertValueThird = false;

  //alert dialog validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  //set high/width using mediaQuery
  double? width;
  late double height;

  //Set List for Report Image
  List<String> reportImages = [];

  //set hide show approve and cancel button
  bool hideButton = true;

  //Add Medicine Data dialog
  TextEditingController _days = TextEditingController();
  String? selectedMedicineValue;

  //Show Signal Appointment Details
  int? id;
  int? userId;
  int? age;
  double? amount;
  String? phoneNo = "";
  String? name = "";
  String? appointmentId = "";
  String? patientAddress = "";
  String date = "";
  String? illness = "";
  String? note = "";
  String? drugEffect = "";
  String? time = "";
  String? fullImage = "";
  String? appointment = "";
  String? appointmentStatus = "";
  String? visitType = "";
  String? pdf = "";
  String? appointmentDateRaw = "";
  late HomeProvider homeProvider;
  int isInsured = 0;
  String policyInsurerName = "";
  String policyNumber = "";

  void initState() {
    super.initState();
    homeProvider = Provider.of(context, listen: false);
    // Ensure Firebase Auth is active so the Firestore stream doesn't get permission-denied.
    Provider.of<chatAuth.AuthProvider>(context, listen: false).ensureFirebaseUser();
    id = widget.id;
    appointmentDetail = appointmentDetails();
    listOfMedicine.clear();
    allMedicinesRequest();
  }

  Map<String, String> body = {};

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    homeProvider = Provider.of(context, listen: false);
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    Color colorWithOpacity(Color color, double opacity) {
      return color.withValues(alpha: opacity);
    }
    String safeText(String? value) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isEmpty ? '-' : trimmed;
    }

    String formatStatus(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) {
        return '-';
      }
      return trimmed[0].toUpperCase() + trimmed.substring(1);
    }

    Color statusBadgeColor(String? value) {
      final key = (value ?? '').toLowerCase();
      if (key == 'cancel' || key == 'canceled' || key == 'cancelled') {
        return statusCancel;
      }
      if (key == 'pending') {
        return hintColor;
      }
      if (key == 'approve' || key == 'approved' || key == 'complete') {
        return status;
      }
      return loginButton;
    }

    Widget sectionCard({required Widget child, EdgeInsets? margin}) {
      return Container(
        margin: margin ?? EdgeInsets.symmetric(horizontal: width! * 0.06, vertical: height * 0.008),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divider),
          boxShadow: [
            BoxShadow(
              color: colorWithOpacity(black, 0.06),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    Widget infoRow({required IconData icon, required String title, required String value, int maxLines = 2}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: colorWithOpacity(loginButton, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: loginButton),
          ),
          SizedBox(width: 12),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: passwordVisibility, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  safeText(value),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: hintColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget sectionHeader({required IconData icon, required String title}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: colorWithOpacity(loginButton, 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: loginButton),
          ),
          SizedBox(width: 10),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              title,
              style: TextStyle(fontSize: 16, color: hintColor, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    Widget sectionBodyText(String text) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorWithOpacity(tabBar, 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: divider),
        ),
        child: Text(
          safeText(text),
          style: TextStyle(fontSize: 14.5, color: passwordVisibility, height: 1.4),
        ),
      );
    }

    final tabs = [
      Tab(
        text: getTranslated(context, AppString.patient_information).toString(),
      ),
      Tab(
        text: getTranslated(context, AppString.patient_illness).toString(),
      ),
      Tab(
        text: _canPrescribe ? getTranslated(context, AppString.doctor_prescription).toString()
          : 'Prescriptions (doctor only)',
      ),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(width! * 0.3, height * 0.08),
        child: SafeArea(
          top: true,
          child: Container(
              margin: EdgeInsets.zero,
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: EdgeInsets.only(right: width! * 0.04),
                  decoration: BoxDecoration(
                    color: colorWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorWithOpacity(black, 0.08),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_ios, size: 18, color: hintColor),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              )),
        ),
      ),
      body: DefaultTabController(
        length: tabs.length,
        child: FutureBuilder(
            future: appointmentDetail,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SingleChildScrollView(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    child: Column(
                      children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: width! * 0.06, vertical: height * 0.01),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: divider),
                          boxShadow: [
                            BoxShadow(
                              color: colorWithOpacity(black, 0.08),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext bc) {
                                        return SafeArea(
                                          child: Container(
                                            child: new Wrap(
                                              children: <Widget>[
                                                new ListTile(
                                                  leading: new Icon(Icons.phone_in_talk),
                                                  title: new Text(
                                                    getTranslated(context, "call_text").toString(),
                                                  ),
                                                  onTap: () {
                                                    if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
                                                      Navigator.of(context).pop();
                                                      launchUrl(Uri.parse("tel:$phoneNo"));
                                                    } else {
                                                      Navigator.of(context).pop();
                                                    }
                                                  },
                                                ),
                                                if (visitType != 'home_visit')
                                                  new ListTile(
                                                    leading: new Icon(Icons.videocam),
                                                    title: new Text(
                                                      getTranslated(context, "video_call").toString(),
                                                    ),
                                                    onTap: () {
                                                      setState(
                                                        () {
                                                          if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
                                                            Navigator.of(context).pop();
                                                            _addVideoOverlay(context);
                                                          } else {
                                                            Navigator.of(context).pop();
                                                          }
                                                        },
                                                      );
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: colorWithOpacity(loginButton, 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/icons/call_dialler.svg',
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                if (patientAddress != null && patientAddress!.trim().isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      final encoded = Uri.encodeComponent(patientAddress!);
                                      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
                                      launchUrl(uri);
                                    },
                                    child: Container(
                                      height: 42,
                                      width: 42,
                                      decoration: BoxDecoration(
                                        color: colorWithOpacity(loginButton, 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Icon(Icons.map_outlined, size: 20, color: loginButton),
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () {
                                    if (body['peerId'] == null || body['peerId']!.isEmpty) {
                                      Fluttertoast.showToast(
                                        msg: 'Chat is not available for this patient yet.',
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => ChatPage(
                                                  peerId: body['peerId']!,
                                                  peerAvatar: body['peerAvatar'] ?? '',
                                                  peerNickname: body['nickName'] ?? '',
                                                  token: body['token'] ?? '',
                                                  isNavigate: 'chatHome',
                                                )));
                                  },
                                  child: Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: colorWithOpacity(loginButton, 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/icons/message_dialler.svg',
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: 120,
                              height: 120,
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorWithOpacity(loginButton, 0.12),
                                border: Border.all(color: colorWithOpacity(loginButton, 0.35), width: 2),
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  alignment: Alignment.center,
                                  imageUrl: '$fullImage',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg", fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '$name',
                              style: TextStyle(fontSize: 20, color: hintColor, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              getTranslated(context,AppString. information_booking_id).toString() + '$appointmentId',
                              style: TextStyle(fontSize: 13, color: passwordVisibility),
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: homeProvider.getStreamFireStoreSpecificUser(FirestoreConstants.pathUserCollection, 1, userId.toString()),
                        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasData) {
                            if ((snapshot.data?.docs.length ?? 0) > 0) {
                              UserChat userChat = UserChat.fromDocument(snapshot.data!.docs[0]);
                              body = {"peerId": userChat.id, "nickName": userChat.nickname, "peerAvatar": userChat.photoUrl, "token": userChat.token};
                              return SizedBox();
                            } else {
                              return SizedBox();
                            }
                          } else {
                            return SizedBox();
                          }
                        },
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: width! * 0.06, vertical: height * 0.01),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(16),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    getTranslated(context, AppString.information_amount).toString(),
                                    style: TextStyle(fontSize: 13, color: hintColor, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    SharedPreferenceHelper.getString(Preferences.currency_symbol) + (amount?.toStringAsFixed(2) ?? '0.0'),
                                    style: TextStyle(fontSize: 15, color: hintColor, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 36, width: 1, color: divider),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    getTranslated(context, AppString.information_date).toString(),
                                    style: TextStyle(fontSize: 13, color: hintColor, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$date',
                                    style: TextStyle(fontSize: 15, color: hintColor, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 36, width: 1, color: divider),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    getTranslated(context, AppString.information_appointment).toString(),
                                    style: TextStyle(fontSize: 13, color: hintColor, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "$appointment",
                                    style: TextStyle(fontSize: 15, color: hintColor, fontWeight: FontWeight.w600),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      new Container(
                        margin: EdgeInsets.symmetric(horizontal: width! * 0.06, vertical: height * 0.01),
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorWithOpacity(tabBar, 0.7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: divider),
                        ),
                        child: new TabBar(
                          labelColor: loginButton,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: colorWhite,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: colorWithOpacity(black, 0.08),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          unselectedLabelColor: hintColor,
                          unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          tabs: tabs,
                        ),
                      ),
                      new Container(
                        height: height * 0.54,
                        child: new TabBarView(
                          children: [
                            ///tab 1
                            SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              physics: AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  hideButton == false
                                      ? sectionCard(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Title + status chip in the same row
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  sectionHeader(
                                                    icon: Icons.event_available,
                                                    title: getTranslated(context, AppString.information_appointment_status).toString(),
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: colorWithOpacity(statusBadgeColor(appointmentStatus), 0.12),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(color: statusBadgeColor(appointmentStatus)),
                                                    ),
                                                    child: Text(
                                                      formatStatus(appointmentStatus),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: statusBadgeColor(appointmentStatus),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),
                                              // Start & Complete buttons row (50% width each)
                                              if (_isApproved)
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed: _canStart && (visitType ?? '').toLowerCase() != 'home_visit'
                                                            ? () {
                                                                _addVideoOverlay(context);
                                                              }
                                                            : null,
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: loginButton,
                                                          side: BorderSide(
                                                            color: (_canStart && (visitType ?? '').toLowerCase() != 'home_visit')
                                                                ? loginButton
                                                                : divider,
                                                          ),
                                                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                        child: Text(
                                                          getTranslated(context, AppString.information_start_status).toString(),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: _canComplete
                                                            ? () {
                                                                statusChangeRequest("complete");
                                                              }
                                                            : null,
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: loginButton,
                                                          foregroundColor: colorWhite,
                                                          elevation: 0,
                                                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                        child: Text(
                                                          getTranslated(context, AppString.information_complete_status).toString(),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        )
                                      : StatefulBuilder(builder: (context, myState) {
                                          return Visibility(
                                            visible: hideButton,
                                            child: sectionCard(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        myState(() {
                                                          statusChangeRequest("approve");
                                                        });
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: loginButton,
                                                        foregroundColor: colorWhite,
                                                        elevation: 0,
                                                        padding: EdgeInsets.symmetric(vertical: 12),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      child: Text(getTranslated(context, AppString.information_approve_status).toString()),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          statusChangeRequest("cancel");
                                                        });
                                                      },
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: statusCancel,
                                                        side: BorderSide(color: statusCancel),
                                                        padding: EdgeInsets.symmetric(vertical: 12),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      child: Text(getTranslated(context, AppString.information_cancel_status).toString()),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                  sectionCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        infoRow(
                                          icon: Icons.person_outline,
                                          title: getTranslated(context, AppString.information_patient_name).toString(),
                                          value: safeText(name),
                                        ),
                                        SizedBox(height: 14),
                                        Divider(color: divider, height: 1),
                                        SizedBox(height: 14),
                                        infoRow(
                                          icon: Icons.cake_outlined,
                                          title: getTranslated(context, AppString.information_patient_age).toString(),
                                          value: safeText(age?.toString()),
                                        ),
                                        SizedBox(height: 14),
                                        Divider(color: divider, height: 1),
                                        SizedBox(height: 14),
                                        infoRow(
                                          icon: Icons.phone_outlined,
                                          title: getTranslated(context, AppString.information_patient_phone_number).toString(),
                                          value: safeText(phoneNo),
                                        ),
                                        SizedBox(height: 14),
                                        Divider(color: divider, height: 1),
                                        SizedBox(height: 14),
                                        infoRow(
                                          icon: Icons.access_time,
                                          title: getTranslated(context, AppString.information_patient_time).toString(),
                                          value: safeText(time),
                                        ),
                                        SizedBox(height: 14),
                                        Divider(color: divider, height: 1),
                                        SizedBox(height: 14),
                                        infoRow(
                                          icon: Icons.location_on_outlined,
                                          title: getTranslated(context, AppString.information_patient_address).toString(),
                                          value: safeText(patientAddress),
                                          maxLines: 3,
                                        ),
                                        if (isInsured == 0) ...[
                                          SizedBox(height: 14),
                                          Divider(color: divider, height: 1),
                                          SizedBox(height: 14),
                                          infoRow(
                                            icon: Icons.shield_outlined,
                                            title: getTranslated(context, AppString.patientInsured).toString(),
                                            value: getTranslated(context, AppString.patientIsNotInsured).toString(),
                                            maxLines: 2,
                                          ),
                                        ],
                                        if (isInsured == 1) ...[
                                          SizedBox(height: 14),
                                          Divider(color: divider, height: 1),
                                          SizedBox(height: 14),
                                          infoRow(
                                            icon: Icons.verified_user_outlined,
                                            title: getTranslated(context, AppString.policy_provider).toString(),
                                            value: safeText(policyInsurerName),
                                            maxLines: 2,
                                          ),
                                          SizedBox(height: 14),
                                          Divider(color: divider, height: 1),
                                          SizedBox(height: 14),
                                          infoRow(
                                            icon: Icons.badge_outlined,
                                            title: getTranslated(context, AppString.policy_number).toString(),
                                            value: safeText(policyNumber),
                                            maxLines: 2,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            ///tab 2
                            SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              physics: AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  sectionCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        sectionHeader(
                                          icon: Icons.health_and_safety_outlined,
                                          title: getTranslated(context, AppString.information_patient_illness_information).toString(),
                                        ),
                                        SizedBox(height: 10),
                                        sectionBodyText(safeText(illness)),
                                      ],
                                    ),
                                  ),
                                  sectionCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        sectionHeader(
                                          icon: Icons.medical_services_outlined,
                                          title: getTranslated(context, AppString.information_side_effect_drug).toString(),
                                        ),
                                        SizedBox(height: 10),
                                        sectionBodyText(safeText(drugEffect)),
                                      ],
                                    ),
                                  ),
                                  sectionCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        sectionHeader(
                                          icon: Icons.sticky_note_2_outlined,
                                          title: getTranslated(context, AppString.information_note).toString(),
                                        ),
                                        SizedBox(height: 10),
                                        sectionBodyText(safeText(note)),
                                      ],
                                    ),
                                  ),
                                  reportImages.length == 0
                                      ? SizedBox()
                                      : sectionCard(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              sectionHeader(
                                                icon: Icons.insert_photo_outlined,
                                                title: getTranslated(context, AppString.information_report_image_title).toString(),
                                              ),
                                              SizedBox(height: 10),
                                              Container(
                                                height: 120,
                                                width: width,
                                                child: GridView.builder(
                                                  physics: NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  scrollDirection: Axis.vertical,
                                                  itemCount: reportImages.length,
                                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 3,
                                                  ),
                                                  itemBuilder: (context, index) {
                                                    return Container(
                                                      margin: EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(color: divider),
                                                      ),
                                                      child: FullScreenWidget(
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(12),
                                                          child: Image.network(
                                                            reportImages[index],
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            ///tab 3
                            SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                physics: AlwaysScrollableScrollPhysics(),
                                child: pdf == ''
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          sectionCard(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                sectionHeader(
                                                  icon: Icons.medication_outlined,
                                                  title: getTranslated(context, AppString.doctor_prescription).toString(),
                                                ),
                                                SizedBox(height: 12),
                                                if (!_canPrescribe)
                                                  const Padding(
                                                    padding: EdgeInsets.symmetric(vertical: 12),
                                                    child: Text(
                                                      'Prescription creation is restricted to approved doctors. Providers can continue scheduling, visiting and communicating with patients.',
                                                      style: TextStyle(fontSize: 14),
                                                    ),
                                                  ),
                                                if (_canPrescribe)
                                                  ElevatedButton.icon(
                                                  onPressed: () {
                                                    _days.clear();
                                                    alertValueFirst = false;
                                                    alertValueSecond = false;
                                                    alertValueThird = false;

                                                    showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return Form(
                                                            key: _formKey,
                                                            child: StatefulBuilder(
                                                              builder: (BuildContext context, StateSetter myState) {
                                                                return AlertDialog(
                                                                  insetPadding: EdgeInsets.all(10),
                                                                  title: Text(getTranslated(context, AppString.information_medicine_title).toString()),
                                                                  content: Container(
                                                                    margin: EdgeInsets.symmetric(horizontal: width! * 0.02),
                                                                    height: height * 0.4,
                                                                    width: width! * 1.0,
                                                                    child: Column(
                                                                      children: [
                                                                        Row(
                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                                                            Container(
                                                                              width: 200,
                                                                              height: 80,
                                                                              child: TextDropdownFormField(
                                                                                options: medicineReq,
                                                                                decoration: InputDecoration(
                                                                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: black)),
                                                                                    suffixIcon: Icon(Icons.arrow_drop_down),
                                                                                    labelText: getTranslated(context, AppString.information_medicine_title).toString()),
                                                                                dropdownHeight: 200,
                                                                                onChanged: (dynamic value) {
                                                                                  selectedMedicineValue = value;
                                                                                },
                                                                              ),
                                                                            ),
                                                                            FittedBox(
                                                                              fit: BoxFit.fitWidth,
                                                                              child: Container(
                                                                                height: 70,
                                                                                width: width! / 5,
                                                                                alignment: Alignment.center,
                                                                                child: TextFormField(
                                                                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                                  inputFormatters: [new FilteringTextInputFormatter.allow(RegExp("[0-9]"))],
                                                                                  controller: _days,
                                                                                  decoration: InputDecoration(
                                                                                    contentPadding: EdgeInsets.all(5),
                                                                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: black)),
                                                                                    hintText: getTranslated(context, AppString.information_medicine_days).toString(),
                                                                                  ),
                                                                                  onChanged: (value) {
                                                                                    myState(() {
                                                                                      valueDays = value;
                                                                                    });
                                                                                  },
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        Container(
                                                                            margin: EdgeInsets.only(
                                                                              left: width! * 0.04,
                                                                              right: width! * 0.04,
                                                                            ),
                                                                            child: Column(
                                                                              children: [
                                                                                Container(
                                                                                  margin: EdgeInsets.only(top: height * 0.01),
                                                                                  child: Transform.scale(
                                                                                    scale: 1.2,
                                                                                    child: CheckboxListTile(
                                                                                      controlAffinity: ListTileControlAffinity.leading,
                                                                                      title: Text(
                                                                                        getTranslated(context, AppString.information_medicine_morning).toString(),
                                                                                        style: TextStyle(fontSize: 16, color: hintColor),
                                                                                      ),
                                                                                      checkColor: loginButton,
                                                                                      activeColor: hintColor,
                                                                                      value: this.alertValueFirst,
                                                                                      onChanged: (bool? value) {
                                                                                        myState(() {
                                                                                          alertValueFirst = value;
                                                                                        });
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Container(
                                                                                  margin: EdgeInsets.only(top: height * 0.01),
                                                                                  child: Transform.scale(
                                                                                    scale: 1.2,
                                                                                    child: CheckboxListTile(
                                                                                      controlAffinity: ListTileControlAffinity.leading,
                                                                                      title: Text(
                                                                                        getTranslated(context, AppString.information_medicine_afternoon).toString(),
                                                                                        style: TextStyle(fontSize: 16, color: hintColor),
                                                                                      ),
                                                                                      checkColor: loginButton,
                                                                                      activeColor: hintColor,
                                                                                      value: this.alertValueSecond,
                                                                                      onChanged: (bool? value) {
                                                                                        myState(() {
                                                                                          alertValueSecond = value;
                                                                                        });
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Container(
                                                                                  margin: EdgeInsets.only(top: height * 0.01),
                                                                                  child: Transform.scale(
                                                                                    scale: 1.2,
                                                                                    child: CheckboxListTile(
                                                                                      controlAffinity: ListTileControlAffinity.leading,
                                                                                      title: Text(
                                                                                        getTranslated(context, AppString.information_medicine_night).toString(),
                                                                                        style: TextStyle(fontSize: 16, color: hintColor),
                                                                                      ),
                                                                                      checkColor: loginButton,
                                                                                      activeColor: hintColor,
                                                                                      value: this.alertValueThird,
                                                                                      onChanged: (bool? value) {
                                                                                        myState(() {
                                                                                          alertValueThird = value;
                                                                                        });
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            )),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  actions: <Widget>[
                                                                    OutlinedButton(
                                                                      child: Text(getTranslated(context, AppString.profile_dialog_ok_button).toString()),
                                                                      onPressed: () {
                                                                        if (selectedMedicineValue == null) {
                                                                          Fluttertoast.showToast(
                                                                            msg: getTranslated(context, AppString.please_select_medicines).toString(),
                                                                            toastLength: Toast.LENGTH_SHORT,
                                                                            gravity: ToastGravity.BOTTOM,
                                                                          );
                                                                        } else if (_days.text.isEmpty) {
                                                                          Fluttertoast.showToast(
                                                                            msg: getTranslated(context, AppString.please_enter_days).toString(),
                                                                            toastLength: Toast.LENGTH_SHORT,
                                                                            gravity: ToastGravity.BOTTOM,
                                                                          );
                                                                        } else {
                                                                          Map<String, dynamic> param = new HashMap();
                                                                          param['name'] = selectedMedicineValue;
                                                                          param['day'] = _days.text;
                                                                          param['morning'] = alertValueFirst;
                                                                          param['afternoon'] = alertValueSecond;
                                                                          param['night'] = alertValueThird;
                                                                          listOfMedicine.add(param);
                                                                          Navigator.pop(context);

                                                                          setState(() {});
                                                                        }
                                                                      },
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                          );
                                                        });
                                                  },
                                                  icon: Icon(Icons.add, size: 18),
                                                  label: Text(getTranslated(context, AppString.add_medicine_button).toString()),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: loginButton,
                                                    foregroundColor: colorWhite,
                                                    elevation: 0,
                                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          sectionCard(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: DataTableWidget(),
                                            ),
                                          ),
                                          sectionCard(
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                  child: Text(
                                                    getTranslated(context, AppString.generate_pdf_button).toString(),
                                                    style: TextStyle(color: colorWhite, fontWeight: FontWeight.bold),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: loginButton,
                                                    foregroundColor: colorWhite,
                                                    elevation: 0,
                                                    padding: EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                  onPressed: () {
                                                    medicineData.clear();
                                                    Map<String, dynamic> medicines;
                                                    for (int i = 0; i < listOfMedicine.length; i++) {
                                                      medicines = {
                                                        "medicine": listOfMedicine[i]['name'],
                                                        "days": listOfMedicine[i]['day'],
                                                        "morning": listOfMedicine[i]['morning'] == true ? 1 : 0,
                                                        "afternoon": listOfMedicine[i]['afternoon'] == true ? 1 : 0,
                                                        "night": listOfMedicine[i]['night'] == true ? 1 : 0
                                                      };
                                                      medicineData.add(medicines);
                                                    }

                                                    var convertMedicine = jsonEncode(medicineData);

                                                    List<Map<String, dynamic>> pdfData = [];

                                                    for (int i = 0; i < listOfMedicine.length; i++) {
                                                      Map<String, dynamic> mapEducationData = {
                                                        "medicine": listOfMedicine[i]['name'],
                                                        "days": listOfMedicine[i]['day'],
                                                        "morning": listOfMedicine[i]['morning'] == true ? 1 : 0,
                                                        "afternoon": listOfMedicine[i]['afternoon'] == true ? 1 : 0,
                                                        "night": listOfMedicine[i]['night'] == true ? 1 : 0
                                                      };
                                                      pdfData.add(mapEducationData);
                                                    }

                                                    if (pdfData.length > 0) {
                                                      reportView(this.context, pdfData, id, userId, convertMedicine);
                                                      Fluttertoast.showToast(
                                                        msg: getTranslated(context, AppString.pdf_generated).toString(),
                                                        toastLength: Toast.LENGTH_SHORT,
                                                        gravity: ToastGravity.BOTTOM,
                                                      );
                                                    } else {
                                                      Fluttertoast.showToast(
                                                        msg: getTranslated(context, AppString.please_enter_data).toString(),
                                                        toastLength: Toast.LENGTH_SHORT,
                                                        gravity: ToastGravity.BOTTOM,
                                                      );
                                                    }
                                                  }),
                                            ),
                                          )
                                        ],
                                      )
                                    : Center(
                                        child: sectionCard(
                                          margin: EdgeInsets.symmetric(horizontal: width! * 0.18, vertical: height * 0.04),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              child: Text(
                                                getTranslated(context, AppString.view_pdf_button).toString(),
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: loginButton,
                                                foregroundColor: colorWhite,
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              onPressed: () {
                                                launchUrl(Uri.parse("$pdf"));
                                              },
                                            ),
                                          ),
                                        ),
                                      )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
      ),
    );
  }

  Future<BaseModel<DoctorStatusChange>> statusChangeRequest(String status) async {
    Map<String, dynamic> body = {"id": id, "status": status};

    DoctorStatusChange response;

    try {
      response = await RestClient(RetroApi().dioData()).doctorStatusChangeRequest(body);
      if (!mounted) {
        return BaseModel()..data = response;
      }
      setState(() {
        if (status == 'approve') {
          appointmentStatus = 'approve';
        } else if (status == 'complete') {
          appointmentStatus = 'complete';
        } else {
          appointmentStatus = 'cancel';
        }

        hideButton = false;

        Fluttertoast.showToast(
          msg: response.msg!,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      });
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<AllMedicines>> allMedicinesRequest() async {
    AllMedicines response;

    try {
      medicineReq.clear();

      response = await RestClient(RetroApi().dioData()).allMedicines();
      setState(() {
        for (int i = 0; i < response.data!.length; i++) {
          medicineReq.add(response.data![i].name.toString());
        }
      });
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<AppointmentDetails>> appointmentDetails() async {
    AppointmentDetails response;

    try {
      response = await RestClient(RetroApi().dioData()).appointmentDetails(id);
      if (!mounted) {
        return BaseModel()..data = response;
      }
      setState(() {
        final data = response.data;
        name = data?.patientName;
        age = data?.age;
        amount = double.tryParse(data?.amount ?? '') ?? 0.0;
        appointmentDateRaw = data?.date ?? '';
        date = data?.date != null ? DateUtil().formattedDate(DateTime.parse(data!.date!)) : '';
        phoneNo = data?.phoneNo;
        patientAddress = data?.patientAddress;
        illness = data?.illnessInformation;
        note = data?.note;
        appointmentId = data?.appointmentId;
        drugEffect = data?.drugEffect;
        time = data?.time;
        fullImage = data?.user?.fullImage ?? "";
        appointment = data?.appointmentFor;
        final normalizedStatus = (data?.appointmentStatus ?? '').toLowerCase();
        appointmentStatus = normalizedStatus;
        visitType = data?.visitType ?? '';
        userId = data?.userId;
        pdf = data?.pdf;
        reportImages.clear();
        reportImages.addAll(data?.reportImage ?? []);
        isInsured = data?.isInsured ?? 0;
        policyInsurerName = data?.policyInsurerName ?? "";
        policyNumber = data?.policyNumber ?? "";
        hideButton = normalizedStatus == 'pending';
      });
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  DateTime? _getAppointmentStart() {
    final dateStr = appointmentDateRaw?.trim() ?? '';
    final timeStr = time?.trim() ?? '';
    if (dateStr.isEmpty || timeStr.isEmpty) return null;
    try {
      final date = DateTime.parse(dateStr);
      final parts = timeStr.split(RegExp(r'\s+'));
      if (parts.isEmpty) return null;
      final timePart = parts[0];
      final ampm = parts.length > 1 ? parts[1].toLowerCase() : 'am';
      final timeComponents = timePart.split(':');
      if (timeComponents.length < 2) return null;
      int h = int.tryParse(timeComponents[0]) ?? 0;
      int m = int.tryParse(timeComponents[1]) ?? 0;
      if (ampm == 'pm' && h < 12) h += 12;
      if (ampm == 'am' && h == 12) h = 0;
      return DateTime(date.year, date.month, date.day, h, m);
    } catch (_) {
      return null;
    }
  }

  bool get _isApproved {
    final s = (appointmentStatus ?? '').toLowerCase();
    return s == 'approve' || s == 'approved';
  }

  bool get _canStart {
    if (!_isApproved) return false;
    final start = _getAppointmentStart();
    if (start == null) return false;
    final now = DateTime.now();
    final windowStart = start.subtract(const Duration(minutes: 10));
    return (now.isAfter(windowStart) || now.isAtSameMomentAs(windowStart)) && now.isBefore(start);
  }

  bool get _canComplete {
    if (!_isApproved) return false;
    final start = _getAppointmentStart();
    if (start == null) return false;
    return DateTime.now().isAfter(start) || DateTime.now().isAtSameMomentAs(start);
  }

  _addVideoOverlay(BuildContext context) {
    OverlayService().addVideosOverlay(
      context,
      VideoCall(
        id: userId,
        callEnd: false,
        flag: "OutGoing",
      ),
    );
  }
}

class DataTableWidget extends StatefulWidget {
  @override
  _DataTableWidgetState createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  @override
  Widget build(BuildContext context) {
    return DataTable(
      horizontalMargin: 15,
      columnSpacing: 20,
      columns: [
        DataColumn(label: Text(getTranslated(context, AppString.pdf_medicine_name).toString())),
        DataColumn(label: Text(getTranslated(context, AppString.information_medicine_days).toString())),
        DataColumn(label: Text(getTranslated(context, AppString.pdf_medicine_morning).toString())),
        DataColumn(label: Text(getTranslated(context, AppString.pdf_medicine_afternoon).toString())),
        DataColumn(label: Text(getTranslated(context, AppString.pdf_medicine_night).toString())),
        DataColumn(label: Text(getTranslated(context, AppString.pdf_medicine_status).toString())),
      ],
      rows: listOfMedicine
          .map(
            ((element) => DataRow(
                  cells: <DataCell>[
                    DataCell(Text(element["name"].toString())), //Extracting from Map element the value
                    DataCell(Text(element["day"])),
                    DataCell(element["morning"] ? Icon(Icons.check, size: 20) : Icon(Icons.clear, size: 20)),
                    DataCell(element["afternoon"] ? Icon(Icons.check, size: 20) : Icon(Icons.clear, size: 20)),
                    DataCell(element["night"] ? Icon(Icons.check, size: 20) : Icon(Icons.clear, size: 20)),
                    DataCell(GestureDetector(
                        onTap: () {
                          setState(() {
                            listOfMedicine.remove(element);
                          });
                        },
                        child: Icon(Icons.delete, size: 20))),
                  ],
                )),
          )
          .toList(),
    );
  }
}

class DateUtil {
  static const DATE_FORMAT = 'dd-MM-yyyy';

  String formattedDate(DateTime dateTime) {
    return DateFormat(DATE_FORMAT).format(dateTime);
  }
}

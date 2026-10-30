import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro/model/appointment_history.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/base_model.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/constant/common_function.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/retrofit/server_error.dart';
import 'package:doctro/screens/auth/SignIn.dart';
import 'package:doctro/screens/home%20page/patient_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  @override
  _AppointmentHistoryScreen createState() => _AppointmentHistoryScreen();
}

class _AppointmentHistoryScreen extends State<AppointmentHistoryScreen>
    with TickerProviderStateMixin {
  Future? appointment;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<PastAppointment> pastAppointmentReq = [];
  List<UpcomingAppointment> upcomingAppointmentReq = [];

  TextEditingController _search = TextEditingController();
  List<UpcomingAppointment> _searchResult = [];
  List<UpcomingAppointment> _userDetails = [];
  List<PastAppointment> _pastSearch = [];
  List<PastAppointment> _pastData = [];
  bool? isShow;

  String? dName;
  String? dFullImage;
  String? phone;
  int? subscription;

  late double width;
  late double height;

  List<Tab> tabList = [];
  TabController? _tabController;

  List<String> _drawer = [];
  List<String> _drawerMenu = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _drawer = [
      getTranslated(context, AppString.drawer_home).toString(),
      getTranslated(context, AppString.drawer_payments).toString(),
      getTranslated(context, AppString.drawer_withdrawal) ?? 'Withdrawal',
      getTranslated(context, AppString.drawer_canceled_appointment).toString(),
      getTranslated(context, AppString.drawer_appointments).toString(),
      getTranslated(context, AppString.chats).toString(),
      getTranslated(context, AppString.drawer_review).toString(),
      getTranslated(context, AppString.drawer_notification).toString(),
      getTranslated(context, AppString.drawer_callHistory).toString(),
      getTranslated(context, AppString.drawer_schedule_timing).toString(),
      getTranslated(context, AppString.drawer_setting).toString(),
      getTranslated(context, AppString.drawer_logout).toString(),
    ];

    _drawerMenu = [
      getTranslated(context, AppString.drawer_home).toString(),
      getTranslated(context, AppString.drawer_payments).toString(),
      getTranslated(context, AppString.drawer_withdrawal) ?? 'Withdrawal',
      getTranslated(context, AppString.drawer_canceled_appointment).toString(),
      getTranslated(context, AppString.drawer_appointments).toString(),
      getTranslated(context, AppString.chats).toString(),
      getTranslated(context, AppString.drawer_review).toString(),
      getTranslated(context, AppString.drawer_notification).toString(),
      getTranslated(context, AppString.drawer_callHistory).toString(),
      getTranslated(context, AppString.drawer_schedule_timing).toString(),
      getTranslated(context, AppString.drawer_setting).toString(),
      getTranslated(context, AppString.drawer_logout).toString(),
    ];
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      tabList.add(Tab(
        child: Text(
          getTranslated(context, AppString.upcoming_appointment).toString(),
          textAlign: TextAlign.center,
        ),
      ));
      tabList.add(Tab(
        child: Text(
          getTranslated(context, AppString.past_appointment).toString(),
          textAlign: TextAlign.center,
        ),
      ));
      _tabController = TabController(vsync: this, length: tabList.length);
      _tabController!.addListener(() {
        setState(() {
          if (isShow == null) {
            isShow = true;
            _searchResult.clear();
            _search.clear();
          } else {
            isShow = false;
            _pastSearch.clear();
            _search.clear();
          }
        });
      });

      appointment = appointmentHistoryScreen();
      dName = SharedPreferenceHelper.getString(Preferences.name);
      dFullImage = SharedPreferenceHelper.getString(Preferences.image);
      phone = SharedPreferenceHelper.getString(Preferences.phone_no);
      subscription =
          SharedPreferenceHelper.getInt(Preferences.subscription_status);
    });
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  Color _colorWithOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  Color _statusColor(String? appointmentStatus) {
    final upper = (appointmentStatus ?? '').toUpperCase();
    if (upper ==
        getTranslated(context, AppString.status_pending).toString()) {
      return _colorWithOpacity(hintColor, 0.6);
    } else if (upper ==
        getTranslated(context, AppString.status_cancel).toString()) {
      return statusCancel;
    }
    return status;
  }

  String _visitTypeLabel(String? visitType) {
    if (visitType == null || visitType.isEmpty) return '';
    if (visitType == 'home_visit')
      return getTranslated(context, AppString.visit_type_home_visit).toString();
    return getTranslated(context, AppString.visit_type_video_call).toString();
  }

  Widget _buildAppointmentCard({
    required int? id,
    required String? imageUrl,
    required String patientName,
    required String treatment,
    required String? visitType,
    required String statusText,
    required String? appointmentStatus,
    required String date,
    required String time,
    required String doctorName,
    required String hospitalName,
    required String hospitalAddress,
  }) {
    final sColor = _statusColor(appointmentStatus);
    final visitLabel = _visitTypeLabel(visitType);
    final displayStatus = statusText.isEmpty ? '-' : statusText;

    return GestureDetector(
      onTap: () {
        if (id != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => patientDetailsScreen(id: id)));
        }
      },
      child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _colorWithOpacity(divider, 0.6)),
        boxShadow: [
          BoxShadow(
            color: _colorWithOpacity(black, 0.06),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _colorWithOpacity(loginButton, 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: _colorWithOpacity(loginButton, 0.06),
                              child: Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: _colorWithOpacity(loginButton, 0.06),
                              child: Icon(Icons.person,
                                  color: hintColor, size: 28),
                            ),
                          )
                        : Container(
                            color: _colorWithOpacity(loginButton, 0.06),
                            child:
                                Icon(Icons.person, color: hintColor, size: 28),
                          ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Text(
                        treatment,
                        style: TextStyle(
                          fontSize: 13,
                          color: passwordVisibility,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (visitLabel.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              visitType == 'home_visit'
                                  ? Icons.home_rounded
                                  : Icons.videocam_rounded,
                              size: 13,
                              color: loginButton,
                            ),
                            SizedBox(width: 4),
                            Text(
                              visitLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: loginButton,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _colorWithOpacity(sColor, 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      color: sColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: _colorWithOpacity(divider, 0.8),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                _buildInfoColumn(
                  icon: Icons.calendar_today_rounded,
                  label: getTranslated(context, AppString.date_and_time)
                      .toString(),
                  value: '$date  $time',
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                Spacer(),
                _buildInfoColumn(
                  icon: Icons.person_outline_rounded,
                  label:
                      getTranslated(context, AppString.doctor_name).toString(),
                  value: doctorName,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ),
          if (hospitalName != '-' || hospitalAddress != '-') ...[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              color: _colorWithOpacity(divider, 0.8),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      icon: Icons.local_hospital_rounded,
                      label: getTranslated(
                              context, AppString.hospital_name_heading)
                          .toString(),
                      value: hospitalName,
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoColumn(
                      icon: Icons.location_on_rounded,
                      label: getTranslated(context, AppString.hospital_address)
                          .toString(),
                      value: hospitalAddress,
                      crossAxisAlignment: CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
    required CrossAxisAlignment crossAxisAlignment,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: loginButton),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: passwordVisibility,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: hintColor,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: _colorWithOpacity(loginButton, 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: _colorWithOpacity(loginButton, 0.5),
              ),
            ),
            SizedBox(height: 16),
            Text(
              getTranslated(context, AppString.result_not_found).toString(),
              style: TextStyle(
                fontSize: 16,
                color: hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'No appointments to display',
              style: TextStyle(
                fontSize: 13,
                color: passwordVisibility,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingList() {
    if (upcomingAppointmentReq.isEmpty) return _buildEmptyState();

    if (_search.text.isNotEmpty) {
      if (_searchResult.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              getTranslated(context, AppString.result_not_found).toString(),
              style: TextStyle(fontSize: 14, color: passwordVisibility),
            ),
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: 40),
        itemCount: _searchResult.length,
        itemBuilder: (context, i) {
          final a = _searchResult[i];
          return _buildAppointmentCard(
            id: a.id,
            imageUrl: a.user?.fullImage,
            patientName: a.patientName ?? '-',
            treatment: a.treatment ?? '-',
            visitType: a.visitType,
            statusText: (a.appointmentStatus ?? '').toUpperCase(),
            appointmentStatus: a.appointmentStatus,
            date: a.date ?? '-',
            time: a.time ?? '-',
            doctorName: a.doctorName ?? '-',
            hospitalName: a.hospital?.name ?? '-',
            hospitalAddress: a.hospital?.address ?? '-',
          );
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 40),
      itemCount: upcomingAppointmentReq.length,
      itemBuilder: (context, index) {
        final a = upcomingAppointmentReq[index];
        return _buildAppointmentCard(
          id: a.id,
          imageUrl: a.user?.fullImage,
          patientName: a.patientName ?? '-',
          treatment: a.treatment ?? '-',
          visitType: a.visitType,
          statusText: (a.appointmentStatus ?? '').toUpperCase(),
          appointmentStatus: a.appointmentStatus,
          date: a.date ?? '-',
          time: a.time ?? '-',
          doctorName: a.doctorName ?? '-',
          hospitalName: a.hospital?.name ?? '-',
          hospitalAddress: a.hospital?.address ?? '-',
        );
      },
    );
  }

  Widget _buildPastList() {
    if (pastAppointmentReq.isEmpty) return _buildEmptyState();

    if (_search.text.isNotEmpty) {
      if (_pastSearch.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              getTranslated(context, AppString.result_not_found).toString(),
              style: TextStyle(fontSize: 14, color: passwordVisibility),
            ),
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: 40),
        itemCount: _pastSearch.length,
        itemBuilder: (context, i) {
          final a = _pastSearch[i];
          return _buildAppointmentCard(
            id: a.id,
            imageUrl: a.user?.fullImage,
            patientName: a.patientName ?? '-',
            treatment: a.treatment ?? '-',
            visitType: a.visitType,
            statusText: (a.appointmentStatus ?? '').toUpperCase(),
            appointmentStatus: a.appointmentStatus,
            date: a.date ?? '-',
            time: a.time ?? '-',
            doctorName: a.doctorName ?? '-',
            hospitalName: a.hospital?.name ?? '-',
            hospitalAddress: a.hospital?.address ?? '-',
          );
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 40),
      itemCount: pastAppointmentReq.length,
      itemBuilder: (context, index) {
        final a = pastAppointmentReq[index];
        return _buildAppointmentCard(
          id: a.id,
          imageUrl: a.user?.fullImage,
          patientName: a.patientName ?? '-',
          treatment: a.treatment ?? '-',
          visitType: a.visitType,
          statusText: (a.appointmentStatus ?? '').toUpperCase(),
          appointmentStatus: a.appointmentStatus,
          date: a.date ?? '-',
          time: a.time ?? '-',
          doctorName: a.doctorName ?? '-',
          hospitalName: a.hospital?.name ?? '-',
          hospitalAddress: a.hospital?.address ?? '-',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    final drawerHome =
        getTranslated(context, AppString.drawer_home).toString();
    final drawerPayments =
        getTranslated(context, AppString.drawer_payments).toString();
    final drawerWithdrawal =
        getTranslated(context, AppString.drawer_withdrawal) ?? 'Withdrawal';
    final drawerCanceled =
        getTranslated(context, AppString.drawer_canceled_appointment)
            .toString();
    final drawerAppointments =
        getTranslated(context, AppString.drawer_appointments).toString();
    final drawerReview =
        getTranslated(context, AppString.drawer_review).toString();
    final drawerNotification =
        getTranslated(context, AppString.drawer_notification).toString();
    final drawerCallHistory =
        getTranslated(context, AppString.drawer_callHistory).toString();
    final drawerSchedule =
        getTranslated(context, AppString.drawer_schedule_timing).toString();
    final drawerSetting =
        getTranslated(context, AppString.drawer_setting).toString();
    final drawerChats =
        getTranslated(context, AppString.chats).toString();
    final drawerLogout =
        getTranslated(context, AppString.drawer_logout).toString();

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
      if (label == drawerSetting) return Icons.settings_rounded;
      if (label == drawerChats) return Icons.chat_bubble_outline_rounded;
      if (label == drawerLogout) return Icons.logout_rounded;
      return Icons.circle;
    }

    Widget buildDrawerList(List<String> items) {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (context, index) => SizedBox(height: 10),
        itemBuilder: (context, index) {
          final label = items[index];
          final isLogout = label == drawerLogout;
          final iconColor = isLogout ? red : loginButton;
          final textColor = isLogout ? red : hintColor;
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
                    color: _colorWithOpacity(black, 0.06),
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
                    color: _colorWithOpacity(iconColor, 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(drawerIcon(label), color: iconColor, size: 20),
                ),
                title: Text(
                  label,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: passwordVisibility),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                horizontalTitleGap: 12,
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: back,
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
                                color: _colorWithOpacity(black, 0.06),
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
                                  border: Border.all(
                                      color:
                                          _colorWithOpacity(loginButton, 0.4),
                                      width: 2),
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: '$dFullImage',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Image.asset(
                                            "assets/images/no_image.jpg",
                                            fit: BoxFit.cover),
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
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: hintColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "$phone",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: passwordVisibility),
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
                          child: subscription == -1
                              ? buildDrawerList(_drawerMenu)
                              : buildDrawerList(_drawer),
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
                          _colorWithOpacity(loginButton, 0.12),
                          _colorWithOpacity(tabBar, 0.2),
                              back,
                            ],
                          ),
                        ),
                    child: Column(
                      children: [
                          Container(
                          margin: EdgeInsets.only(
                              left: width * 0.06,
                              right: width * 0.04,
                              top: height * 0.01),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                getTranslated(context,
                                        AppString.appointment_history_heading)
                                    .toString(),
                                style: TextStyle(
                                    fontSize: 20,
                                    color: hintColor,
                                    fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                      color: _colorWithOpacity(black, 0.06),
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
                          padding:
                              EdgeInsets.symmetric(horizontal: width * 0.06),
                            child: Container(
                              height: height * 0.058,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: colorWhite,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: divider),
                                boxShadow: [
                                  BoxShadow(
                                  color: _colorWithOpacity(black, 0.08),
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
                                      hintText: getTranslated(
                                              context,
                                              AppString
                                                  .search_appointment_history)
                                          .toString(),
                                        hintStyle: TextStyle(
                                          fontSize: width * 0.042,
                                        color:
                                            _colorWithOpacity(hintColor, 0.4),
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
                                    color:
                                        _colorWithOpacity(loginButton, 0.12),
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
                      ],
                    ),
                  ),
                ),
              ),
              body: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, 'loginHome', (route) => false);
                  }
                },
                child: RefreshIndicator(
                  color: loginButton,
                  onRefresh: appointmentHistoryScreen,
                  child: FutureBuilder(
                      future: appointment,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                        return Column(
                                    children: [
                                      Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: width * 0.05, vertical: 10),
                              padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                color: _colorWithOpacity(tabBar, 0.7),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: divider),
                                        ),
                                        child: TabBar(
                                          labelColor: loginButton,
                                          controller: _tabController,
                                          indicatorSize: TabBarIndicatorSize.tab,
                                          unselectedLabelColor: hintColor,
                                          indicator: BoxDecoration(
                                            color: colorWhite,
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                      color: _colorWithOpacity(black, 0.08),
                                                blurRadius: 8,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                labelStyle: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                                unselectedLabelStyle: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                                dividerHeight: 0,
                                          tabs: tabList,
                                        ),
                                      ),
                            Expanded(
                                        child: TabBarView(
                                          controller: _tabController,
                                          children: [
                                  _buildUpcomingList(),
                                  _buildPastList(),
                                                                              ],
                                                                            ),
                                                                          ),
                          ],
                        );
                      } else {
                        return Center(
                          child: CircularProgressIndicator(color: loginButton),
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<BaseModel<AppointmentHistory>> appointmentHistoryScreen() async {
    AppointmentHistory response;
    try {
      pastAppointmentReq.clear();
      upcomingAppointmentReq.clear();
      _pastData.clear();
      _userDetails.clear();
      response = await RestClient(RetroApi().dioData())
          .appointmentHistoryScreenRequest();
      if (mounted) {
      setState(() {
        pastAppointmentReq.addAll(response.data!.pastAppointment!);
        upcomingAppointmentReq.addAll(response.data!.upcomingAppointment!);
        _userDetails.addAll(response.data!.upcomingAppointment!);
        _pastData.addAll(response.data!.pastAppointment!);
      });
      }
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<void> logoutUser() async {
    SharedPreferenceHelper.clearPref();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (BuildContext context) => SignIn()),
      ModalRoute.withName('SignIn'),
    );
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
                  getTranslated(context, AppString.are_you_sure_logout)
                      .toString(),
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
                          getTranslated(context, AppString.cancel_button)
                              .toString(),
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
                          getTranslated(context, AppString.logout_button)
                              .toString(),
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
    _pastSearch.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    isShow == null
        ? _userDetails.forEach((upcomingAppointment) {
            if (upcomingAppointment.patientName!
                .toLowerCase()
                .contains(text.toLowerCase()))
              _searchResult.add(upcomingAppointment);
          })
        : _pastData.forEach((pastAppointment) {
            if (pastAppointment.patientName!
                .toLowerCase()
                .contains(text.toLowerCase()))
              _pastSearch.add(pastAppointment);
          });

    setState(() {});
  }
}

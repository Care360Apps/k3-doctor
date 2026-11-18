import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/base_model.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/constant/common_function.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/model/review.dart';
import 'package:doctro/retrofit/server_error.dart';
import 'package:doctro/screens/auth/SignIn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class RateAndReviewRoutesScreen extends StatefulWidget {
  @override
  _RateAndReviewRoutesScreenState createState() => _RateAndReviewRoutesScreenState();
}

class _RateAndReviewRoutesScreenState extends State<RateAndReviewRoutesScreen> {
  //Set Loader Data
  Future? reviewDatas;

  //Set Open Drawer
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  //Set Height/Width Using MediaQuery
  late double width;
  late double height;

  //doctorReview
  List<ReviewData> reviewData = [];

  //get preferences
  String? dName;

  String? dFullImage;

  String? phone;
  int? subscription;

  //Search view
  TextEditingController _search = TextEditingController();
  List<ReviewData> _searchResult = [];
  List<ReviewData> _userReview = [];

  //set HospitalName & HospitalAddress app bar
  String? hospitalName, hospitalAddress;
  List<String> _drawer = [];
  List<String> _drawerMenu = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    //Set Drawer Menu Item List
    _drawer = [
      getTranslated(context, AppString.drawer_home).toString(),
      getTranslated(context, AppString.drawer_payments).toString(),
      getTranslated(context, AppString.drawer_withdrawal) ?? 'Withdrawal',
      getTranslated(context, AppString.drawer_canceled_appointment).toString(),
      getTranslated(context, AppString.drawer_appointments).toString(),
      getTranslated(context, AppString.drawer_review).toString(),
      getTranslated(context, AppString.drawer_notification).toString(),
      getTranslated(context, AppString.drawer_callHistory).toString(),
      getTranslated(context, AppString.drawer_schedule_timing).toString(),
      getTranslated(context, AppString.drawer_setting).toString(),
      getTranslated(context, AppString.chats).toString(),
      getTranslated(context, AppString.drawer_logout).toString(),
    ];

    _drawerMenu = [
      getTranslated(context, AppString.drawer_home).toString(),
      getTranslated(context, AppString.drawer_payments).toString(),
      getTranslated(context, AppString.drawer_withdrawal) ?? 'Withdrawal',
      getTranslated(context, AppString.drawer_canceled_appointment).toString(),
      getTranslated(context, AppString.drawer_appointments).toString(),
      getTranslated(context, AppString.drawer_review).toString(),
      getTranslated(context, AppString.drawer_notification).toString(),
      getTranslated(context, AppString.drawer_callHistory).toString(),
      getTranslated(context, AppString.drawer_schedule_timing).toString(),
      getTranslated(context, AppString.drawer_setting).toString(),
      getTranslated(context, AppString.chats).toString(),
      getTranslated(context, AppString.drawer_logout).toString(),
    ];
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      dName = SharedPreferenceHelper.getString(Preferences.name);
      dFullImage = SharedPreferenceHelper.getString(Preferences.image);
      phone = SharedPreferenceHelper.getString(Preferences.phone_no);
      subscription = SharedPreferenceHelper.getInt(Preferences.subscription_status);
      reviewDatas = reviewRequest();
    });
  }

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
    final drawerSetting = getTranslated(context, AppString.drawer_setting).toString();
    final drawerChats = getTranslated(context, AppString.chats).toString();
    final drawerLogout = getTranslated(context, AppString.drawer_logout).toString();

    Color colorWithOpacity(Color color, double opacity) {
      return color.withValues(alpha: opacity);
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
                    color: black.withOpacity(0.06),
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
                trailing: Icon(Icons.chevron_right_rounded, color: passwordVisibility),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                horizontalTitleGap: 12,
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      key: _scaffoldKey,
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
          preferredSize: Size(20, 150),
          child: SafeArea(
              top: true,
              child: Column(children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: width * 0.06, right: width * 0.06, top: height * 0.01),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                child: Text(
                                  getTranslated(context, AppString.review_heading).toString(),
                                  style: TextStyle(fontSize: width * 0.05, color: hintColor),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(),
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
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: height * 0.01),
                  padding: EdgeInsets.all(10),
                  child: Card(
                    color: colorWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                        alignment: AlignmentDirectional.center,
                        margin: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: height * 0.06,
                              width: width * 0.7,
                              child: TextField(
                                controller: _search,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: getTranslated(context, AppString.review_search).toString(),
                                  hintStyle: TextStyle(
                                    color: hintColor.withOpacity(0.3),
                                  ),
                                ),
                                onChanged: onSearchTextChanged,
                                textAlign: TextAlign.left,
                              ),
                            ),
                            Container(
                              child: SvgPicture.asset(
                                'assets/icons/dSearch.svg',
                                height: 20,
                              ),
                            ),
                          ],
                        )),
                  ),
                ),
              ]))),
      body: WillPopScope(
        onWillPop: () {
          Navigator.pushNamedAndRemoveUntil(context, 'loginHome', (route) => false);
          return Future<bool>.value(false);
        },
        child: FutureBuilder(
            future: reviewDatas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return RefreshIndicator(
                  onRefresh: reviewRequest,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          reviewData.length == 0
                              ? Center(
                                  child: Container(
                                    margin: EdgeInsets.only(top: height * 0.2),
                                    child: Container(
                                      child: Image.asset("assets/images/no-data.png"),
                                    ),
                                  ),
                                )
                              : _search.text.isNotEmpty
                                  ? _searchResult.length > 0
                                      ? ListView.builder(
                                          shrinkWrap: true,
                                          physics: NeverScrollableScrollPhysics(),
                                          itemCount: _searchResult.length,
                                          itemBuilder: (context, i) {
                                            String createDate = DateUtil().formattedDate(DateTime.parse(_searchResult[i].createdAt!));
                                            return Container(
                                                margin: EdgeInsets.only(left: width * 0.02, right: width * 0.02),
                                                width: width * 0.87,
                                                height: 100,
                                                child: Column(children: <Widget>[
                                                  Container(
                                                    child: ListTile(
                                                      leading: SizedBox(
                                                        height: 70,
                                                        width: 60,
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: Container(decoration: new BoxDecoration(image: new DecorationImage(fit: BoxFit.fitHeight, image: NetworkImage(_searchResult[i].user!.fullImage!)))),
                                                        ),
                                                      ),
                                                      title: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Container(
                                                            alignment: AlignmentDirectional.topStart,
                                                            margin: EdgeInsets.only(
                                                              top: height * 0.01,
                                                            ),
                                                            child: Text(_searchResult[i].user!.name!, style: TextStyle(fontSize: 16.0)),
                                                          ),
                                                          Container(
                                                            child: RatingBarIndicator(
                                                              rating: _searchResult[i].rate!.toDouble(),
                                                              itemBuilder: (context, index) => Icon(
                                                                Icons.star,
                                                                color: loginButton,
                                                              ),
                                                              itemCount: 5,
                                                              itemSize: 18.0,
                                                              direction: Axis.horizontal,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      subtitle: Column(
                                                        children: <Widget>[
                                                          Container(
                                                            alignment: AlignmentDirectional.topStart,
                                                            child: Text(
                                                              _searchResult[i].review!,
                                                              style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 2,
                                                            ),
                                                          ),
                                                          Container(
                                                              alignment: AlignmentDirectional.topStart,
                                                              child: Text(
                                                                "$createDate",
                                                                style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                              )),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ]));
                                          },
                                        )
                                      : Container(
                                          height: height / 1.5,
                                          child: Center(
                                              child: Container(
                                            margin: EdgeInsets.only(top: height * 0.02),
                                            child: Text(getTranslated(context, AppString.result_not_found).toString()),
                                          )))
                                  : ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      reverse: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount: reviewData.length,
                                      itemBuilder: (context, index) {
                                        String createDate = DateUtil().formattedDate(DateTime.parse(reviewData[index].createdAt!));
                                        return Container(
                                            margin: EdgeInsets.only(left: width * 0.02, right: width * 0.02),
                                            width: width * 0.87,
                                            height: 100,
                                            child: Column(children: <Widget>[
                                              Container(
                                                child: ListTile(
                                                  isThreeLine: true,
                                                  leading: SizedBox(
                                                    height: 70,
                                                    width: 60,
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Container(decoration: new BoxDecoration(image: new DecorationImage(fit: BoxFit.fitHeight, image: NetworkImage(reviewData[index].user!.fullImage!)))),
                                                    ),
                                                  ),
                                                  title: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Container(
                                                        alignment: AlignmentDirectional.topStart,
                                                        margin: EdgeInsets.only(
                                                          top: height * 0.01,
                                                        ),
                                                        child: Text(reviewData[index].user!.name!, style: TextStyle(fontSize: 16.0)),
                                                      ),
                                                      Container(
                                                        child: RatingBarIndicator(
                                                          rating: reviewData[index].rate!.toDouble(),
                                                          itemBuilder: (context, index) => Icon(
                                                            Icons.star,
                                                            color: loginButton,
                                                          ),
                                                          itemCount: 5,
                                                          itemSize: 18.0,
                                                          direction: Axis.horizontal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: Column(
                                                    children: <Widget>[
                                                      Container(
                                                        alignment: AlignmentDirectional.topStart,
                                                        child: Text(
                                                          reviewData[index].review!,
                                                          style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                      Container(
                                                          alignment: AlignmentDirectional.topStart,
                                                          child: Text(
                                                            "$createDate",
                                                            style: TextStyle(fontSize: 12, color: passwordVisibility),
                                                          )),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ]));
                                      },
                                    ),
                        ],
                      ),
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
    );
  }

  Future<BaseModel<Review>> reviewRequest() async {
    Review response;

    try {
      reviewData.clear();
      _userReview.clear();
      response = await RestClient(RetroApi().dioData()).reviewRequest();
      setState(() {
        reviewData.addAll(response.data!);
        _userReview.addAll(response.data!);
      });
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<void> logoutUser() async {
    try {
      await SharedPreferenceHelper.clearPrefSecurely();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to finish signing out. Please try again.'),
        ));
      }
      return;
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) => SignIn()), ModalRoute.withName('SignIn'));
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget cancel = TextButton(
      child: Text(
        getTranslated(context, AppString.cancel_button).toString(),
        style: TextStyle(color: hintColor),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget okButton = TextButton(
      child: Text(
        getTranslated(context, AppString.logout_button).toString(),
        style: TextStyle(color: hintColor),
      ),
      onPressed: () {
        CommonFunction.checkNetwork().then((value) {
          if (value == true) {
            logoutUser();
          }
        });
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      content: Text(getTranslated(context, AppString.are_you_sure_logout).toString()),
      actions: [cancel, okButton],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    _userReview.forEach((userName) {
      if (userName.user!.name!.toLowerCase().contains(text.toLowerCase())) _searchResult.add(userName);
    });

    setState(() {});
  }
}

class DateUtil {
  static const DATE_FORMAT = 'dd-MM-yyyy';

  String formattedDate(DateTime dateTime) {
    return DateFormat(DATE_FORMAT).format(dateTime);
  }
}

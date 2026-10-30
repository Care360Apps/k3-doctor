import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/screens/setting/changeLanguage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../model/UpdateProfile.dart';
import '../../model/account_delete_model.dart';
import '../../model/doctor_profile.dart';
import '../../retrofit/api_header.dart';
import '../../retrofit/base_model.dart';
import '../../retrofit/network_api.dart';
import '../../retrofit/server_error.dart';
import 'ChangePassword.dart';
import '../auth/SignIn.dart';
import '../subscription/SubscriptionHistory.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool isCallEnable = false;
  bool _deleteAccountLoading = false;

  @override
  void initState() {
    super.initState();
    doctorProfile();
  }

  @override
  Widget build(BuildContext context) {
    double width;
    double height;

    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    Color colorWithOpacity(Color color, double opacity) {
      return color.withValues(alpha: opacity);
    }

    Widget buildSettingTile({required String title, required VoidCallback onTap, IconData icon = Icons.chevron_right_rounded}) {
      return Card(
        elevation: 1,
        shadowColor: colorWithOpacity(black, 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: colorWithOpacity(loginButton, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: hintColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(color: hintColor, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: passwordVisibility),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
      appBar: PreferredSize(
          preferredSize: Size(20, 120),
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
                    margin: EdgeInsets.only(left: width * 0.04, right: width * 0.04, top: height * 0.01),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                            icon: Icon(Icons.arrow_back_ios, size: 18, color: hintColor),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Text(
                          getTranslated(context, AppString.drawer_setting).toString(),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: hintColor),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(width: 44),
                      ],
                    ),
                  ),
                ]),
              ))),
      body: Container(
        height: height,
        width: width,
        color: back,
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, height * 0.02, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 1,
                    shadowColor: colorWithOpacity(black, 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: SwitchListTile(
                      value: isCallEnable,
                      onChanged: (value) {
                        setState(() {
                          isCallEnable = value;
                          updateVCall(value == true ? 1 : 0);
                        });
                      },
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      title: Text(
                        getTranslated(context, AppString.allowPatientsToVideoCallDirectly).toString(),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: hintColor),
                      ),
                      activeThumbColor: loginButton,
                      activeTrackColor: colorWithOpacity(loginButton, 0.35),
                      inactiveThumbColor: colorWhite,
                      inactiveTrackColor: colorWithOpacity(passwordVisibility, 0.35),
                    ),
                  ),
                  SizedBox(height: 12),
                  buildSettingTile(
                    title: getTranslated(context, AppString.drawer_change_language).toString(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChangeLanguage()),
                      );
                    },
                    icon: Icons.language,
                  ),
                  SizedBox(height: 12),
                  buildSettingTile(
                    title: getTranslated(context, AppString.drawer_change_password).toString(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChangePassword()),
                      );
                    },
                    icon: Icons.lock_outline,
                  ),
                  if (SharedPreferenceHelper.getInt(Preferences.subscription_status) == 1) ...[
                    SizedBox(height: 12),
                    buildSettingTile(
                      title: getTranslated(context, AppString.drawer_subscription_history).toString(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SubscriptionHistory()),
                        );
                      },
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                  SizedBox(height: 12),
                  buildSettingTile(
                    title: getTranslated(context, AppString.delete_account).toString(),
                    onTap: () => _showDeleteAccountDialog(context),
                    icon: Icons.delete_outline_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
        if (_deleteAccountLoading)
          Positioned.fill(
            child: Container(
              color: black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(color: colorWhite),
              ),
            ),
          ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: black.withOpacity(0.12),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_off_rounded, size: 40, color: red),
              ),
              SizedBox(height: 20),
              Text(
                getTranslated(context, AppString.delete_account_question).toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: hintColor,
                ),
              ),
              SizedBox(height: 10),
              Text(
                getTranslated(context, AppString.you_will_lose_all_the_data_and_wont_be_able_to_log_back_in).toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: passwordVisibility,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: passwordVisibility),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        getTranslated(context, AppString.no).toString(),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: hintColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _callDeleteAccount();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        getTranslated(context, AppString.yes).toString(),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorWhite),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logoutUser() async {
    SharedPreferenceHelper.clearPref();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (BuildContext context) => SignIn()),
      ModalRoute.withName('SignIn'),
    );
  }

  Future<void> _callDeleteAccount() async {
    setState(() => _deleteAccountLoading = true);
    try {
      final response = await RestClient(RetroApi().dioData()).deleteAccountRequest();
      if (response.success == true) {
        if (response.message != null && response.message!.isNotEmpty) {
          Fluttertoast.showToast(msg: response.message!);
        }
        await _logoutUser();
      } else {
        if (response.message != null && response.message!.isNotEmpty) {
          Fluttertoast.showToast(msg: response.message!);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
    if (mounted) setState(() => _deleteAccountLoading = false);
  }

  Future<BaseModel<DoctorProfile>> doctorProfile() async {
    DoctorProfile response;

    try {
      response = await RestClient(RetroApi().dioData()).doctorProfile();

      if (response.data?.patientVCall != null) {
        isCallEnable = response.data?.patientVCall == 0 ? false : true;
      } else {
        isCallEnable = false;
      }

      setState(() {});
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  /// update vCall permission
  Future<BaseModel<UpdateProfile>> updateVCall(vCallData) async {
    UpdateProfile response;

    Map<String, dynamic> body = {"patient_vcall": vCallData};
    try {
      response = await RestClient(RetroApi().dioData()).updatePatientVcallRequest(body);

      if (response.success == true) {
        Fluttertoast.showToast(msg: response.msg!);
      }

      setState(() {});
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}

import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:doctro/main.dart';
import 'color_constant.dart';

class CommonFunction {
  //Set Loader SignUp & Sign In
  static onLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(20),
            child: new Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                new CircularProgressIndicator(),
                SizedBox(width: 20),
                new Text(getTranslated(context, AppString.please_wait).toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  static toastMessage(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        //timeInSecForIosWeb: 1,
        backgroundColor: blackOpacity,
        textColor: colorWhite,
        fontSize: 16.0);
  }

  static hideDialog(BuildContext context) {
    Navigator.pop(context);
  }

  //Check Internet Connection Data
  static Future<bool> checkNetwork() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      return true;
    }
    try {
      final lookup = await InternetAddress.lookup('example.com').timeout(Duration(seconds: 3));
      if (lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}
    Fluttertoast.showToast(
      msg: getTranslated(navigatorKey.currentState!.context, AppString.noInternetConnection).toString(),
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    return false;
  }
}

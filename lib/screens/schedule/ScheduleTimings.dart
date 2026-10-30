import 'dart:convert';
import 'package:doctro/model/UpdateTiming.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/base_model.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/model/working_hours.dart';
import 'package:doctro/retrofit/server_error.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class ScheduleTimings extends StatefulWidget {
  const ScheduleTimings({Key? key}) : super(key: key);

  @override
  _ScheduleTimingsState createState() => _ScheduleTimingsState();
}

//Set Value in Switch
bool isSwitched = true;

//Check Status
int? checkStatus;

List<Data> workingReq = [];
int passIndex = 0;
List startsTime = [];
List endsTime = [];

class _ScheduleTimingsState extends State<ScheduleTimings> {
  //Set Loader
  Future? workingHours;

  List<Map<String, dynamic>> listDynamic = [];

  @override
  void initState() {
    workingHours = doctorWorkingHoursFunction();
    super.initState();
  }

  //Show Start & End Time List
  String? startTime;
  String? endTime;

  //Set Height/Width using MediaQuery
  late double width;
  late double height;

  int? id;

  //Set Value edit Button on Click to addMore
  String? _startTime;
  String? _endTime;

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    Color colorWithOpacity(Color color, double opacity) {
      return color.withValues(alpha: opacity);
    }

    return Scaffold(
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
                          getTranslated(context, AppString.schedule_heading).toString(),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: hintColor),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(width: 44),
                      ],
                    ),
                  ),
                ]),
              ))),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: FutureBuilder(
            future: workingHours,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: width * 0.06),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorWithOpacity(black, 0.06),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                getTranslated(context, AppString.schedule_schedule_title).toString(),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: hintColor),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Text(
                                getTranslated(context, AppString.schedule_time_slot).toString(),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: hintColor),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                getTranslated(context, AppString.schedule_status).toString(),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: hintColor),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: height * 0.02),
                        child: ListView.builder(
                            itemCount: workingReq.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              endsTime.clear();
                              startsTime.clear();
                              var parseData = json.decode(workingReq[index].periodList!);
                              for (int i = 0; i < parseData.length; i++) {
                                startsTime.add(parseData[i]['start_time']);
                                endsTime.add(parseData[i]['end_time']);
                              }
                              final timeSlots = List.generate(
                                startsTime.length,
                                (slotIndex) => "${startsTime[slotIndex]} ${getTranslated(context, AppString.to).toString()} ${endsTime[slotIndex]}",
                              );
                              return Container(
                                margin: EdgeInsets.only(bottom: height * 0.015),
                                child: Card(
                                  elevation: 1,
                                  shadowColor: colorWithOpacity(black, 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            workingReq[index].dayIndex!,
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: hintColor),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 6,
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: timeSlots
                                                .map(
                                                  (slot) => Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: colorWithOpacity(loginButton, 0.12),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      slot,
                                                      style: TextStyle(fontSize: 12, color: hintColor, fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.topRight,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: colorWithOpacity(tabBar, 0.4),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.edit, size: 18, color: hintColor),
                                                onPressed: () async {
                                                  passIndex = index;
                                                  id = workingReq[index].id;
                                                  checkStatus = workingReq[index].status;
                                                  var convertData;
                                                  listDynamic.clear();
                                                  convertData = json.decode(workingReq[index].periodList!);
                                                  startTime = convertData[0]['start_time'];
                                                  endTime = convertData[0]['end_time'];

                                                  TextEditingController startController = TextEditingController();
                                                  TextEditingController endController = TextEditingController();

                                                  for (int k = 0; k < convertData.length; k++) {
                                                    startController.text = convertData[k]['start_time'];
                                                    endController.text = convertData[k]['end_time'];

                                                    listDynamic.add({
                                                      "start_time": startController.text,
                                                      "end_time": endController.text,
                                                    });
                                                  }

                                                  showDialog(
                                                      barrierDismissible: false,
                                                      context: context,
                                                      builder: (context) {
                                                        return StatefulBuilder(
                                                          builder: (context, myState) {
                                                            return AlertDialog(
                                                              insetPadding: EdgeInsets.all(14),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(18),
                                                              ),
                                                              titlePadding: EdgeInsets.fromLTRB(20, 18, 20, 0),
                                                              contentPadding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                                                              actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                                                              title: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    getTranslated(context, AppString.schedule_heading).toString(),
                                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: hintColor),
                                                                  ),
                                                                  SizedBox(height: 8),
                                                                  Container(
                                                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                                    decoration: BoxDecoration(
                                                                      color: colorWithOpacity(tabBar, 0.35),
                                                                      borderRadius: BorderRadius.circular(12),
                                                                    ),
                                                                    child: SwitchScreen(checkStatus),
                                                                  ),
                                                                ],
                                                              ),
                                                              content: Container(
                                                                height: height * 0.34,
                                                                width: width * 1.0,
                                                                child: Column(
                                                                  children: [
                                                                    Flexible(
                                                                      child: ListView.builder(
                                                                        itemCount: listDynamic.length,
                                                                        itemBuilder: (context, index) {
                                                                          return Container(
                                                                            margin: EdgeInsets.only(bottom: 12),
                                                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                                            decoration: BoxDecoration(
                                                                              color: colorWhite,
                                                                              borderRadius: BorderRadius.circular(14),
                                                                              border: Border.all(color: divider),
                                                                            ),
                                                                            child: Column(
                                                                              children: [
                                                                                Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Text(
                                                                                      getTranslated(context, AppString.schedule_start_time).toString(),
                                                                                      style: TextStyle(fontSize: 13, color: passwordVisibility, fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                    Text(
                                                                                      getTranslated(context, AppString.schedule_end_time).toString(),
                                                                                      style: TextStyle(fontSize: 13, color: passwordVisibility, fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                    SizedBox(width: 28),
                                                                                  ],
                                                                                ),
                                                                                SizedBox(height: 8),
                                                                                Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    InkWell(
                                                                                      onTap: () async {
                                                                                        List tempChange = [];
                                                                                        final TimeOfDay? result = await showTimePicker(
                                                                                            context: context,
                                                                                            initialTime: TimeOfDay.now(),
                                                                                            builder: (context, child) {
                                                                                              return MediaQuery(
                                                                                                  data: MediaQuery.of(context).copyWith(
                                                                                                      alwaysUse24HourFormat: false),
                                                                                                  child: child!);
                                                                                            });
                                                                                        if (result != null) {
                                                                                          myState(() {
                                                                                            DateTime tempDate = DateFormat("hh:mm").parse(result.hour.toString() + ":" + result.minute.toString());
                                                                                            var dateFormat = DateFormat("hh:mm a");
                                                                                            String finalTime = dateFormat.format(tempDate);

                                                                                            _startTime = finalTime;

                                                                                            var decodeData = json.decode(workingReq[passIndex].periodList!);
                                                                                            for (int i = 0; i < listDynamic.length; i++) {
                                                                                              tempChange.add(decodeData[i]);
                                                                                            }

                                                                                            tempChange[index] = {"start_time": _startTime, "end_time": listDynamic[index]["end_time"]};

                                                                                            listDynamic[index] = {"start_time": _startTime, "end_time": listDynamic[index]["end_time"]};
                                                                                          });
                                                                                        }
                                                                                        setState(() {
                                                                                          workingReq[passIndex].periodList = JsonEncoder().convert(tempChange);
                                                                                        });
                                                                                      },
                                                                                      child: Container(
                                                                                        height: height * 0.065,
                                                                                        width: width * 0.30,
                                                                                        alignment: AlignmentDirectional.center,
                                                                                        decoration: BoxDecoration(
                                                                                          color: colorWithOpacity(loginButton, 0.12),
                                                                                          borderRadius: BorderRadius.circular(12),
                                                                                        ),
                                                                                        child: Text(
                                                                                          listDynamic[index]['start_time'].toString(),
                                                                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hintColor),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    InkWell(
                                                                                      onTap: () async {
                                                                                        List tempChange = [];
                                                                                        final TimeOfDay? result = await showTimePicker(
                                                                                            context: context,
                                                                                            initialTime: TimeOfDay.now(),
                                                                                            builder: (context, child) {
                                                                                              return MediaQuery(
                                                                                                  data: MediaQuery.of(context).copyWith(
                                                                                                    alwaysUse24HourFormat: false,
                                                                                                  ),
                                                                                                  child: child!);
                                                                                            });
                                                                                        if (result != null) {
                                                                                          myState(() {
                                                                                            DateTime tempDate = DateFormat("hh:mm").parse(result.hour.toString() + ":" + result.minute.toString());
                                                                                            var dateFormat = DateFormat("hh:mm a");
                                                                                            String finalTime = dateFormat.format(tempDate);

                                                                                            _endTime = finalTime;

                                                                                            var decodeData = json.decode(workingReq[passIndex].periodList!);
                                                                                            for (int i = 0; i < listDynamic.length; i++) {
                                                                                              tempChange.add(decodeData[i]);
                                                                                            }

                                                                                            tempChange[index] = {"start_time": listDynamic[index]["start_time"], "end_time": _endTime};

                                                                                            listDynamic[index] = {"start_time": listDynamic[index]["start_time"], "end_time": _endTime};
                                                                                          });
                                                                                        }
                                                                                        setState(() {
                                                                                          workingReq[passIndex].periodList = JsonEncoder().convert(tempChange);
                                                                                        });
                                                                                      },
                                                                                      child: Container(
                                                                                        height: height * 0.065,
                                                                                        width: width * 0.30,
                                                                                        alignment: AlignmentDirectional.center,
                                                                                        decoration: BoxDecoration(
                                                                                          color: colorWithOpacity(loginButton, 0.12),
                                                                                          borderRadius: BorderRadius.circular(12),
                                                                                        ),
                                                                                        child: Text(
                                                                                          listDynamic[index]['end_time'].toString(),
                                                                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hintColor),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    index == 0
                                                                                        ? SizedBox(width: 28)
                                                                                        : InkWell(
                                                                                            child: Container(
                                                                                              height: 28,
                                                                                              width: 28,
                                                                                              decoration: BoxDecoration(
                                                                                                color: colorWithOpacity(red, 0.12),
                                                                                                borderRadius: BorderRadius.circular(8),
                                                                                              ),
                                                                                              child: Icon(Icons.delete, size: 16, color: red),
                                                                                            ),
                                                                                            onTap: () {
                                                                                              myState(() {
                                                                                                listDynamic.removeAt(index);
                                                                                              });
                                                                                            },
                                                                                          )
                                                                                  ],
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                    Align(
                                                                      alignment: Alignment.centerLeft,
                                                                      child: InkWell(
                                                                        onTap: () {
                                                                          myState(() {
                                                                            listDynamic.add({
                                                                              "start_time": getTranslated(context, AppString.schedule_start_time).toString(),
                                                                              "end_time": getTranslated(context, AppString.schedule_end_time).toString(),
                                                                            });

                                                                            var decodeData = json.decode(workingReq[passIndex].periodList!);
                                                                            decodeData.add({
                                                                              "start_time": getTranslated(context, AppString.schedule_start_time).toString(),
                                                                              "end_time": getTranslated(context, AppString.schedule_end_time).toString(),
                                                                            });
                                                                            workingReq[passIndex].periodList = JsonEncoder().convert(decodeData);
                                                                          });
                                                                        },
                                                                        child: Container(
                                                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                          decoration: BoxDecoration(
                                                                            color: colorWithOpacity(loginButton, 0.15),
                                                                            borderRadius: BorderRadius.circular(12),
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: [
                                                                              Container(
                                                                                height: 26,
                                                                                width: 26,
                                                                                decoration: BoxDecoration(
                                                                                  color: colorWithOpacity(loginButton, 0.35),
                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                ),
                                                                                child: Icon(Icons.add, size: 18, color: hintColor),
                                                                              ),
                                                                              SizedBox(width: 10),
                                                                              Text(
                                                                                getTranslated(context, AppString.schedule_add_more).toString(),
                                                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: hintColor),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              actions: <Widget>[
                                                                SizedBox(
                                                                  width: double.infinity,
                                                                  child: ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: loginButton,
                                                                      foregroundColor: colorWhite,
                                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                      padding: EdgeInsets.symmetric(vertical: 12),
                                                                    ),
                                                                    child: Text(getTranslated(context, AppString.schedule_ok_button).toString()),
                                                                    onPressed: () {
                                                                      bool isOk = true;

                                                                      for (int i = 0; i < listDynamic.length; i++) {
                                                                        if (listDynamic[i]['start_time'] == getTranslated(context, AppString.schedule_start_time).toString() ||
                                                                            listDynamic[i]['end_time'] == getTranslated(context, AppString.schedule_end_time).toString()) {
                                                                          isOk = false;
                                                                        }
                                                                      }

                                                                      if (isOk == true) {
                                                                        myState(() {
                                                                          updateHours();
                                                                          Navigator.pop(context);
                                                                        });
                                                                      } else {
                                                                        Fluttertoast.showToast(
                                                                          msg: getTranslated(context, AppString.please_enter_start_end_time).toString(),
                                                                          toastLength: Toast.LENGTH_SHORT,
                                                                          gravity: ToastGravity.BOTTOM,
                                                                        );
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      )
                    ],
                  ),
                );
              }
            }),
      ),
    );
  }

  Future<BaseModel<Workinghours>> doctorWorkingHoursFunction() async {
    Workinghours response;

    try {
      workingReq.clear();
      response = await RestClient(RetroApi().dioData()).workinghours();
      setState(() {
        workingReq.addAll(response.data!);
      });
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<UpdateTiming>> updateHours() async {
    List hours = [];

    for (int i = 0; i < listDynamic.length; i++) {
      Map<String, dynamic> mapEducationData = {
        "start_time": listDynamic[i]["start_time"].toString().toLowerCase(),
        "end_time": listDynamic[i]["end_time"].toString().toLowerCase(),
      };
      hours.add(mapEducationData);
    }

    Map<String, dynamic> body = {"id": id.toString(), "period_list": hours, "status": isSwitched == true ? 1 : 0};
    UpdateTiming response;
    try {
      response = await RestClient(RetroApi().dioData()).updateTimingRequest(body);
      doctorWorkingHoursFunction();
      Fluttertoast.showToast(
        msg: response.msg!,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}

class SwitchScreen extends StatefulWidget {
  SwitchScreen(int? checkStatus);

  @override
  SwitchClass createState() => new SwitchClass();
}

class SwitchClass extends State {
  @override
  void initState() {
    super.initState();
    if (checkStatus == 1) {
      setState(() {
        isSwitched = true;
      });
    } else {
      setState(() {
        isSwitched = false;
      });
    }
  }

  void toggleSwitch(bool value) {
    if (isSwitched == true) {
      setState(() {
        isSwitched = false;
      });
    } else {
      setState(() {
        isSwitched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(
        children: [
          Container(
            child: Text(getTranslated(context, AppString.schedule_day_status).toString()),
          ),
          Transform.scale(
              scale: 1.2,
              child: Switch(
                onChanged: toggleSwitch,
                value: isSwitched,
                activeThumbColor: colorWhite,
                activeTrackColor: subheading,
                inactiveThumbColor: colorWhite,
                inactiveTrackColor: red,
              )),
        ],
      ),
    ]);
  }
}

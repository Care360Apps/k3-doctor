import 'dart:async';
import 'dart:io';

import 'package:doctro/VideoCall/overlay_handler.dart';
import 'package:doctro/VideoCall/overlay_service.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/model/doctor_profile.dart';
import 'package:doctro/model/setting.dart';
import 'package:doctro/model/video_call_history_add_model.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/base_model.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:doctro/retrofit/server_error.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pip_view/pip_view.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/screens/home page/login_home.dart';
import 'package:doctro/screens/videoCall/model/doctorAgoraTokenGenerateModel.dart';

class VideoCall extends StatefulWidget {

  final bool callEnd;
  final int? id;
  final String? flag;

  VideoCall({
    required this.callEnd,
    this.id,
    this.flag,
  });
  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool muted = false;
  bool mutedVideo = false;
  RtcEngine? _engine;
  String? appId;
  int uid = 0;
  String? token;
  String? channelName;
  int? doctorId = 0;
  ChannelMediaOptions options = const ChannelMediaOptions(
    clientRoleType: ClientRoleType.clientRoleBroadcaster,
    channelProfile: ChannelProfileType.channelProfileCommunication,
  );

  int? callDuration = 0;
  String? callTime = "";
  String? callDate = "";

  bool _isDisposed = false;
  bool _isEnding = false;
  bool _leaveRequested = false;
  bool _released = false;
  bool _handledLeave = false;
  Timer? _leaveTimeoutTimer;

  Future<bool> _isPhysicalDeviceForVideoCapture() async {
    // iOS Simulator has no real camera capture pipeline; Agora can crash after join.
    // Prefer disabling local video capture when running on a simulator.
    if (!Platform.isIOS) return true;
    try {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      return iosInfo.isPhysicalDevice ?? true;
    } catch (_) {
      return true;
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  Future<void> _leaveChannelOnce() async {
    if (_leaveRequested) return;
    _leaveRequested = true;

    final engine = _engine;
    if (engine == null) return;

    try {
      await engine.stopPreview();
    } catch (_) {}

    try {
      await engine.leaveChannel();
    } catch (e, st) {
      // If Agora is already leaving/destroyed, ignore.
      debugPrint('Agora leaveChannel error: $e\n$st');
    }
  }

  Future<void> _releaseEngineOnce() async {
    if (_released) return;
    _released = true;

    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = null;

    final engine = _engine;
    _engine = null;
    if (engine == null) return;

    try {
      await engine.release();
    } catch (e, st) {
      debugPrint('Agora release error: $e\n$st');
    }
  }

  void _requestEndCall({String reason = 'user'}) {
    if (_isEnding) return;
    _isEnding = true;

    _safeSetState(() {
      _localUserJoined = false;
      _remoteUid = null;
    });

    unawaited(_leaveChannelOnce());
  }

  @override
  void initState() {
    debugPrint("Call End : ${widget.callEnd}\tID : ${widget.id}\tFlag : ${widget.flag}");
    super.initState();
    settingRequest();
    offset = const Offset(20.0, 50.0);
  }

  Offset offset = Offset.zero;
  int? boxNumberIsDragged;

  Widget _toolbar() {
    return Consumer<OverlayHandlerProvider>(
      builder: (context, overlayProvider, _) {
        return Container(
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.symmetric(vertical: overlayProvider.inPipMode == true ? 20 : 45),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: RawMaterialButton(
                  onPressed: _onToggleMute,
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? colorWhite : loginButton,
                    size: overlayProvider.inPipMode == true ? 12.0 : 15.0,
                  ),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? loginButton : colorWhite,
                  padding: EdgeInsets.all(overlayProvider.inPipMode == true ? 5.0 : 12.0),
                ),
              ),
              Expanded(
                child: RawMaterialButton(
                  onPressed: () => _onCallEnd(context),
                  child: Icon(
                    Icons.call_end,
                    color: colorWhite,
                    size: overlayProvider.inPipMode == true ? 15.0 : 30.0,
                  ),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: red,
                  padding: EdgeInsets.all(overlayProvider.inPipMode == true ? 5.0 : 15.0),
                ),
              ),
              Expanded(
                child: RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  child: Icon(
                    Icons.switch_camera,
                    color: loginButton,
                    size: overlayProvider.inPipMode == true ? 12.0 : 15.0,
                  ),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: colorWhite,
                  padding: EdgeInsets.all(overlayProvider.inPipMode == true ? 5.0 : 12.0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onCallEnd(BuildContext context) {
    _requestEndCall();
  }

  void _onToggleMute() {
    _safeSetState(() {
      muted = !muted;
    });
    _engine?.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine?.switchCamera();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    final resolvedAppId = (appId != null && appId!.isNotEmpty) ? appId! : (SharedPreferenceHelper.getString(Preferences.agoraAppId) ?? '');
    if (resolvedAppId.isEmpty) {
      debugPrint('Agora init skipped: missing appId');
      return;
    }

    final canUseLocalVideoCapture = await _isPhysicalDeviceForVideoCapture();

    final engine = await createAgoraRtcEngine();
    _engine = engine;
    _leaveRequested = false;
    _released = false;
    _handledLeave = false;
    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_released) return;
      debugPrint('Agora leave timeout reached, forcing engine release.');
      unawaited(_releaseEngineOnce());
    });

    await engine.initialize(RtcEngineContext(appId: resolvedAppId));
    await engine.enableVideo();

    if (!canUseLocalVideoCapture) {
      debugPrint('iOS simulator detected: disabling local video capture to avoid crash.');
      try {
        await engine.enableLocalVideo(false);
      } catch (_) {}
    }

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("Local user uid : ${connection.localUid} joined the channel");
          _safeSetState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print("Remote user uid:$remoteUid joined the channel");
          DateTime now = DateTime.now();
          callTime = DateFormat('h:mm a').format(now);
          callDate = DateFormat('yyyy-MM-dd').format(now);
          _safeSetState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (_isDisposed) return;
          _safeSetState(() {
            _remoteUid = null;
          });
          Fluttertoast.showToast(msg: "Call Ended", toastLength: Toast.LENGTH_SHORT);
          _requestEndCall(reason: 'remote_offline');
        },
        onLeaveChannel: (RtcConnection connection, RtcStats details) {
          if (_handledLeave) return;
          _handledLeave = true;

          _leaveTimeoutTimer?.cancel();
          _leaveTimeoutTimer = null;

          callDuration = details.duration;
          _safeSetState(() {});

          if (widget.flag == "OutGoing") {
            if (mounted) {
              OverlayService().removeVideosOverlay(
                context,
                VideoCall(
                  id: widget.id,
                  callEnd: false,
                ),
              );
            }
          } else {
            if (callTime != "" && callDate != "" && widget.callEnd == false) {
              unawaited(callApiAddVideoCallHistory());
            }
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginHomeScreen(chat: "")));
            }
          }

          // Release only after leave callback to avoid native race/crash.
          unawaited(_releaseEngineOnce());
        },
      ),
    );

    if (canUseLocalVideoCapture) {
      await engine.startPreview();
    }

    final joinChannelId = (channelName ?? '').trim();
    if (joinChannelId.isEmpty) {
      debugPrint('Agora join skipped: missing channelName');
      Fluttertoast.showToast(msg: 'Unable to start video call. Please try again.');
      return;
    }

    final joinToken = (token == null || token!.isEmpty || token!.toLowerCase() == 'null') ? '' : token!;

    engine.joinChannel(
      token: joinToken,
      channelId: joinChannelId,
      uid: uid,
      options: options,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = null;

    // If the user didn't explicitly end, request a leave.
    if (!_isEnding) {
      unawaited(_leaveChannelOnce());
    }
    // Always release (idempotent), but avoid releasing twice.
    unawaited(_releaseEngineOnce());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return PIPView(
      builder: (context, isFloating) {
        return Scaffold(
          body: Consumer<OverlayHandlerProvider>(
            builder: (context, overlayProvider, _) {
              return InkWell(
                onTap: () {
                  Provider.of<OverlayHandlerProvider>(context, listen: false).disablePip();
                },
                child: Stack(
                  children: [
                    Container(
                      color: grey,
                      child: Center(
                        child: _remoteVideo(),
                      ),
                    ),
                    widget.callEnd == true
                        ? Container()
                        : Stack(
                            children: [
                              Positioned(
                                left: offset.dx,
                                top: offset.dy,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      if (offset.dx > 0.0 &&
                                          (offset.dx + 150) < width &&
                                          offset.dy > 0.0 &&
                                          (offset.dy + 200) < height) {
                                        offset = Offset(offset.dx + details.delta.dx, offset.dy + details.delta.dy);
                                      } else {
                                        offset = Offset(details.delta.dx + 20, details.delta.dy + 50);
                                      }
                                    });
                                  },
                                  child: Consumer<OverlayHandlerProvider>(
                                    builder: (context, overlayProvider, _) {
                                      return SizedBox(
                                        width: overlayProvider.inPipMode == true ? 80 : 150,
                                        height: overlayProvider.inPipMode == true ? 80 : 200,
                                        child: Center(
                                          child: _localUserJoined ? _localPreview() : const CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                    _toolbar(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<BaseModel<DoctorProfile>> doctorProfile() async {
    DoctorProfile response;
    try {
      response = await RestClient(RetroApi().dioData()).doctorProfile();
      if (response.success == true) {
        token = response.data!.agoraToken;
        channelName = response.data!.channelName;
        doctorId = response.data!.id;
        await initAgora();
      }
      setState(() {});
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<VideoCallModel>> agoraTokenGenerateDoctor() async {
    VideoCallModel response;
    Map<String, dynamic> body = {"to_id": widget.id};
    try {
      response = await RestClient(RetroApi().dioData()).generateDoctorAgoraTokenCall(body);
      if (response.success == true) {
        channelName = response.data!.cn;
        token = response.data!.token;
        await initAgora();
      }
      setState(() {});
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<Setting>> settingRequest() async {
    Setting response;
    try {
      response = await RestClient(RetroApi().dioData()).settingRequest();
      appId = response.data!.agoraAppId;
      if (widget.flag != "OutGoing") {
        await doctorProfile();
      } else {
        await agoraTokenGenerateDoctor();
      }
      setState(() {});
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<VideoCallHistoryAddModel>> callApiAddVideoCallHistory() async {
    VideoCallHistoryAddModel response;
    Map<String, dynamic> body = {
      "user_id": widget.id,
      "date": callDate,
      "start_time": callTime,
      "duration": callDuration,
      "doctor_id": doctorId,
    };
    try {
      response = await RestClient(RetroApi().dioData()).videoCallHistoryAddRequest(body);
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Widget _localPreview() {
    final engine = _engine;
    if (engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _remoteVideo() {
    // Do not expose RTC credentials or channel identifiers in UI rebuild logs.
    final engine = _engine;
    if (_remoteUid != null && engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: channelName),
        ),
      );
    } else {
      return widget.callEnd == true
          ? ScalingText(
              getTranslated(context, AppString.disconnect_call).toString(),
              style: TextStyle(fontSize: 16, color: cardText),
            )
          : widget.flag == "OutGoing"
              ? ScalingText(
                  getTranslated(context, AppString.ringing).toString(),
                  style: TextStyle(fontSize: 16, color: cardText),
                )
              : ScalingText(
                  getTranslated(context,AppString.connect_call).toString(),
                  style: TextStyle(fontSize: 16, color: cardText),
                );
    }
  }
}
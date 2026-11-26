import 'dart:async';
import 'dart:io';

import 'package:doctro/VideoCall/overlay_handler.dart';
import 'package:doctro/security/care360_agora_join_policy.dart';
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

import 'package:doctro/security/consultation_session_client.dart';

class VideoCall extends StatefulWidget {
  final int? appointmentId;
  final ConsultationSessionClient? sessionClient;

  final bool callEnd;
  final int? id;
  final String? flag;

  VideoCall({
    required this.callEnd,
    this.appointmentId,
    this.sessionClient,
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
  Timer? _remoteReconnectTimer;
  Timer? _renewalTimer;
  ConsultationCredentials? _credentials;
  bool _renewing = false;
  Timer? _statusTimer;
  bool _checkingStatus = false;
  bool _statusWarningShown = false;

  void _scheduleStatusCheck() {
    _statusTimer?.cancel();
    if (_isDisposed || _isEnding || _credentials == null) return;
    _statusTimer = Timer(const Duration(seconds: 15), () {
      unawaited(_checkSessionStatus());
    });
  }

  Future<void> _checkSessionStatus() async {
    final credentials = _credentials;
    final client = widget.sessionClient;
    final id = widget.appointmentId;
    if (_checkingStatus || _isDisposed || _isEnding ||
        credentials == null || client == null || id == null) return;
    _checkingStatus = true;
    try {
      final state = await client.status(id, expectedSessionId: credentials.sessionId);
      if (_isDisposed || _isEnding) return;
      _statusWarningShown = false;
      if (state != 'active') {
        Fluttertoast.showToast(msg: 'Consultation has ended.');
        _requestEndCall(reason: 'server_closed');
      }
    } on ConsultationAccessRevoked {
      if (!_isDisposed && !_isEnding) {
        Fluttertoast.showToast(msg: 'Consultation access ended.');
        _requestEndCall(reason: 'access_revoked');
      }
    } on FormatException {
      if (!_isDisposed && !_isEnding) {
        _requestEndCall(reason: 'invalid_session');
      }
    } catch (_) {
      if (!_isDisposed && !_isEnding && !_statusWarningShown) {
        _statusWarningShown = true;
        Fluttertoast.showToast(msg: 'Unable to verify consultation status. Retrying.');
      }
    } finally {
      _checkingStatus = false;
      _scheduleStatusCheck();
    }
  }

  Future<void> _notifySessionEnd() async {
    final client = widget.sessionClient;
    final id = widget.appointmentId;
    if (_credentials == null || client == null || id == null) return;
    try {
      await client.end(id);
    } catch (_) {
      if (mounted && !_isDisposed) {
        Fluttertoast.showToast(msg: 'Call closed locally. Server confirmation unavailable.');
      }
    }
  }

  void _scheduleRenewal() {
    _renewalTimer?.cancel();
    final credentials = _credentials;
    if (credentials == null || _isDisposed || _isEnding) return;
    final remaining = credentials.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _requestEndCall(reason: 'credential_expiry');
      return;
    }
    final delay = remaining - const Duration(seconds: 60);
    final wait = delay > const Duration(seconds: 10) ? delay : const Duration(seconds: 10);
    _renewalTimer = Timer(wait < remaining ? wait : remaining, () {
      unawaited(_renewCredentials());
    });
  }

  Future<void> _renewCredentials() async {
    final client = widget.sessionClient;
    final previous = _credentials;
    final engine = _engine;
    if (client == null || previous == null || engine == null || _renewing || _isDisposed || _isEnding) return;
    if (!previous.expiresAt.isAfter(DateTime.now())) {
      _requestEndCall(reason: 'credential_expiry');
      return;
    }
    _renewing = true;
    try {
      final next = await client.credentials(widget.appointmentId!, previous: previous);
      if (_isDisposed || _isEnding || _engine != engine) return;
      if (!next.expiresAt.isAfter(previous.expiresAt)) {
        _scheduleRenewal();
        return;
      }
      await engine.renewToken(next.token).timeout(const Duration(seconds: 10));
      if (_isDisposed || _isEnding) return;
      _credentials = next;
      _scheduleRenewal();
    } on ConsultationAccessRevoked {
      if (!_isDisposed && !_isEnding) _requestEndCall(reason: 'access_revoked');
    } on FormatException {
      if (!_isDisposed && !_isEnding) _requestEndCall(reason: 'invalid_session');
    } catch (_) {
      if (_isDisposed || _isEnding) return;
      if (previous.expiresAt.difference(DateTime.now()).inSeconds <= 20) {
        Fluttertoast.showToast(msg: 'Secure consultation expired.');
        _requestEndCall(reason: 'credential_expiry');
      } else {
        _renewalTimer?.cancel();
        _renewalTimer = Timer(const Duration(seconds: 10), () => unawaited(_renewCredentials()));
      }
    } finally {
      _renewing = false;
    }
  }

  Future<void> _startAppointmentSession() async {
    try {
      final id = widget.appointmentId;
      if (id == null || id <= 0 || widget.sessionClient == null) throw StateError('Missing session configuration');
      final credentials = await widget.sessionClient!.credentials(id);
      if (!mounted || _isDisposed || _isEnding) return;
      if (credentials.uid != 2) throw StateError('Invalid professional identity');
      _credentials = credentials;
      token = credentials.token;
      channelName = credentials.channel;
      appId = credentials.appId;
      uid = credentials.uid;
      await initAgora();
      if (!_isDisposed && !_isEnding && _engine != null) {
        _scheduleRenewal();
        _scheduleStatusCheck();
      }
    } catch (_) {
      if (mounted && !_isDisposed) Fluttertoast.showToast(msg: 'Secure consultation unavailable.');
      await _releaseEngineOnce();
    }
  }

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

    // The fallback release timeout starts only when leaving, never when a
    // consultation starts. Otherwise calls are incorrectly cut off at 10s.
    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!_released) unawaited(_releaseEngineOnce());
    });

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
    _statusTimer?.cancel();
    _renewalTimer?.cancel();
    if (reason == 'user') unawaited(_notifySessionEnd());
    _remoteReconnectTimer?.cancel();
    _remoteReconnectTimer = null;

    _safeSetState(() {
      _localUserJoined = false;
      _remoteUid = null;
    });

    if (widget.appointmentId != null && _engine == null && mounted) {
      Navigator.of(context).pop();
      return;
    }
    unawaited(_leaveChannelOnce());
  }

  @override
  void initState() {
    super.initState();
    if (widget.sessionClient != null || widget.appointmentId != null) {
      unawaited(_startAppointmentSession());
    } else {
      settingRequest();
    }
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
                child: Tooltip(
                  message: mutedVideo ? 'Resume video' : 'Switch to audio-only',
                  child: RawMaterialButton(
                    onPressed: _onToggleVideo,
                    child: Icon(
                      mutedVideo ? Icons.videocam_off : Icons.videocam,
                      color: mutedVideo ? colorWhite : loginButton,
                      size: overlayProvider.inPipMode == true ? 12.0 : 15.0,
                    ),
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: mutedVideo ? loginButton : colorWhite,
                    padding: EdgeInsets.all(
                        overlayProvider.inPipMode == true ? 5.0 : 12.0),
                  ),
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

  Future<void> _onToggleVideo() async {
    final engine = _engine;
    if (engine == null || _isDisposed || _isEnding) return;
    final nextMuted = !mutedVideo;
    if (!nextMuted) {
      final granted = await Permission.camera.request();
      if (!mounted || _isDisposed || !granted.isGranted ||
          !await _isPhysicalDeviceForVideoCapture()) return;
      if (!mounted || _isDisposed || _isEnding || _engine != engine) return;
    }
    try {
      if (!nextMuted) await engine.enableLocalVideo(true);
      // Only suppress outgoing video; keep the authorized Agora audio session.
      await engine.muteLocalVideoStream(nextMuted);
      _safeSetState(() => mutedVideo = nextMuted);
    } catch (_) {
      Fluttertoast.showToast(msg: 'Unable to change video mode.');
    }
  }

  void _onSwitchCamera() {
    if (!mutedVideo && !_isEnding && !_isDisposed) _engine?.switchCamera();
  }

  Future<void> initAgora() async {
    final resolvedAppId = (appId != null && appId!.isNotEmpty)
        ? appId!.trim()
        : SharedPreferenceHelper.getString(Preferences.agoraAppId);
    if (!Care360AgoraJoinPolicy.canJoin(
      sessionToken: SharedPreferenceHelper.getString(Preferences.auth_token),
      agoraToken: token,
      channelId: channelName,
      appId: resolvedAppId,
      outgoing: widget.flag == 'OutGoing',
      remoteUserId: widget.id,
    )) {
      Fluttertoast.showToast(
          msg: 'Secure video session unavailable. Please refresh and retry.');
      return;
    }

    final grants = await [Permission.microphone, Permission.camera].request();
    if (grants[Permission.microphone]?.isGranted != true) {
      Fluttertoast.showToast(msg: 'Microphone permission is required for calls.');
      return;
    }
    if (!mounted || _isDisposed || _isEnding) return;
    final physicalVideoCapture = await _isPhysicalDeviceForVideoCapture();
    final canUseLocalVideoCapture = physicalVideoCapture &&
        grants[Permission.camera]?.isGranted == true;
    if (!mounted || _isDisposed || _isEnding) return;

    final engine = await createAgoraRtcEngine();
    if (!mounted || _isDisposed || _isEnding) {
      await engine.release();
      return;
    }
    _engine = engine;
    _leaveRequested = false;
    _released = false;
    _handledLeave = false;
    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = null;

    await engine.initialize(RtcEngineContext(appId: resolvedAppId));
    if (_isDisposed || _isEnding || _engine != engine) return;
    await engine.enableVideo();
    if (_isDisposed || _isEnding || _engine != engine) return;

    if (!canUseLocalVideoCapture) {
      _safeSetState(() => mutedVideo = true);
      try {
        await engine.enableLocalVideo(false);
      } catch (_) {}
    }

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          // Never log clinical call participant identifiers.
          _safeSetState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (_isDisposed || _isEnding || (_credentials != null && remoteUid != 1)) return;
          final reconnecting = _remoteReconnectTimer != null;
          _remoteReconnectTimer?.cancel();
          _remoteReconnectTimer = null;
          if (reconnecting) Fluttertoast.showToast(msg: 'Participant reconnected.');
          // Presence is displayed in-app without logging identity.
          DateTime now = DateTime.now();
          if (callTime == null || callTime!.isEmpty) {
            callTime = DateFormat('h:mm a').format(now);
            callDate = DateFormat('yyyy-MM-dd').format(now);
          }
          _safeSetState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (_isDisposed || _isEnding || _remoteUid != remoteUid) return;
          _safeSetState(() => _remoteUid = null);
          if (reason == UserOfflineReasonType.userOfflineDropped) {
            Fluttertoast.showToast(msg: 'Connection interrupted. Waiting for participant to reconnect.');
            _remoteReconnectTimer?.cancel();
            _remoteReconnectTimer = Timer(const Duration(seconds: 45), () {
              _remoteReconnectTimer = null;
              if (_isDisposed || _isEnding || _remoteUid != null) return;
              Fluttertoast.showToast(msg: 'Participant could not reconnect.');
              _requestEndCall(reason: 'remote_reconnect_timeout');
            });
            return;
          }
          Fluttertoast.showToast(msg: 'Call ended');
          _requestEndCall(reason: 'remote_offline');
        },
        onTokenPrivilegeWillExpire: (connection, expiringToken) {
          unawaited(_renewCredentials());
        },
        onLeaveChannel: (RtcConnection connection, RtcStats details) {
          if (_handledLeave) return;
          _handledLeave = true;
          _isEnding = true;
          _statusTimer?.cancel();
          _renewalTimer?.cancel();
          _remoteReconnectTimer?.cancel();
          _remoteReconnectTimer = null;

          _leaveTimeoutTimer?.cancel();
          _leaveTimeoutTimer = null;

          callDuration = details.duration;
          _safeSetState(() {});

          if (widget.appointmentId != null) {
            if (mounted && !_isDisposed && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.of(context).pop();
            }
            unawaited(_releaseEngineOnce());
            return;
          }
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
            if (_credentials == null && callTime != "" && callDate != "" && widget.callEnd == false) {
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

    if (_isDisposed || _isEnding || _engine != engine) return;
    final joinChannelId = channelName!.trim();
    final joinToken = token!.trim();

    await engine.joinChannel(
      token: joinToken,
      channelId: joinChannelId,
      uid: uid,
      options: options,
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _renewalTimer?.cancel();
    _remoteReconnectTimer?.cancel();
    _remoteReconnectTimer = null;
    _isDisposed = true;
    _leaveTimeoutTimer?.cancel();
    _leaveTimeoutTimer = null;

    // Leave before releasing the native engine. Starting both operations
    // independently caused a race on Android/iOS and occasional call crashes.
    unawaited(_leaveChannelOnce().whenComplete(_releaseEngineOnce));

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
      if (response.success == true && response.data != null) {
        token = response.data!.agoraToken;
        channelName = response.data!.channelName;
        doctorId = response.data!.id;
        await initAgora();
      }
      if (mounted) setState(() {});
    } catch (error, stacktrace) {
      // Do not print server errors, tokens or channel identifiers.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<VideoCallModel>> agoraTokenGenerateDoctor() async {
    VideoCallModel response;
    Map<String, dynamic> body = {"to_id": widget.id};
    try {
      response = await RestClient(RetroApi().dioData()).generateDoctorAgoraTokenCall(body);
      if (response.success == true && response.data != null) {
        channelName = response.data!.cn;
        token = response.data!.token;
        await initAgora();
      }
      setState(() {});
    } catch (error, stacktrace) {
      // No clinical session identifiers in diagnostic logs.
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
      // No clinical session identifiers in diagnostic logs.
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
      // No clinical session identifiers in diagnostic logs.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Widget _localPreview() {
    final engine = _engine;
    if (engine == null) return const SizedBox.shrink();
    if (mutedVideo) {
      return Center(
        child: Semantics(
          label: 'Your camera is off. Audio-only consultation is active.',
          child: Icon(Icons.mic, size: 36),
        ),
      );
    }
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

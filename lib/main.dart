import 'startup_gate.dart';
import 'dart:async';
import'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/localization/language_localization.dart';
import 'package:doctro/model/setting.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/server_error.dart';
import 'package:doctro/screens/setting/ChangePassword.dart';
import 'package:doctro/screens/setting/Setting.dart';
import 'package:doctro/screens/auth/SignIn.dart';
import 'package:doctro/screens/notification/ViewAllNotification.dart';
import 'package:doctro/screens/setting/changeLanguage.dart';
import 'package:doctro/screens/auth/forgotpassword.dart';
import 'package:doctro/screens/videoCall/videocallhistory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:doctro/retrofit/base_model.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'VideoCall/overlay_handler.dart';
import 'chat/pages/home_page.dart';
import 'chat/providers/auth_provider.dart' as provider;
import 'chat/providers/chat_provider.dart';
import 'chat/providers/home_provider.dart';
import 'constant/prefConstatnt.dart';
import 'localization/localization_constant.dart';
import 'localization/localization_constant.dart' as care360_locale;
import 'brand/care360_global_language.dart';
import 'screens/auth/signup.dart';
import 'screens/auth/phoneverification.dart';
import 'screens/home page/login_home.dart';
import 'screens/home page/patient_information.dart';
import 'screens/appointment/cancel_appointment.dart';
import 'screens/appointment/appointment_history.dart';
import 'screens/review/rate&review.dart';
import 'screens/notification/notifications.dart';
import 'screens/notes/notes.dart';
import 'screens/profile/profile.dart';
import 'screens/paymentScreen/payment.dart';
import 'screens/withdrawal/WithdrawalScreen.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/screens/subscription/Subscription.dart';
import 'package:doctro/screens/paymentScreen/PaymentGateway.dart';
import 'package:doctro/screens/subscription/SubscriptionHistory.dart';
import 'package:doctro/screens/schedule/ScheduleTimings.dart';
import 'package:doctro/screens/paymentScreen/StripePayment.dart';
import 'package:doctro/firebase_options.dart';
import 'screens/onboarding/onboarding.dart';

void main() {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  runZoned(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(StartupGate(
        initialize: _initializeApp,
        onReady: () => unawaited(_initFirebaseMessagingWithLogging()),
      ));
    },
    zoneSpecification: kReleaseMode ? ZoneSpecification(print: (_, __, ___, ____) {}) : null,
  );
}

Future<Widget> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SharedPreferenceHelper.init();


  if (Platform.isAndroid) {
    SharedPreferenceHelper.setString(Preferences.device_platform, "Android");
  }

  return MyApp(prefs: prefs);
}

Future<void> _initFirebaseMessagingWithLogging() async {
  try {
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission().timeout(const Duration(seconds: 5));
      debugPrint('FCM permission status in main: ${settings.authorizationStatus}');

      // On iOS simulators the APNS token is often null. Guard against this to
      // avoid [firebase_messaging/apns-token-not-set] crashing the app.
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken().timeout(const Duration(seconds: 5));
      if (apnsToken == null) {
        debugPrint('Skipping subscribeToTopic(\"all\"): APNS token is null.');
        return;
      }
    }

    await FirebaseMessaging.instance.subscribeToTopic("all").timeout(const Duration(seconds: 5));
    debugPrint('Successfully subscribed to FCM topic \"all\".');
  } catch (e, st) {
    debugPrint('Error during FCM topic subscription: $e\n$st');
  }
}

final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    importance: Importance.high,
    showBadge: true,
    playSound: true,
    enableVibration: true
);

class MyApp extends StatefulWidget {
  MyApp({required this.prefs});
  final SharedPreferences prefs;

  _MyAppState createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

}

class _MyAppState extends State<MyApp> {

  late SharedPreferences _prefs;

  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  get skip => null;

  Locale? _locale;
  String messageImage = '';
  String messageName = '';
  String messageId = '';
  String userToken = '';

  void initState() {
    super.initState();
    _prefs = widget.prefs;
    settingRequest();
    getToken();
  }

  Future<void> getToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken()
          .timeout(const Duration(seconds: 5));
      if (token != null && token.isNotEmpty) {
        await SharedPreferenceHelper.setString(Preferences.messageToken, token);
      }
    } catch (_) {
      debugPrint('Optional push token unavailable; app remains usable.');
    }
  }

  Future<BaseModel<Setting>> settingRequest() async {

    Setting response;

    try {
      response = await RestClient(RetroApi().dioData()).settingRequest();

      if( SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true){

          if(response.data!.stripePublicKey != null){
            SharedPreferenceHelper.setString(Preferences.stripPublicKey, response.data!.stripePublicKey!);
          }

          if(response.data!.flutterwaveKey != null){
            SharedPreferenceHelper.setString(Preferences.flutterWave_key, response.data!.flutterwaveKey!);
          }

          if(response.data!.paystackPublicKey != null){
            SharedPreferenceHelper.setString(Preferences.payStack_public_key, response.data!.paystackPublicKey!);
          }

          if(response.data!.razorKey != null){
            SharedPreferenceHelper.setString(Preferences.razor_key, response.data!.razorKey!);
          }

          if(response.data!.paypalProducationKey != null){
            SharedPreferenceHelper.setString(Preferences.payPal_production_key,response.data!.paypalProducationKey!);
          }

          if(response.data!.paypalSandboxKey != null){
            SharedPreferenceHelper.setString(Preferences.payPal_sandbox_key, response.data!.paypalSandboxKey!);
          }

          if(response.data!.paypalClientId != null){
            SharedPreferenceHelper.setString(Preferences.paypal_client_key, response.data!.paypalClientId!);
          }

          if(response.data!.currencySymbol != null){
            SharedPreferenceHelper.setString(Preferences.currency_symbol, response.data!.currencySymbol!);
          }

          if(response.data!.currencyCode != null){
            SharedPreferenceHelper.setString(Preferences.currency_code, response.data!.currencyCode!);
          }

          if(response.data!.doctorAppId != null){
            SharedPreferenceHelper.setString(Preferences.doctorAppId, response.data!.doctorAppId!);
          }

      } else {

        if(response.data!.currencySymbol != null){
          SharedPreferenceHelper.setString(Preferences.currency_symbol, response.data!.currencySymbol!);
        }

        if(response.data!.currencyCode != null){
          SharedPreferenceHelper.setString(Preferences.currency_code, response.data!.currencyCode!);
        }

        if(response.data!.doctorAppId != null){
          setState(() {
            SharedPreferenceHelper.setString(Preferences.doctorAppId, response.data!.doctorAppId!);
          });
        }

        if(response.data!.doctorAppId != null){

          setState(() {
            getOneSingleToken(SharedPreferenceHelper.getString(Preferences.doctorAppId));
          });

        }
      }
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<void> getOneSingleToken(appId) async {
    OneSignal.Debug.setLogLevel(OSLogLevel.info);

    OneSignal.initialize(appId);
    if (kDebugMode) {
      debugPrint("OneSignal App ID: $appId");
    }

    OneSignal.Notifications.addPermissionObserver((state) {
      debugPrint("OneSignal permission state changed: $state");
    });

    final hasPermission = OneSignal.Notifications.permission;
    debugPrint("OneSignal initial permission: $hasPermission");

    if (Platform.isIOS &&
        hasPermission == false &&
        !SharedPreferenceHelper.getBoolean(Preferences.notificationPermissionDialog)) {
      await OneSignal.Notifications.requestPermission(true);
      await SharedPreferenceHelper.setBoolean(Preferences.notificationPermissionDialog, true);
    } else if (Platform.isAndroid) {
      await OneSignal.Notifications.requestPermission(true);
    }

    if (kDebugMode) {
      debugPrint("OneSignal ID : ${OneSignal.User.pushSubscription.id}");
    }

    OneSignal.Debug.setAlertLevel(OSLogLevel.none);

    final subscriptionId = OneSignal.User.pushSubscription.id;
    if (subscriptionId != null) {
      await SharedPreferenceHelper.setString(
        Preferences.device_token,
        subscriptionId.toString(),
      );
    } else {
      debugPrint('OneSignal pushSubscription.id is null; device_token not saved yet.');
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void didChangeDependencies() {
    getLocale().then((local) => {
      setState(() {
        this._locale = local;
      })
    });
    super.didChangeDependencies();
  }

  Widget build(BuildContext context) {
    final effectiveLocale = _locale ?? const Locale(ENGLISH, 'US');

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: ChangeNotifierProvider<OverlayHandlerProvider>(
          create: (_) => OverlayHandlerProvider(),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<provider.AuthProvider>(
                create: (_) => provider.AuthProvider(
                  firebaseAuth: FirebaseAuth.instance,
                  prefs: _prefs,
                  firebaseFirestore: this.firebaseFirestore,
                ),
              ),
              Provider<HomeProvider>(
                create: (_) => HomeProvider(
                  firebaseFirestore: this.firebaseFirestore,
                ),
              ),
              Provider<ChatProvider>(
                create: (_) => ChatProvider(
                  prefs: _prefs,
                  firebaseFirestore: this.firebaseFirestore,
                  firebaseStorage: this.firebaseStorage,
                ),
              ),
            ],
            child: MaterialApp(
              navigatorKey: navigatorKey,
              builder: (context, navigatorChild) => Stack(
                children: [
                  if (navigatorChild != null) navigatorChild,
                  PositionedDirectional(
                    end: 10,
                    bottom: 64,
                    child: SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      child: Care360GlobalLanguageSwitch(
                        rootNavigatorKey: navigatorKey,
                        onSelect: (code) async {
                          final selectedLocale = await care360_locale.setLocale(code);
                          if (!mounted) return;
                          setLocale(selectedLocale);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              title: "Care360 Plus",
              debugShowCheckedModeBanner: false,
              locale: effectiveLocale,
              supportedLocales: [
                Locale(ENGLISH, 'US'),
                Locale(HAUSA, 'NG'),
                Locale(IGBO, 'NG'),
                Locale(YORUBA, 'NG'),
                Locale(FRENCH, 'FR'),
                Locale(ARABIC, 'AE'),
              ],
              localizationsDelegates: [
                LanguageLocalization.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              localeResolutionCallback: (deviceLocal, supportedLocales) {
                for (var local in supportedLocales) {
                  if (deviceLocal != null && local.languageCode == deviceLocal.languageCode &&
                      local.countryCode == deviceLocal.countryCode) {
                    return deviceLocal;
                  }
                }
                return supportedLocales.first;
              },
              initialRoute: SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                  ? 'loginHome'
                  : (SharedPreferenceHelper.getBoolean(Preferences.onboarding_seen) ? 'SignIn' : 'Onboarding'),
              theme: ThemeData(useMaterial3: false,),
              routes: {
                'SignIn': (context) => SignIn(),
                'signup': (context) => CreateAccount(),
                'ForgotPasswordScreen': (context) => ForgotPasswordScreen(),
                'phoneverification': (context) => PhoneVerificationScreen(),
                'loginHome': (context) => LoginHomeScreen(chat: ""),
                'patientInformation': (context) => patientDetailsScreen(),
                'cancelAppoitmentRoutes': (context) => CancelAppointmentScreen(),
                'AppointmentHistoryScreen': (context) => AppointmentHistoryScreen(),
                'rateAndReviewRoutes': (context) => RateAndReviewRoutesScreen(),
                'notifications': (context) => NotificationsScreen(),
                'profile': (context) => ProfileScreen(),
                'payment': (context) => PaymentScreen(),
                'withdrawal': (context) => WithdrawalScreen(),
                'subscription': (context) => SubSubscription(),
                'paymentGatewayRoutes': (context) => PaymentGatewayScreen(),
                'Subscription History': (context) => SubscriptionHistory(),
                'Schedule Timings': (context) => ScheduleTimings(),
                'Change Password': (context) => ChangePassword(),
                'Change Language': (context) => ChangeLanguage(),
                'ViewAllNotification': (context) => ViewAllNotification(),
                'Stripe' :(context) => Stripe(),
                'VideoCallHistory' :(context) => VideoCallHistory(),
                'Settings' : (context) => SettingScreen(),
                'ChatHome' : (context) => HomePage(),
                'Onboarding': (context) => const OnboardingScreen(),
                'Notes': (context) => const NotesScreen(),
              },
            ),
          ),
        ),
      );
  }
}
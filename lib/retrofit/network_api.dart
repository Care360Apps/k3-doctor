import 'package:doctro/model/AllMedicines.dart';
import 'package:doctro/model/CancelAppointment.dart';
import 'package:doctro/model/ChangePassword.dart';
import 'package:doctro/model/DoctorStatusChange.dart';
import 'package:doctro/model/FinanceDetails.dart';
import 'package:doctro/model/ForgotPassword.dart';
import 'package:doctro/model/Notification.dart';
import 'package:doctro/model/ResentOtp.dart';
import 'package:doctro/model/UpdateTiming.dart';
import 'package:doctro/model/add_prescription.dart';
import 'package:doctro/model/appointment_history.dart';
import 'package:doctro/model/expertise.dart';
import 'package:doctro/model/Treatment.dart';
import 'package:doctro/model/categories.dart';
import 'package:doctro/model/hospital.dart';
import 'package:doctro/model/login.dart';
import 'package:doctro/model/register.dart';
import 'package:doctro/model/appointment_details.dart';
import 'package:doctro/model/update_profile_image.dart';
import 'package:doctro/model/video_call_history_add_model.dart';
import 'package:doctro/model/video_call_history_show_model.dart';
import 'package:doctro/retrofit/apis.dart';
import 'package:retrofit/http.dart';
import 'package:dio/dio.dart';
import 'package:doctro/model/working_hours.dart';
import 'package:doctro/model/doctor_profile.dart';
import 'package:doctro/model/review.dart';
import 'package:doctro/model/doctor_note.dart';
import 'package:doctro/model/payment.dart';
import 'package:doctro/model/otp_verify.dart';
import 'package:doctro/model/today_appointment.dart';
import 'package:doctro/model/UpdateProfile.dart';
import 'package:doctro/model/account_delete_model.dart';
import 'package:doctro/model/withdrawal_request_model.dart';
import 'package:doctro/model/payout_account.dart';
import 'package:doctro/model/setting.dart';
import 'package:doctro/model/purchaseSubscription.dart';
import 'package:doctro/model/Subscription.dart';

import 'package:doctro/screens/videoCall/model/doctorAgoraTokenGenerateModel.dart';

part 'network_api.g.dart';

/// Optional logger used by generated Retrofit client to report JSON parse errors.
abstract class ParseErrorLogger {
  void logError(
    Object error,
    StackTrace stackTrace,
    RequestOptions requestOptions, {
    Response<dynamic>? response,
  });
}

@RestApi(baseUrl: Apis.baseUrl)
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  @POST(Apis.login)
  Future<Login> loginRequest(@Body() body);

  @POST(Apis.provider_login)
  Future<Login> providerLoginRequest(@Body() body);

  @POST(Apis.register)
  Future<Register> registerRequest(@Body() body);

  @POST(Apis.provider_register)
  Future<Register> providerRegisterRequest(@Body() body);

  @GET(Apis.appointment)
  Future<TodayAppointment> todayAppointments();

  @GET(Apis.appointment_details)
  Future<AppointmentDetails> appointmentDetails(@Path() int? id);

  @GET(Apis.appointment_history)
  Future<AppointmentHistory> appointmentHistoryScreenRequest();

  @GET(Apis.working_hours)
  Future<Workinghours> workinghours();

  @GET(Apis.hospitals)
  Future<Hospitals> hospitalRequest();

  @GET(Apis.doctor_profile)
  Future<DoctorProfile> doctorProfile();

  @GET(Apis.review)
  Future<Review> reviewRequest();

  @GET(Apis.payment)
  Future<Payment> paymentRequest();

  @POST(Apis.check_otp)
  Future<OtpVerify> otpVerifyRequest(@Body() body);

  @POST(Apis.update_doctor)
  Future<UpdateProfile> updateProfile(@Body() body);

  @GET(Apis.treatment)
  Future<Treatment> treatmentRequest();

  @GET(Apis.categories)
  Future<Categories> categoryRequest(@Path() int? id);

  @GET(Apis.expertise)
  Future<Expertise> expertiseRequest(@Path() int? id);

  @GET(Apis.subscription)
  Future<SubscriptionPlan> subscriptionRequest();

  @POST(Apis.addPrescription)
  Future<AddPrescription> addPrescriptionRequest(@Body() body);

  @GET(Apis.setting)
  Future<Setting> settingRequest();

  @POST(Apis.update_image)
  Future<ImageUpload> uploadImage(@Body() body);

  @POST(Apis.purchase_subscription)
  Future<PurchaseSubscription> purchaseSubscriptionRequest(@Body() body);

  @POST(Apis.status_change)
  Future<DoctorStatusChange> doctorStatusChangeRequest(@Body() body);

  @GET(Apis.cancel_appointment)
  Future<CancelAppointment> cancelAppointmentRequest();

  @GET(Apis.finance_detail)
  Future<FinanceDetails> purchaseDetailsRequest();

  @POST(Apis.update_time)
  Future<UpdateTiming> updateTimingRequest(@Body() body);

  @POST(Apis.change_password)
  Future<ChangePasswordModel> changePasswordRequest(@Body() body);

  @POST(Apis.forgot_password)
  Future<ForgotPassword> forgotPasswordScreen(@Body() body);

  @GET(Apis.notification)
  Future<Notifications> notifications();

  @GET(Apis.all_medicines)
  Future<AllMedicines> allMedicines();

  @GET(Apis.resend_otp)
  Future<ResentOtp> resentOtpRequest(@Path() int? id);

  @POST(Apis.videoCallAddHistory)
  Future<VideoCallHistoryAddModel> videoCallHistoryAddRequest(@Body() body);

  @GET(Apis.videoCallShowHistory)
  Future<VideoCallHistoryShowModel> videoCallHistoryShowRequest();

  @POST(Apis.generateDoctorAgoraToken)
  Future<VideoCallModel> generateDoctorAgoraTokenCall(@Body() body);

  @POST(Apis.updatePatientVcall)
  Future<UpdateProfile> updatePatientVcallRequest(@Body() body);

  @GET(Apis.deleteAccount)
  Future<AccountDeleteModel> deleteAccountRequest();

  @GET(Apis.doctor_notes)
  Future<DoctorNotesResponse> doctorNotes(@Query('appointment_id') int appointmentId);

  @POST(Apis.doctor_notes)
  Future<DoctorNotesResponse> createDoctorNote(@Body() Map<String, dynamic> body);

  @PUT(Apis.doctor_note_id)
  Future<DoctorNotesResponse> updateDoctorNote(@Path() int id, @Body() Map<String, dynamic> body);

  @DELETE(Apis.doctor_note_id)
  Future<DoctorNotesResponse> deleteDoctorNote(@Path() int id);

  @GET(Apis.withdrawal_requests)
  Future<WithdrawalRequestsResponse> withdrawalRequestsRequest();

  @POST(Apis.withdrawal_requests)
  Future<WithdrawalRequestCreateResponse> withdrawalRequestCreateRequest(@Body() Map<String, dynamic> body);

  @GET(Apis.payout_account)
  Future<PayoutAccountResponse> payoutAccountShow();

  @POST(Apis.payout_account)
  Future<PayoutAccountResponse> payoutAccountUpdate(@Body() Map<String, dynamic> body);
}

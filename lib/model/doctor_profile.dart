class DoctorProfile {
  bool? success;
  Data? data;
  String? msg;

  DoctorProfile({this.success, this.data, this.msg});

  DoctorProfile.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['msg'] = this.msg;
    return data;
  }
}

class Data {
  int? id;
  int? treatmentId;
  int? categoryId;
  int? expertiseId;
  String? hospitalId;
  int? userId;
  String? image;
  String? desc;
  String? education;
  String? certificate;
  String? appointmentFees;
  String? hourlyRate;
  String? experience;
  String? timeslot;
  String? name;
  String? dob;
  String? gender;
  String? startTime;
  String? endTime;
  String? since;
  int? status;
  int? subscriptionStatus;
  String? basedOn;
  int? isPopular;
  String? commissionAmount;
  int? customTimeslot;
  int? isFilled;
  int? patientVCall;
  int? offersVideoCall;
  int? offersHomeVisit;

  String? language;
  String? createdAt;
  String? updatedAt;
  String? email;
  String? phone;
  String? agoraToken;
  String? channelName;
  String? fullImage;
  Hospital? hospital;
  String? address;
  double? lat;
  double? lng;

  Data(
      {this.id,
      this.treatmentId,
      this.categoryId,
      this.expertiseId,
      this.hospitalId,
      this.userId,
      this.image,
      this.desc,
      this.education,
      this.certificate,
      this.appointmentFees,
      this.hourlyRate,
      this.experience,
      this.timeslot,
      this.name,
      this.dob,
      this.gender,
      this.startTime,
      this.endTime,
      this.since,
      this.status,
      this.subscriptionStatus,
      this.basedOn,
      this.isPopular,
      this.commissionAmount,
      this.customTimeslot,
      this.isFilled,
      this.patientVCall,
      this.offersVideoCall,
      this.offersHomeVisit,
      this.language,
      this.createdAt,
      this.updatedAt,
      this.email,
      this.phone,
      this.agoraToken,
      this.channelName,
      this.fullImage,
      this.hospital,
      this.address,
      this.lat,
      this.lng});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    treatmentId = json['treatment_id'] != null ? int.tryParse(json['treatment_id'].toString()) : null;
    categoryId = json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null;
    expertiseId = json['expertise_id'] != null ? int.tryParse(json['expertise_id'].toString()) : null;
    hospitalId = json['hospital_id'];
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    image = json['image'];
    desc = json['desc'];
    education = json['education'];
    certificate = json['certificate'];
    appointmentFees = json['appointment_fees']?.toString();
    hourlyRate = json['hourly_rate']?.toString();
    experience = json['experience'];
    timeslot = json['timeslot'];
    name = json['name'];
    dob = json['dob'];
    gender = json['gender'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    since = json['since'];
    status = json['status'] != null ? int.tryParse(json['status'].toString()) : null;
    subscriptionStatus = json['subscription_status'] != null ? int.tryParse(json['subscription_status'].toString()) : null;
    basedOn = json['based_on'];
    isPopular = json['is_popular'] != null ? int.tryParse(json['is_popular'].toString()) : null;
    commissionAmount = json['commission_amount'];
    customTimeslot = json['custom_timeslot'] != null ? int.tryParse(json['custom_timeslot'].toString()) : null;
    isFilled = json['is_filled'] != null ? int.tryParse(json['is_filled'].toString()) : null;
    patientVCall = json['patient_vcall'] != null ? int.tryParse(json['patient_vcall'].toString()) : null;
    offersVideoCall = json['offers_video_call'] != null ? int.tryParse(json['offers_video_call'].toString()) : null;
    offersHomeVisit = json['offers_home_visit'] != null ? int.tryParse(json['offers_home_visit'].toString()) : null;
    language = json['language'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    email = json['email'];
    phone = json['phone'];
    agoraToken = json['agora_token'];
    channelName = json['channel_name'];
    fullImage = json['fullImage'];
    hospital = json['hospital'] != null ? new Hospital.fromJson(json['hospital']) : null;
    address = json['address']?.toString();
    lat = json['lat'] != null ? double.tryParse(json['lat'].toString()) : null;
    lng = json['lng'] != null ? double.tryParse(json['lng'].toString()) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['treatment_id'] = this.treatmentId;
    data['category_id'] = this.categoryId;
    data['expertise_id'] = this.expertiseId;
    data['hospital_id'] = this.hospitalId;
    data['user_id'] = this.userId;
    data['image'] = this.image;
    data['desc'] = this.desc;
    data['education'] = this.education;
    data['certificate'] = this.certificate;
    data['appointment_fees'] = this.appointmentFees;
    data['hourly_rate'] = this.hourlyRate;
    data['experience'] = this.experience;
    data['timeslot'] = this.timeslot;
    data['name'] = this.name;
    data['dob'] = this.dob;
    data['gender'] = this.gender;
    data['start_time'] = this.startTime;
    data['end_time'] = this.endTime;
    data['since'] = this.since;
    data['status'] = this.status;
    data['subscription_status'] = this.subscriptionStatus;
    data['based_on'] = this.basedOn;
    data['is_popular'] = this.isPopular;
    data['commission_amount'] = this.commissionAmount;
    data['custom_timeslot'] = this.customTimeslot;
    data['is_filled'] = this.isFilled;
    data['patient_vcall'] = this.patientVCall;
    data['offers_video_call'] = this.offersVideoCall;
    data['offers_home_visit'] = this.offersHomeVisit;
    data['language'] = this.language;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['agora_token'] = this.agoraToken;
    data['channel_name'] = this.channelName;
    data['fullImage'] = this.fullImage;
    if (this.hospital != null) {
      data['hospital'] = this.hospital!.toJson();
    }
    data['address'] = this.address;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    return data;
  }
}

class Hospital {
  int? id;
  String? name;
  String? address;

  Hospital({this.id, this.name, this.address});

  Hospital.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['address'] = this.address;
    return data;
  }
}

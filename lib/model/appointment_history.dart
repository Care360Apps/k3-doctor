class AppointmentHistory {
  bool? success;
  Data? data;

  AppointmentHistory({this.success, this.data});

  AppointmentHistory.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  List<UpcomingAppointment>? upcomingAppointment;
  List<PastAppointment>? pastAppointment;

  Data({this.upcomingAppointment, this.pastAppointment});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['upcoming_appointment'] != null) {
      upcomingAppointment = <UpcomingAppointment>[];
      json['upcoming_appointment'].forEach((v) {
        upcomingAppointment!.add(new UpcomingAppointment.fromJson(v));
      });
    }
    if (json['past_appointment'] != null) {
      pastAppointment = <PastAppointment>[];
      json['past_appointment'].forEach((v) {
        pastAppointment!.add(new PastAppointment.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.upcomingAppointment != null) {
      data['upcoming_appointment'] = this.upcomingAppointment!.map((v) => v.toJson()).toList();
    }
    if (this.pastAppointment != null) {
      data['past_appointment'] = this.pastAppointment!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UpcomingAppointment {
  int? id;
  String? date;
  String? time;
  int? userId;
  int? hospitalId;
  String? patientAddress;
  String? patientName;
  String? appointmentStatus;
  String? visitType;
  String? treatment;
  String? doctorName;
  int? rate;
  int? review;
  User? user;
  Hospital? hospital;

  UpcomingAppointment({this.id, this.date, this.time, this.userId, this.hospitalId, this.patientAddress, this.patientName, this.appointmentStatus, this.visitType, this.treatment, this.doctorName, this.rate, this.review, this.user, this.hospital});

  UpcomingAppointment.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    date = json['date'];
    time = json['time'];
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    hospitalId = json['hospital_id'] != null ? int.tryParse(json['hospital_id'].toString()) : null;
    patientAddress = json['patient_address'];
    patientName = json['patient_name'];
    appointmentStatus = json['appointment_status'];
    visitType = json['visit_type'];
    treatment = json['treatment'];
    doctorName = json['doctor_name'];
    rate = json['rate'] != null ? int.tryParse(json['rate'].toString()) : null;
    review = json['review'] != null ? int.tryParse(json['review'].toString()) : null;
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    hospital = json['hospital'] != null ? new Hospital.fromJson(json['hospital']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['date'] = this.date;
    data['time'] = this.time;
    data['user_id'] = this.userId;
    data['hospital_id'] = this.hospitalId;
    data['patient_address'] = this.patientAddress;
    data['patient_name'] = this.patientName;
    data['appointment_status'] = this.appointmentStatus;
    data['visit_type'] = this.visitType;
    data['treatment'] = this.treatment;
    data['doctor_name'] = this.doctorName;
    data['rate'] = this.rate;
    data['review'] = this.review;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.hospital != null) {
      data['hospital'] = this.hospital!.toJson();
    }
    return data;
  }
}

class PastAppointment {
  int? id;
  String? date;
  String? time;
  int? userId;
  int? hospitalId;
  String? patientAddress;
  String? patientName;
  String? appointmentStatus;
  String? visitType;
  String? treatment;
  String? doctorName;
  int? rate;
  int? review;
  User? user;
  Hospital? hospital;

  PastAppointment({this.id, this.date, this.time, this.userId, this.hospitalId, this.patientAddress, this.patientName, this.appointmentStatus, this.visitType, this.treatment, this.doctorName, this.rate, this.review, this.user, this.hospital});

  PastAppointment.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    date = json['date'];
    time = json['time'];
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    hospitalId = json['hospital_id'] != null ? int.tryParse(json['hospital_id'].toString()) : null;
    patientAddress = json['patient_address'];
    patientName = json['patient_name'];
    appointmentStatus = json['appointment_status'];
    visitType = json['visit_type'];
    treatment = json['treatment'];
    doctorName = json['doctor_name'];
    rate = json['rate'] != null ? int.tryParse(json['rate'].toString()) : null;
    review = json['review'] != null ? int.tryParse(json['review'].toString()) : null;
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    hospital = json['hospital'] != null ? new Hospital.fromJson(json['hospital']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['date'] = this.date;
    data['time'] = this.time;
    data['user_id'] = this.userId;
    data['hospital_id'] = this.hospitalId;
    data['patient_address'] = this.patientAddress;
    data['patient_name'] = this.patientName;
    data['appointment_status'] = this.appointmentStatus;
    data['visit_type'] = this.visitType;
    data['treatment'] = this.treatment;
    data['doctor_name'] = this.doctorName;
    data['rate'] = this.rate;
    data['review'] = this.review;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.hospital != null) {
      data['hospital'] = this.hospital!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? image;
  String? fullImage;

  User({this.id, this.image, this.fullImage});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    image = json['image'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['image'] = this.image;
    data['fullImage'] = this.fullImage;
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

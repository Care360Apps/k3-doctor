class DoctorNotesResponse {
  bool? success;
  List<DoctorNote>? data;
  String? msg;

  DoctorNotesResponse({this.success, this.data, this.msg});

  DoctorNotesResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    msg = json['msg'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(DoctorNote.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['msg'] = msg;
    return data;
  }
}

class DoctorNote {
  int? id;
  int? doctorId;
  int? userId;
  int? appointmentId;
  String? title;
  String? body;
  String? createdAt;

  DoctorNote(
      {this.id,
      this.doctorId,
      this.userId,
      this.appointmentId,
      this.title,
      this.body,
      this.createdAt});

  DoctorNote.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    doctorId = json['doctor_id'] != null ? int.tryParse(json['doctor_id'].toString()) : null;
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    appointmentId = json['appointment_id'] != null ? int.tryParse(json['appointment_id'].toString()) : null;
    title = json['title'];
    body = json['body'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['doctor_id'] = doctorId;
    data['user_id'] = userId;
    data['appointment_id'] = appointmentId;
    data['title'] = title;
    data['body'] = body;
    data['created_at'] = createdAt;
    return data;
  }
}


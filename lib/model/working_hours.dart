class Workinghours {
  bool? success;
  List<Data>? data;
  String? msg;

  Workinghours({this.success, this.data, this.msg});

  Workinghours.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['msg'] = this.msg;
    return data;
  }
}

class Data {
  int? id;
  int? doctorId;
  String? dayIndex;
  String? periodList;
  int? status;

  Data({this.id, this.doctorId, this.dayIndex, this.periodList, this.status});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    doctorId = json['doctor_id'] != null ? int.tryParse(json['doctor_id'].toString()) : null;
    dayIndex = json['day_index'];
    periodList = json['period_list'];
    status = json['status'] != null ? int.tryParse(json['status'].toString()) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['doctor_id'] = this.doctorId;
    data['day_index'] = this.dayIndex;
    data['period_list'] = this.periodList;
    data['status'] = this.status;
    return data;
  }
}

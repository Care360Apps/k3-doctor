class FinanceDetails {
  bool? success;
  List<PurchaseDetails>? data;
  double? availableBalance;

  FinanceDetails({this.success, this.data});

  FinanceDetails.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    final bal = json['available_balance'];
    if (bal is num) {
      availableBalance = bal.toDouble();
    } else if (bal is String) {
      availableBalance = double.tryParse(bal);
    }
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(new PurchaseDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PurchaseDetails {
  int? id;
  int? doctorId;
  int? subscriptionId;
  int? duration;
  String? startDate;
  String? endDate;
  String? paymentType;
  int? amount;
  String? paymentToken;
  int? paymentStatus;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? doctorName;
  Subscription? subscription;
  double? dBalance;

  PurchaseDetails(
      {this.id,
      this.doctorId,
      this.subscriptionId,
      this.duration,
      this.startDate,
      this.endDate,
      this.paymentType,
      this.amount,
      this.paymentToken,
      this.paymentStatus,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.doctorName,
      this.subscription,
      this.dBalance});

  PurchaseDetails.fromJson(Map<String, dynamic> json) {
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    id = _toInt(json['id']);
    doctorId = _toInt(json['doctor_id']);
    subscriptionId = _toInt(json['subscription_id']);
    duration = _toInt(json['duration']);
    startDate = json['start_date'];
    endDate = json['end_date'];
    paymentType = json['payment_type'];
    amount = _toInt(json['amount']);
    paymentToken = json['payment_token'];
    paymentStatus = _toInt(json['payment_status']);
    status = _toInt(json['status']);
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    doctorName = json['doctor_name'];
    final dynamic balanceRaw = json['d_balance'];
    if (balanceRaw is num) {
      dBalance = balanceRaw.toDouble();
    } else if (balanceRaw is String) {
      dBalance = double.tryParse(balanceRaw);
    }
    subscription = json['subscription'] != null ? new Subscription.fromJson(json['subscription']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['doctor_id'] = this.doctorId;
    data['subscription_id'] = this.subscriptionId;
    data['duration'] = this.duration;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    data['payment_type'] = this.paymentType;
    data['amount'] = this.amount;
    data['payment_token'] = this.paymentToken;
    data['payment_status'] = this.paymentStatus;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['doctor_name'] = this.doctorName;
    if (this.dBalance != null) {
      data['d_balance'] = this.dBalance;
    }
    if (this.subscription != null) {
      data['subscription'] = this.subscription!.toJson();
    }
    return data;
  }
}

class Subscription {
  int? id;
  String? name;

  Subscription({this.id, this.name});

  Subscription.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }
}

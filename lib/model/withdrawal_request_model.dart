class WithdrawalRequestsResponse {
  bool? success;
  String? msg;
  List<WithdrawalRequestItem>? data;

  WithdrawalRequestsResponse({this.success, this.msg, this.data});

  WithdrawalRequestsResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    msg = json['msg'];
    if (json['data'] != null) {
      data = [];
      for (final v in json['data'] as List) {
        data!.add(WithdrawalRequestItem.fromJson(v as Map<String, dynamic>));
      }
    }
  }
}

class WithdrawalRequestItem {
  int? id;
  double? amount;
  String? status;
  String? paymentReference;
  String? rejectedReason;
  String? createdAt;
  String? paidAt;

  WithdrawalRequestItem({
    this.id,
    this.amount,
    this.status,
    this.paymentReference,
    this.rejectedReason,
    this.createdAt,
    this.paidAt,
  });

  WithdrawalRequestItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    final raw = json['amount'];
    if (raw is num) {
      amount = raw.toDouble();
    } else if (raw is String) {
      amount = double.tryParse(raw);
    } else {
      amount = null;
    }
    status = json['status'];
    paymentReference = json['payment_reference'];
    rejectedReason = json['rejected_reason'];
    createdAt = json['created_at'];
    paidAt = json['paid_at'];
  }
}

class WithdrawalRequestCreateResponse {
  bool? success;
  String? msg;
  WithdrawalRequestCreateData? data;

  WithdrawalRequestCreateResponse({this.success, this.msg, this.data});

  WithdrawalRequestCreateResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    msg = json['msg'];
    data = json['data'] != null ? WithdrawalRequestCreateData.fromJson(json['data']) : null;
  }
}

class WithdrawalRequestCreateData {
  int? id;

  WithdrawalRequestCreateData({this.id});

  WithdrawalRequestCreateData.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
  }
}

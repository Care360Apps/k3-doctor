class PayoutAccountResponse {
  bool? success;
  String? msg;
  PayoutAccountData? data;

  PayoutAccountResponse({this.success, this.msg, this.data});

  PayoutAccountResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    msg = json['msg'];
    data = json['data'] != null ? PayoutAccountData.fromJson(json['data']) : null;
  }
}

class PayoutAccountData {
  String? accountName;
  String? accountNumber;
  String? bankName;

  PayoutAccountData({this.accountName, this.accountNumber, this.bankName});

  PayoutAccountData.fromJson(Map<String, dynamic> json) {
    accountName = json['account_name'];
    accountNumber = json['account_number'];
    bankName = json['bank_name'];
  }
}


import 'package:intl/intl.dart';

class CoursesResponse {
  bool? success;
  List<CourseData>? data;
  String? msg;

  CoursesResponse({this.success, this.data, this.msg});

  CoursesResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(new CourseData.fromJson(v));
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

class CourseData {
  int? id;
  String? title;
  String? provider;
  String? summary;
  String? details;
  String? image;
  String? duration;
  num? amount;
  String? link;
  String? fullImage;

  CourseData({
    this.id,
    this.provider,
    this.title,
    this.summary,
    this.details,
    this.image,
    this.duration,
    this.amount,
    this.link,
    this.fullImage,
  });

  CourseData.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    title = json['title'];
    provider = json['provider'];
    summary = json['summary'];
    details = json['details'];
    image = json['image'];
    duration = json['duration'];
    amount = _parseAmount(json['amount']);
    link = json['link'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['provider'] = this.provider;
    data['summary'] = this.summary;
    data['details'] = this.details;
    data['image'] = this.image;
    data['duration'] = this.duration;
    data['amount'] = this.amount;
    data['link'] = this.link;
    data['fullImage'] = this.fullImage;
    return data;
  }

  bool get isSpeakOut => provider == 'speakout';
  String get providerLabel => isSpeakOut
      ? 'SpeakOut'
      : provider == 'cnu'
      ? 'CNU'
      : 'Course provider';
  bool get hasTuition => amount != null && amount!.isFinite && amount! > 0;
  String get tuitionLabel => isSpeakOut
      ? '100% free'
      : hasTuition
      ? 'NGN ${NumberFormat('#,##0.00', 'en_NG').format(amount)}'
      : 'Contact for tuition';
  String get tuitionFilter => isSpeakOut
      ? 'Free'
      : hasTuition
      ? 'Paid'
      : 'Contact for tuition';
  String get applicationNotice => isSpeakOut
      ? '100% free. Registration and approval are required on the SpeakOut website.'
      : 'Apply on the provider website. Tuition and admission are handled by the provider.';
  Uri? get applicationUri {
    final uri = Uri.tryParse(link?.trim() ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.port != 443 ||
        !uri.host.contains('.') ||
        RegExp(r'^[0-9.]+$').hasMatch(uri.host) ||
        uri.host.contains(':') ||
        [
          'localhost',
          'local',
          'internal',
          'test',
          'invalid',
        ].any((s) => uri.host == s || uri.host.endsWith('.$s')))
      return null;
    if (isSpeakOut &&
        uri.host != 'speakoutmentalhealth.org' &&
        !uri.host.endsWith('.speakoutmentalhealth.org'))
      return null;
    return uri;
  }

  static String plain(String? value) =>
      (value ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim();
  num? _parseAmount(dynamic value) {
    if (value == null) return null;
    return num.tryParse(value.toString());
  }
}

import 'dart:core';
import 'package:country_picker/country_picker.dart';
import 'package:doctro/model/otp_verify.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/apis.dart';
import 'package:doctro/retrofit/base_model.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/constant/common_function.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/model/register.dart';
import 'package:doctro/retrofit/server_error.dart';
import 'package:doctro/screens/auth/phoneverification.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  //Set Height/Width Using MediaQuery
  late double width;
  late double height;

  //Set Password Visibility
  bool _isHidden = true;

  // Toggle between Doctor and Provider registration
  bool _registerAsProvider = false;

  // Provider types loaded from API when registering as provider
  List<Map<String, dynamic>> _providerTypes = [];
  int? _selectedProviderTypeId;
  bool _loadingProviderTypes = false;

  // Certification documents; limits mirror the server-side validation.
  static const int _maxDocuments = 5;
  static const int _maxDocumentBytes = 5 * 1024 * 1024;
  static const List<String> _documentExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  final List<PlatformFile> _documents = [];

//Set DropDown For Male/Female
  List<String> gender = [];
  String? _genderSelect;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      gender = [
        getTranslated(context, AppString.gender_male).toString(),
        getTranslated(context, AppString.gender_female).toString(),
      ];
      // Preload provider types so the dropdown is ready when user switches tab.
      _loadProviderTypes();
    });
  }

  Future<void> _loadProviderTypes() async {
    if (_providerTypes.isNotEmpty || _loadingProviderTypes) return;
    try {
      setState(() {
        _loadingProviderTypes = true;
      });
      final dio = RetroApi().dioData();
      // Ensure absolute URL so this works before login as well.
      dio.options.baseUrl = Apis.baseUrl;
      final response = await dio.get(Apis.provider_types);
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        final List list = data['data'] as List;
        final types = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is Map) {
            types.add(Map<String, dynamic>.from(item as Map));
          }
        }
        if (mounted) {
          setState(() {
            _providerTypes = types;
          });
        }
      }
    } catch (_) {
      // silently ignore; user can retry by toggling
    } finally {
      if (mounted) {
        setState(() {
          _loadingProviderTypes = false;
        });
      }
    }
  }

  //Select Dob
  DateTime? _selectedDate;
  String newDateApiPass = "";

  //Set Empty Data Validation
  final _formkey = GlobalKey<FormState>();

  //Set TextInput Controller
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _dob = TextEditingController();
  TextEditingController _phone = TextEditingController();
  TextEditingController _password = TextEditingController();
  TextEditingController _phoneCode = TextEditingController(text: "+91");
  TextEditingController _address = TextEditingController();

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(width, height * 0.06),
        child: SafeArea(
          child: Container(
            margin: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              child: Padding(
                padding: EdgeInsets.zero,
                child: Icon(Icons.arrow_back_ios),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: SingleChildScrollView(
          child: Center(
            child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: height * 0.015, left: width * 0.073, right: width * 0.073),
                    child: Text(
                      getTranslated(context, AppString.register_heading).toString(),
                      style: TextStyle(fontSize: width * 0.07, fontWeight: FontWeight.bold, color: hintColor),
                    ),
                  ),
                  SizedBox(height: height * 0.015),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_registerAsProvider) {
                                  setState(() {
                                    _registerAsProvider = false;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _registerAsProvider ? Colors.transparent : loginButton,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Doctor',
                                  style: TextStyle(
                                    fontSize: width * 0.038,
                                    color: _registerAsProvider ? hintColor : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (!_registerAsProvider) {
                                  setState(() {
                                    _registerAsProvider = true;
                                  });
                                  await _loadProviderTypes();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _registerAsProvider ? loginButton : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  getTranslated(context, AppString.auth_tab_other_providers).toString(),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: width * 0.038,
                                    color: _registerAsProvider ? Colors.white : hintColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: width * 0.020, right: width * 0.020, top: height * 0.027),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: height * 0.01, left: width * 0.05, right: width * 0.05),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                          child: TextFormField(
                            controller: _name,
                            keyboardType: TextInputType.name,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
                            ],
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: getTranslated(context, AppString.register_full_name).toString(),
                              hintStyle: TextStyle(
                                fontSize: width * 0.04,
                                color: hintColor,
                              ),
                            ),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return getTranslated(context, AppString.please_enter_full_name).toString();
                              } else if (value.trim().length < 1) {
                                return getTranslated(context, AppString.please_enter_valid_name).toString();
                              }
                              return null;
                            },
                            onSaved: (String? name) {},
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: height * 0.01, left: width * 0.05, right: width * 0.05),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                          child: TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: getTranslated(context, AppString.register_email_hint).toString(),
                              hintStyle: TextStyle(
                                fontSize: width * 0.04,
                                color: hintColor,
                              ),
                            ),
                            validator: (String? value) {
                              Pattern pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                              RegExp regex = new RegExp(pattern as String);

                              if (value!.length == 0) {
                                return getTranslated(context, AppString.please_enter_email).toString();
                              }
                              if (!regex.hasMatch(value)) {
                                return getTranslated(context, AppString.please_enter_valid_email).toString();
                              }
                              return null;
                            },
                            onSaved: (String? name) {},
                          ),
                        ),
                        Container(
                          child: Row(
                            children: [
                              Container(
                                width: width * 0.21,
                                height: height * 0.06,
                                margin: EdgeInsets.only(
                                  top: height * 0.01,
                                  left: width * 0.05,
                                  right: width * 0.05,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: width * 0.20,
                                      height: height * 0.06,
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: TextFormField(
                                        keyboardType: TextInputType.phone,
                                        textAlign: TextAlign.center,
                                        readOnly: true,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: hintColor,
                                        ),
                                        controller: _phoneCode,
                                        decoration: InputDecoration(
                                          hintText: '+91',
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(
                                            fontSize: width * 0.04,
                                            color: hintColor,
                                          ),
                                        ),
                                        onTap: () {
                                          showCountryPicker(
                                            context: context,
                                            exclude: <String>['KN', 'MF'],
                                            showPhoneCode: true,
                                            onSelect: (Country country) {
                                              _phoneCode.text = "+" + country.phoneCode;
                                            },
                                            countryListTheme: CountryListThemeData(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(40.0),
                                                topRight: Radius.circular(40.0),
                                              ),
                                              inputDecoration: InputDecoration(
                                                labelText: getTranslated(context, AppString.register_phone_code_search).toString(),
                                                hintText: getTranslated(context, AppString.register_typing_search).toString(),
                                                prefixIcon: const Icon(Icons.search),
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: hintColor.withOpacity(0.2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: width * 0.60,
                                height: height * 0.06,
                                margin: EdgeInsets.only(
                                  top: height * 0.01,
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 1),
                                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                                child: TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [new FilteringTextInputFormatter.allow(RegExp("[0-9]")), LengthLimitingTextInputFormatter(10)],
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: getTranslated(context, AppString.register_phone_no).toString(),
                                    hintStyle: TextStyle(
                                      fontSize: width * 0.04,
                                      color: hintColor,
                                    ),
                                  ),
                                  validator: (String? value) {
                                    print(' ${value!.length}');
                                    if (value.isEmpty) {
                                      return getTranslated(context, AppString.please_enter_phone_no).toString();
                                    }
                                    if (value.length != 10) {
                                      return getTranslated(context, AppString.please_enter_valid_number).toString();
                                    }
                                    return null;
                                  },
                                  onSaved: (String? name) {},
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: height * 0.01, left: width * 0.05, right: width * 0.05),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                          child: TextFormField(
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(
                              fontSize: 16,
                              color: hintColor,
                            ),
                            controller: _dob,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: getTranslated(context, AppString.register_birth_date_hint).toString(),
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: width * 0.04,
                                color: hintColor,
                              ),
                            ),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return getTranslated(context, AppString.please_select_birth_date).toString();
                              }
                              return null;
                            },
                            onTap: () {
                              _selectDate(context);
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: height * 0.01, left: width * 0.05, right: width * 0.05),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                          child: DropdownButtonFormField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: getTranslated(context, AppString.register_select_gender_hint).toString(),
                              hintStyle: TextStyle(
                                fontSize: width * 0.04,
                                color: hintColor,
                              ),
                            ),
                            value: _genderSelect,
                            isExpanded: true,
                            iconSize: 25,
                            onSaved: (dynamic value) {
                              setState(
                                () {
                                  _genderSelect = value;
                                },
                              );
                            },
                            onChanged: (dynamic newValue) {
                              setState(
                                () {
                                  _genderSelect = newValue;
                                },
                              );
                            },
                            validator: (dynamic value) => value == null ? getTranslated(context, AppString.please_select_gender).toString() : null,
                            items: gender.map(
                              (location) {
                                return DropdownMenuItem<String>(
                                  child: new Text(
                                    location,
                                    style: TextStyle(
                                      fontSize: width * 0.04,
                                      color: hintColor,
                                    ),
                                  ),
                                  value: location,
                                );
                              },
                            ).toList(),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: height * 0.01, left: width * 0.05, right: width * 0.05),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                          child: TextFormField(
                            controller: _address,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Address / Location (for map)',
                              hintStyle: TextStyle(
                                fontSize: width * 0.04,
                                color: hintColor,
                              ),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter address';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_registerAsProvider)
                          Container(
                            margin: EdgeInsets.only(top: height * 0.01, left: width * 0.05, right: width * 0.05),
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                            child: DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: _loadingProviderTypes
                                    ? 'Loading provider types...'
                                    : 'Select provider type',
                                hintStyle: TextStyle(
                                  fontSize: width * 0.04,
                                  color: hintColor,
                                ),
                              ),
                              value: _selectedProviderTypeId,
                              isExpanded: true,
                              iconSize: 25,
                              items: _providerTypes
                                  .map(
                                    (t) => DropdownMenuItem<int>(
                                      value: t['id'] is int ? t['id'] as int : int.tryParse(t['id'].toString()),
                                      child: Text(
                                        (t['name'] ?? '').toString(),
                                        style: TextStyle(
                                          fontSize: width * 0.04,
                                          color: hintColor,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedProviderTypeId = val;
                                });
                              },
                              validator: (val) {
                                if (!_registerAsProvider) return null;
                                if (val == null) {
                                  return 'Please select provider type';
                                }
                                return null;
                              },
                            ),
                          ),
                        Container(
                          margin: EdgeInsets.only(top: height * 0.01, left: width * 0.05, right: width * 0.05),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                          child: TextFormField(
                            controller: _password,
                            keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: getTranslated(context, AppString.register_password_hint).toString(),
                              hintStyle: TextStyle(
                                fontSize: width * 0.04,
                                color: hintColor,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isHidden ? Icons.visibility : Icons.visibility_off,
                                  color: passwordVisibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isHidden = !_isHidden;
                                  });
                                },
                              ),
                            ),
                            obscureText: _isHidden,
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return getTranslated(context, AppString.please_enter_password).toString();
                              } else if (value.length < 6) {
                                return getTranslated(context, AppString.please_enter_valid_password).toString();
                              }
                              return null;
                            },
                            onSaved: (String? name) {},
                          ),
                        ),
                        _buildDocumentsField(),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: height * 0.05, left: width * 0.05, right: width * 0.05, bottom: width * 0.05),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      width: width * 1.0,
                      height: height * 0.06,
                      child: ElevatedButton(
                        child: Text(
                          getTranslated(context, AppString.register_button).toString(),
                          style: TextStyle(fontSize: width * 0.045),
                          textAlign: TextAlign.center,
                        ),
                        onPressed: () {
                          if (_formkey.currentState!.validate()) {
                            callApiForRegister();
                          }
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: width * 0.08, vertical: 8),
                    child: Text(
                      getTranslated(context, AppString.register_description).toString(),
                      style: TextStyle(fontSize: width * 0.03, color: hintColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              getTranslated(context, AppString.register_all_ready_account).toString(),
                              style: TextStyle(fontSize: width * 0.035, color: hintColor),
                            ),
                          ],
                        ),
                        Container(
                          margin: EdgeInsets.only(left: width * 0.009),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, 'SignIn');
                                },
                                child: Text(getTranslated(context, AppString.register_sign_in).toString(), style: TextStyle(color: loginButton, fontWeight: FontWeight.bold, fontSize: width * 0.035)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsField() {
    return FormField<List<PlatformFile>>(
      validator: (_) => _documents.isEmpty ? 'Please upload at least one certification document' : null,
      builder: (field) {
        void onChanged() {
          field.didChange(_documents);
          if (field.hasError) field.validate();
        }

        return Container(
          margin: EdgeInsets.only(top: height * 0.01, left: width * 0.05, right: width * 0.05),
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Certification documents', style: TextStyle(fontSize: width * 0.04)),
              SizedBox(height: 4),
              Text(
                'Licence, degree or practising certificate. PDF, JPG or PNG, up to $_maxDocuments files, 5 MB each.',
                style: TextStyle(fontSize: width * 0.03, color: hintColor),
              ),
              for (final document in _documents)
                Row(
                  children: [
                    Icon(document.extension?.toLowerCase() == 'pdf' ? Icons.picture_as_pdf : Icons.image, color: hintColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text(document.name, overflow: TextOverflow.ellipsis)),
                    IconButton(
                      icon: Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() => _documents.remove(document));
                        onChanged();
                      },
                    ),
                  ],
                ),
              if (_documents.length < _maxDocuments)
                TextButton.icon(
                  onPressed: () async {
                    await _pickDocuments();
                    onChanged();
                  },
                  icon: Icon(Icons.upload_file),
                  label: Text('Add document'),
                ),
              if (field.hasError)
                Text(field.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: _documentExtensions, allowMultiple: true);
    for (final file in result?.files ?? <PlatformFile>[]) {
      if (_documents.length >= _maxDocuments) {
        CommonFunction.toastMessage('You can upload up to $_maxDocuments documents');
        break;
      }
      if (!_documentExtensions.contains(file.extension?.toLowerCase())) {
        CommonFunction.toastMessage('${file.name} must be a PDF, JPG or PNG file');
        continue;
      }
      if (file.size > _maxDocumentBytes) {
        CommonFunction.toastMessage('${file.name} is larger than 5 MB');
        continue;
      }
      if (_documents.any((document) => document.name == file.name)) continue;
      _documents.add(file);
    }
    if (mounted) setState(() {});
  }

  Future<BaseModel<Register>> callApiForRegister() async {
    newDateApiPass = DateUtilForPass().formattedDate(DateTime.parse('$_selectedDate'));

    Map<String, dynamic> body = {
      "name": _name.text,
      "email": _email.text,
      "dob": newDateApiPass,
      "gender": _genderSelect,
      "phone": _phone.text,
      "password": _password.text,
      "phone_code": _phoneCode.text,
      "address": _address.text,
    };

    if (_registerAsProvider) {
      body["provider_type_id"] = _selectedProviderTypeId;
    }

    Register response;
    try {
      CommonFunction.onLoading(context);
      final formData = FormData.fromMap(body..removeWhere((key, value) => value == null));
      for (final document in _documents) {
        formData.files.add(MapEntry(
          'documents[]',
          MultipartFile.fromBytes(await document.xFile.readAsBytes(), filename: document.name),
        ));
      }
      if (_registerAsProvider) {
        response = await RestClient(RetroApi().dioData()).providerRegisterRequest(formData);
      } else {
        response = await RestClient(RetroApi().dioData()).registerRequest(formData);
      }
      CommonFunction.hideDialog(context);
      final data = OtpData(otp: response.data!.otp, id: response.data!.id);
      response.data!.verify != 1
          ? Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PhoneVerificationScreen(data: data)),
            )
          : Navigator.pushNamed(context, 'SignIn');
      Fluttertoast.showToast(
        msg: response.msg!,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (error, stacktrace) {
      CommonFunction.hideDialog(context);
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  _selectDate(BuildContext context) async {
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null ? _selectedDate! : DateTime.now(),
      firstDate: DateTime(1950, 1),
      lastDate: DateTime.now(),
    );
    if (newSelectedDate != null) {
      _selectedDate = newSelectedDate;
      _dob
        ..text = DateFormat('dd-MM-yyyy').format(_selectedDate!)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: _dob.text.length, affinity: TextAffinity.upstream),
        );
    }
  }
}

class DateUtilForPass {
  static const DATE_FORMAT = 'yyyy-MM-dd';

  String formattedDate(DateTime dateTime) {
    return DateFormat(DATE_FORMAT).format(dateTime);
  }
}

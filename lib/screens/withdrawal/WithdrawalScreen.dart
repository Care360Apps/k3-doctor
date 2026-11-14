import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/constant/common_function.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/model/FinanceDetails.dart';
import 'package:doctro/model/payout_account.dart';
import 'package:doctro/model/withdrawal_request_model.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:doctro/retrofit/server_error.dart';
import 'package:doctro/screens/auth/SignIn.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WithdrawalScreen extends StatefulWidget {
  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late double width;
  late double height;

  List<String> _drawer = [];
  List<String> _drawerMenu = [];
  String? dName;
  String? dFullImage;
  String? phone;
  int? subscription;

  Future<WithdrawalRequestsResponse?>? _withdrawalsFuture;
  final _amountController = TextEditingController();
  double _availableBalance = 0.0;
  bool _isLoadingBalance = false;

  static const double _minWithdrawalAmount = 50.0;

  PayoutAccountData? _payoutAccount;
  bool _isLoadingAccount = false;

  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  bool get _hasPayoutAccount =>
      _payoutAccount != null &&
      (_payoutAccount!.accountName?.isNotEmpty ?? false) &&
      (_payoutAccount!.accountNumber?.isNotEmpty ?? false) &&
      (_payoutAccount!.bankName?.isNotEmpty ?? false);

  void _showNoPayoutAccountPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60, width: 60,
              decoration: BoxDecoration(
                color: loginButton.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.account_balance_rounded, color: loginButton, size: 30),
            ),
            SizedBox(height: 16),
            Text(
              'Payout Account Required',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: hintColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'You need to add your bank account details before you can request a withdrawal.',
              style: TextStyle(fontSize: 13, color: passwordVisibility, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hintColor,
                    side: BorderSide(color: divider),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Later'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openPayoutAccountDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: loginButton,
                    foregroundColor: colorWhite,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Add Account', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns translated string or fallback to avoid null labels.
  String _t(String key, String fallback) {
    final v = getTranslated(context, key);
    return (v != null && v.isNotEmpty) ? v : fallback;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _drawer = [
      _t(AppString.drawer_home, 'Home'),
      _t(AppString.drawer_payments, 'Payments'),
      _t(AppString.drawer_withdrawal, 'Withdrawal'),
      _t(AppString.drawer_canceled_appointment, 'Canceled'),
      _t(AppString.drawer_appointments, 'Appointments'),
      _t(AppString.chats, 'Chats'),
      _t(AppString.drawer_review, 'Review'),
      _t(AppString.drawer_notification, 'Notifications'),
      _t(AppString.drawer_callHistory, 'Call History'),
      _t(AppString.drawer_schedule_timing, 'Schedule Timings'),
      _t(AppString.drawer_setting, 'Settings'),
      _t(AppString.drawer_logout, 'Logout'),
    ];
    _drawerMenu = _drawer;
  }

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
    _loadPayoutAccount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _loadWithdrawals() async {
    _loadBalance();
    setState(() {
      _withdrawalsFuture = _fetchWithdrawals();
    });
  }

   Future<void> _loadBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });
    try {
      final res = await RestClient(RetroApi().dioData()).purchaseDetailsRequest();
      double total = 0.0;
      if (res.availableBalance != null) {
        total = res.availableBalance!;
      } else if (res.data != null) {
        for (final item in res.data!) {
          final bal = item.dBalance;
          if (bal != null && bal > 0) {
            total += bal;
          }
        }
      }
      if (mounted) {
        setState(() {
          _availableBalance = total;
        });
      }
    } catch (e, st) {
      if (mounted) {
        ServerError.withError(error: e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  Future<void> _loadPayoutAccount() async {
    setState(() {
      _isLoadingAccount = true;
    });
    try {
      final res = await RestClient(RetroApi().dioData()).payoutAccountShow();
      if (mounted) {
        setState(() {
          _payoutAccount = res.data;
        });
      }
    } catch (e, st) {
      if (mounted) {
        ServerError.withError(error: e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccount = false;
        });
      }
    }
  }

  void _openPayoutAccountDialog() {
    _accountNameController.text = _payoutAccount?.accountName ?? '';
    _accountNumberController.text = _payoutAccount?.accountNumber ?? '';
    _bankNameController.text = _payoutAccount?.bankName ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            bool isSaving = false;

            Future<void> save() async {
              final name = _accountNameController.text.trim();
              final number = _accountNumberController.text.trim();
              final bank = _bankNameController.text.trim();
              if (name.isEmpty || number.isEmpty || bank.isEmpty) {
                CommonFunction.toastMessage('Please fill all account fields');
                return;
              }
              setSheetState(() => isSaving = true);
              try {
                final res = await RestClient(RetroApi().dioData()).payoutAccountUpdate({
                  'account_name': name,
                  'account_number': number,
                  'bank_name': bank,
                });
                setSheetState(() => isSaving = false);
                if (res.success == true && res.data != null && mounted) {
                  setState(() => _payoutAccount = res.data);
                  Navigator.pop(ctx);
                  CommonFunction.toastMessage(res.msg ?? 'Payout account saved.');
                } else {
                  CommonFunction.toastMessage(res.msg ?? 'Failed to save payout account.');
                }
              } catch (e) {
                setSheetState(() => isSaving = false);
                ServerError.withError(error: e);
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: colorWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      margin: EdgeInsets.only(top: 12, bottom: 4),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header gradient banner
                    Container(
                      margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [loginButton, Color(0xFF005BE0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 48, width: 48,
                            decoration: BoxDecoration(
                              color: colorWhite.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.account_balance_rounded, color: colorWhite, size: 24),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _payoutAccount != null ? 'Edit Payout Account' : 'Add Payout Account',
                                  style: TextStyle(color: colorWhite, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Bank details for receiving payouts',
                                  style: TextStyle(color: colorWhite.withOpacity(0.75), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Fields
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Column(
                        children: [
                          _payoutField(
                            controller: _accountNameController,
                            label: 'Account Name',
                            hint: 'e.g. John Doe',
                            icon: Icons.person_outline_rounded,
                          ),
                          SizedBox(height: 14),
                          _payoutField(
                            controller: _bankNameController,
                            label: 'Bank Name',
                            hint: 'e.g. First Bank',
                            icon: Icons.account_balance_outlined,
                          ),
                          SizedBox(height: 14),
                          _payoutField(
                            controller: _accountNumberController,
                            label: 'Account Number',
                            hint: 'e.g. 0123456789',
                            icon: Icons.tag_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: hintColor,
                                side: BorderSide(color: divider),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(_t(AppString.cancel_button, 'Cancel'), style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isSaving ? null : save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: loginButton,
                                foregroundColor: colorWhite,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: isSaving
                                  ? SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(color: colorWhite, strokeWidth: 2),
                                    )
                                  : Text('Save Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _payoutField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 15, color: hintColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: loginButton.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: loginButton, size: 20),
        ),
        labelStyle: TextStyle(color: passwordVisibility, fontSize: 13),
        hintStyle: TextStyle(color: passwordVisibility.withOpacity(0.5), fontSize: 13),
        filled: true,
        fillColor: back,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: loginButton, width: 1.5),
        ),
      ),
    );
  }

  Future<WithdrawalRequestsResponse?> _fetchWithdrawals() async {
    try {
      final res = await RestClient(RetroApi().dioData()).withdrawalRequestsRequest();
      return res;
    } catch (e, st) {
      if (mounted) {
        ServerError.withError(error: e);
      }
      return null;
    }
  }

  Future<void> _submitWithdrawal() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      CommonFunction.toastMessage(_t(AppString.withdrawal_enter_amount, 'Please enter amount'));
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 1) {
      CommonFunction.toastMessage(_t(AppString.withdrawal_enter_valid_amount, 'Please enter a valid amount (min 1)'));
      return;
    }

    // Enforce minimum balance requirement and max amount <= available balance.
    final currencySymbol = SharedPreferenceHelper.getString(Preferences.currency_symbol);
    if (_availableBalance < _minWithdrawalAmount) {
      CommonFunction.toastMessage(
        '${_t(AppString.withdrawal_minimum_amount, 'Minimum withdrawal amount')}: '
        '$currencySymbol${_minWithdrawalAmount.toStringAsFixed(2)}',
      );
      return;
    }
    if (amount > _availableBalance) {
      CommonFunction.toastMessage(
        'You cannot withdraw more than your available balance ($currencySymbol${_availableBalance.toStringAsFixed(2)}).',
      );
      return;
    }
    if (!mounted) return;
    CommonFunction.onLoading(context);
    try {
      final res = await RestClient(RetroApi().dioData()).withdrawalRequestCreateRequest({'amount': amount});
      CommonFunction.hideDialog(context);
      if (res.success == true && mounted) {
        CommonFunction.toastMessage(res.msg ?? 'Request submitted.');
        _amountController.clear();
        Navigator.of(context).pop();
        _loadWithdrawals();
      } else {
        CommonFunction.toastMessage(res.msg ?? 'Failed.');
      }
    } catch (e, st) {
      CommonFunction.hideDialog(context);
      if (mounted) ServerError.withError(error: e);
    }
  }

  void _openRequestDialog() {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        final currencySymbol = SharedPreferenceHelper.getString(Preferences.currency_symbol);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: loginButton.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.account_balance_wallet_rounded, color: loginButton),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(AppString.withdrawal_request, 'Request Withdrawal'),
                  style: TextStyle(color: hintColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountSummaryRow(currencySymbol),
              SizedBox(height: 10),
              Text(
                '${_t(AppString.withdrawal_available_balance, 'Available balance')}: '
                '$currencySymbol${_availableBalance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13, color: passwordVisibility, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                '${_t(AppString.withdrawal_minimum_amount, 'Minimum withdrawal amount')}: '
                '$currencySymbol${_minWithdrawalAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 11, color: passwordVisibility),
              ),
              SizedBox(height: 14),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _t(AppString.withdrawal_amount_hint, 'Enter amount'),
                  prefixText: '$currencySymbol ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: back,
                ),
              ),
            ],
          ),
          actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t(AppString.cancel_button, 'Cancel'), style: TextStyle(color: passwordVisibility)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _submitWithdrawal();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: loginButton,
                foregroundColor: colorWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(_t(AppString.withdrawal_submit, 'Submit')),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(String? statusStr) {
    if (statusStr == null) return hintColor;
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return orange;
      case 'approved':
        return status;
      case 'rejected':
        return statusCancel;
      case 'paid':
        return green;
      default:
        return hintColor;
    }
  }

  void _showAlertDialog(BuildContext context) {
    Widget cancel = TextButton(
      child: Text(
        _t(AppString.cancel_button, 'Cancel'),
        style: TextStyle(color: hintColor),
      ),
      onPressed: () => Navigator.pop(context),
    );
    Widget okButton = TextButton(
      child: Text(
        _t(AppString.logout_button, 'Logout'),
        style: TextStyle(color: hintColor),
      ),
      onPressed: () async {
        try {
          await SharedPreferenceHelper.clearPrefSecurely();
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Unable to finish signing out. Please try again.'),
            ));
          }
          return;
        }
        if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (BuildContext context) => SignIn()),
              ModalRoute.withName('SignIn'),
            );
      },
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(_t(AppString.are_you_sure_logout, 'Are you sure you want to logout?')),
        actions: [cancel, okButton],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    final drawerHome = _t(AppString.drawer_home, 'Home');
    final drawerPayments = _t(AppString.drawer_payments, 'Payments');
    final drawerWithdrawal = _t(AppString.drawer_withdrawal, 'Withdrawal');
    final drawerCanceled = _t(AppString.drawer_canceled_appointment, 'Canceled');
    final drawerAppointments = _t(AppString.drawer_appointments, 'Appointments');
    final drawerReview = _t(AppString.drawer_review, 'Review');
    final drawerNotification = _t(AppString.drawer_notification, 'Notifications');
    final drawerCallHistory = _t(AppString.drawer_callHistory, 'Call History');
    final drawerSchedule = _t(AppString.drawer_schedule_timing, 'Schedule Timings');
    final drawerSetting = _t(AppString.drawer_setting, 'Settings');
    final drawerChats = _t(AppString.chats, 'Chats');
    final drawerLogout = _t(AppString.drawer_logout, 'Logout');

    Color colorWithOpacity(Color color, double opacity) => color.withValues(alpha: opacity);

    void handleDrawerSelection(String label) {
      if (label == drawerHome) {
        Navigator.popAndPushNamed(context, "loginHome");
      } else if (label == drawerPayments) {
        Navigator.popAndPushNamed(context, 'payment');
      } else if (label == drawerWithdrawal) {
        Navigator.pop(context);
      } else if (label == drawerCanceled) {
        Navigator.popAndPushNamed(context, 'cancelAppoitmentRoutes');
      } else if (label == drawerAppointments) {
        Navigator.popAndPushNamed(context, 'AppointmentHistoryScreen');
      } else if (label == drawerReview) {
        Navigator.popAndPushNamed(context, 'rateAndReviewRoutes');
      } else if (label == drawerNotification) {
        Navigator.popAndPushNamed(context, 'notifications');
      } else if (label == drawerCallHistory) {
        Navigator.popAndPushNamed(context, 'VideoCallHistory');
      } else if (label == drawerSchedule) {
        Navigator.popAndPushNamed(context, 'Schedule Timings');
      } else if (label == drawerSetting) {
        Navigator.popAndPushNamed(context, 'Settings');
      } else if (label == drawerChats) {
        Navigator.popAndPushNamed(context, 'ChatHome');
      } else if (label == drawerLogout) {
        _showAlertDialog(context);
      }
    }

    IconData drawerIcon(String label) {
      if (label == drawerHome) return Icons.home_rounded;
      if (label == drawerPayments) return Icons.payments_rounded;
      if (label == drawerWithdrawal) return Icons.account_balance_wallet_rounded;
      if (label == drawerCanceled) return Icons.event_busy_rounded;
      if (label == drawerAppointments) return Icons.event_note_rounded;
      if (label == drawerReview) return Icons.star_rate_rounded;
      if (label == drawerNotification) return Icons.notifications_rounded;
      if (label == drawerCallHistory) return Icons.call_rounded;
      if (label == drawerSchedule) return Icons.schedule_rounded;
      if (label == drawerSetting) return Icons.settings_rounded;
      if (label == drawerChats) return Icons.chat_bubble_outline_rounded;
      if (label == drawerLogout) return Icons.logout_rounded;
      return Icons.circle;
    }

    return WillPopScope(
      onWillPop: () {
        Navigator.pushNamedAndRemoveUntil(context, 'loginHome', (route) => false);
        return Future.value(false);
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(
          colorWithOpacity,
          drawerLogout,
          drawerChats,
          handleDrawerSelection,
          drawerIcon,
        ),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colorWhite,
          foregroundColor: hintColor,
          title: Text(
            _t(AppString.drawer_withdrawal, 'Withdrawal'),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.add_rounded,
                color: _hasPayoutAccount ? loginButton : passwordVisibility,
              ),
              onPressed: _hasPayoutAccount ? _openRequestDialog : _showNoPayoutAccountPrompt,
              tooltip: _hasPayoutAccount
                  ? _t(AppString.withdrawal_request, 'Request Withdrawal')
                  : 'Add payout account first',
            ),
          ],
        ),
        body: Container(
          color: back,
          child: RefreshIndicator(
            onRefresh: _loadWithdrawals,
            child: FutureBuilder<WithdrawalRequestsResponse?>(
              future: _withdrawalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null && _isLoadingBalance) {
                  return Center(child: CircularProgressIndicator(color: loginButton));
                }
                final data = snapshot.data?.data ?? [];
                if (data.isEmpty) {
                  return ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      _buildBalanceCard(),
                      SizedBox(height: 24),
                      Icon(Icons.account_balance_wallet_rounded, size: 72, color: passwordVisibility),
                      SizedBox(height: 16),
                      Text(
                        _t(AppString.withdrawal_empty, 'No withdrawal requests yet. Request a withdrawal to get started.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: passwordVisibility),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _hasPayoutAccount ? _openRequestDialog : _showNoPayoutAccountPrompt,
                        icon: Icon(_hasPayoutAccount ? Icons.add_rounded : Icons.lock_outline_rounded, size: 22),
                        label: Text(_hasPayoutAccount
                            ? _t(AppString.withdrawal_request, 'Request Withdrawal')
                            : 'Add payout account first'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasPayoutAccount ? loginButton : passwordVisibility,
                          foregroundColor: colorWhite,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: data.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildBalanceCard();
                    }
                    final item = data[index - 1];
                    final status = item.status ?? 'pending';
                    final dateStr = item.createdAt != null
                        ? DateFormat.yMMMd().add_Hm().format(DateTime.tryParse(item.createdAt!) ?? DateTime.now())
                        : '—';
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colorWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: divider),
                        boxShadow: [
                          BoxShadow(
                            color: colorWithOpacity(black, 0.06),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.amount?.toStringAsFixed(2) ?? '0'}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: hintColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(dateStr, style: TextStyle(fontSize: 12, color: passwordVisibility)),
                            if (item.rejectedReason != null && item.rejectedReason!.isNotEmpty) ...[
                              SizedBox(height: 6),
                              Text(
                                item.rejectedReason!,
                                style: TextStyle(fontSize: 12, color: statusCancel),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _hasPayoutAccount ? _openRequestDialog : _showNoPayoutAccountPrompt,
          backgroundColor: _hasPayoutAccount ? loginButton : passwordVisibility,
          icon: Icon(
            _hasPayoutAccount ? Icons.add_rounded : Icons.lock_outline_rounded,
            color: colorWhite,
          ),
          label: Text(
            _hasPayoutAccount
                ? _t(AppString.withdrawal_request, 'Request Withdrawal')
                : 'Add payout account first',
            style: TextStyle(color: colorWhite, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(
    Color Function(Color, double) colorWithOpacity,
    String drawerLogout,
    String drawerChats,
    void Function(String) handleDrawerSelection,
    IconData Function(String) drawerIcon,
  ) {
    return Drawer(
      child: Container(
        color: back,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _drawer.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final label = _drawer[index];
                    final isLogout = label == drawerLogout;
                    final iconColor = isLogout ? red : loginButton;
                    final textColor = isLogout ? red : hintColor;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => handleDrawerSelection(label),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: divider),
                          boxShadow: [
                            BoxShadow(
                              color: colorWithOpacity(black, 0.06),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: colorWithOpacity(iconColor, 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(drawerIcon(label), color: iconColor, size: 20),
                          ),
                          title: Text(
                            label,
                            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded, color: passwordVisibility),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          horizontalTitleGap: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final currencySymbol = SharedPreferenceHelper.getString(Preferences.currency_symbol);
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  loginButton,
                  Color(0xFF005BE0),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: loginButton.withOpacity(0.25),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(AppString.withdrawal_available_balance, 'Available balance'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '$currencySymbol${_availableBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: colorWhite,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${_t(AppString.withdrawal_minimum_amount, 'Minimum withdrawal amount')}: '
                          '$currencySymbol${_minWithdrawalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: colorWhite.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: colorWhite,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                _buildAccountSummaryRow(currencySymbol),
              ],
            ),
          ),
          Positioned(
            bottom: -24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickActionChip(
                  icon: Icons.account_balance_rounded,
                  label: _hasPayoutAccount ? 'Edit account' : 'Add account',
                  onTap: _openPayoutAccountDialog,
                  highlight: !_hasPayoutAccount,
                ),
                _quickActionChip(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: () {
                    // Already on history; just scroll to list.
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummaryRow(String currencySymbol) {
    final hasAccount = _payoutAccount != null &&
        (_payoutAccount!.accountName?.isNotEmpty ?? false) &&
        (_payoutAccount!.accountNumber?.isNotEmpty ?? false);
    final accountName = _payoutAccount?.accountName ?? '';
    final accountNumber = _payoutAccount?.accountNumber ?? '';
    final bankName = _payoutAccount?.bankName ?? '';

    return Row(
      children: [
        Icon(
          hasAccount ? Icons.account_balance_rounded : Icons.info_outline_rounded,
          size: 18,
          color: passwordVisibility,
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            hasAccount
                ? '$accountName • $bankName • $accountNumber'
                : 'No payout account set. Please add your bank details.',
            style: TextStyle(fontSize: 11, color: passwordVisibility),
          ),
        ),
        TextButton(
          onPressed: _openPayoutAccountDialog,
          child: Text(
            hasAccount ? 'Edit' : 'Add',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _quickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? Colors.orange.shade50 : colorWhite,
          borderRadius: BorderRadius.circular(24),
          border: highlight ? Border.all(color: Colors.orange.shade200) : null,
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: highlight ? Colors.orange.shade700 : loginButton),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: highlight ? Colors.orange.shade800 : hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

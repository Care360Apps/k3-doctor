import 'package:flutter/material.dart';
import 'workforce_api.dart';
import 'workforce_notice_gate.dart';

class CareerPasswordScreen extends StatefulWidget {
  const CareerPasswordScreen({super.key, required this.api});
  final WorkforceApi api;
  @override
  State<CareerPasswordScreen> createState() => _CareerPasswordScreenState();
}

class _CareerPasswordScreenState extends State<CareerPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _code = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _sent = false, _busy = false;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (!_sent) {
        await widget.api.requestRecovery(_email.text);
        if (mounted)
          setState(() {
            _sent = true;
            _message =
                'If an active account exists, recovery instructions will be sent to its email address. Check your mailbox or contact support.';
          });
      } else {
        await widget.api.completeRecovery(
          _email.text,
          _code.text,
          _password.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Career password updated. Sign in again.'),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _message = e is WorkforceApiException
              ? e.message
              : 'Recovery unavailable. Please retry.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recover career account')),
    body: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'This changes only your separate career/training password. It does not change your Patient or Plus clinical password.',
            ),
            if (WorkforceNoticeGate.localDemo)
              const Text('Demo accounts do not send real email.'),
            TextFormField(
              controller: _email,
              enabled: !_busy,
              readOnly: _sent,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              maxLength: 190,
              decoration: const InputDecoration(
                labelText: 'Career account email',
              ),
              validator: (v) =>
                  (v ?? '').contains('@') ? null : 'Enter your account email.',
            ),
            if (_sent) ...[
              TextFormField(
                controller: _code,
                enabled: !_busy,
                autocorrect: false,
                maxLength: 64,
                decoration: const InputDecoration(
                  labelText: 'Single-use recovery code from email',
                ),
                validator: (v) =>
                    RegExp(r'^[a-fA-F0-9]{64}$').hasMatch((v ?? '').trim())
                    ? null
                    : 'Enter the recovery code from your email.',
              ),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                maxLength: 128,
                decoration: const InputDecoration(
                  labelText: 'New career password',
                ),
                validator: (v) => (v ?? '').length >= 12
                    ? null
                    : 'Use at least 12 characters.',
              ),
              TextFormField(
                controller: _confirm,
                enabled: !_busy,
                obscureText: true,
                maxLength: 128,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (v) =>
                    v == _password.text ? null : 'Passwords must match.',
              ),
            ],
            if (_message != null) Text(_message!),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(
                _busy
                    ? 'Please wait…'
                    : _sent
                    ? 'Update career password'
                    : 'Request recovery code',
              ),
            ),
            if (_sent)
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _sent = false;
                          _message = null;
                          _code.clear();
                          _password.clear();
                          _confirm.clear();
                        });
                      },
                child: const Text('Use another email'),
              ),
          ],
        ),
      ),
    ),
  );
}

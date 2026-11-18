import 'career_password_screen.dart';
import 'package:flutter/material.dart';

import 'workforce_api.dart';
import 'workforce_notice_gate.dart';
import 'workforce_data_use_notice.dart';
import 'workforce_dashboard.dart';
import 'workforce_landing.dart';

class WorkforceAccessScreen extends StatefulWidget {
  const WorkforceAccessScreen({
    super.key,
    required this.accountType,
    required this.api,
    this.initiallyRegistering = true,
  });

  final String accountType;
  final WorkforceApi api;
  final bool initiallyRegistering;

  @override
  State<WorkforceAccessScreen> createState() => _WorkforceAccessScreenState();
}

class _WorkforceAccessScreenState extends State<WorkforceAccessScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = true;
  bool _adult = false;
  bool _terms = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _registering = widget.initiallyRegistering;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_registering && !WorkforceNoticeGate.configured) {
      setState(
        () => _message =
            'Workforce applications are closed until the recruitment privacy notice is approved.',
      );
      return;
    }
    if (_registering && (!_adult || !_terms)) {
      setState(
        () => _message =
            'Please confirm you are 18 or older and accept the Workforce terms.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_registering) {
        await widget.api.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          accountType: widget.accountType,
          adultAttestation: _adult,
          acceptedTerms: _terms,
        );
        if (!mounted) return;
        setState(() {
          _registering = false;
          _message =
              'Account created. Sign in to complete your profile. '
              'All qualifications remain unverified until reviewed.';
        });
      } else {
        final role = await widget.api.login(_email.text, _password.text);
        if (role != widget.accountType) {
          await widget.api.logout();
          throw const WorkforceApiException(
            'This account belongs to another Workforce registration type.',
          );
        }
        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                WorkforceDashboardScreen(api: widget.api, role: role),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = error is WorkforceApiException
              ? error.message
              : 'Could not complete this request. Check your details or network.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCandidate = widget.accountType == 'candidate';
    return Scaffold(
      appBar: AppBar(
        title: Text(isCandidate ? 'Join Workforce' : 'Employer registration'),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: workforceTeal,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                _registering
                    ? (isCandidate
                          ? 'Start your career profile'
                          : 'Verify your organization')
                    : 'Sign in to Workforce',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: workforceNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isCandidate
                    ? 'Student and graduate credentials are checked independently. '
                          'Your patient records are never part of this profile.'
                    : 'Only independently approved hospitals and companies '
                          'can browse verified applicants.',
                style: const TextStyle(color: Color(0xFF516B72), height: 1.45),
              ),
              const SizedBox(height: 20),
              if (!_registering)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                CareerPasswordScreen(api: widget.api),
                          ),
                        ),
                  child: const Text('Forgot career password?'),
                ),
              if (_registering) ...[
                TextFormField(
                  key: const Key('workforce-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Enter your full name'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                key: const Key('workforce-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email address'),
                validator: (v) =>
                    !RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch((v ?? '').trim())
                    ? 'Enter a valid email address'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('workforce-password'),
                controller: _password,
                obscureText: true,
                autofillHints: [
                  _registering
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                decoration: const InputDecoration(
                  labelText: 'Password (12+ characters)',
                ),
                validator: (v) => (v?.length ?? 0) < 12
                    ? 'Enter at least 12 characters'
                    : null,
              ),
              if (_registering) ...[
                const SizedBox(height: 10),
                CheckboxListTile(
                  key: const Key('workforce-adult'),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('I am at least 18 years old'),
                  contentPadding: EdgeInsets.zero,
                  value: _adult,
                  onChanged: (v) => setState(() => _adult = v ?? false),
                ),
                WorkforceDataUseNotice(accountType: widget.accountType),
                CheckboxListTile(
                  key: const Key('workforce-terms'),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I have read the Workforce recruitment '
                    'privacy notice and agree to the profile verification process',
                  ),
                  subtitle: const Text(
                    'Your consent to appear in talent search is requested '
                    'separately after verification.',
                  ),
                  contentPadding: EdgeInsets.zero,
                  value: _terms,
                  onChanged: !WorkforceNoticeGate.configured
                      ? null
                      : (v) => setState(() => _terms = v ?? false),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  key: const Key('workforce-message'),
                  style: const TextStyle(color: workforceNavy, height: 1.4),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('workforce-submit'),
                onPressed:
                    _busy || (_registering && !WorkforceNoticeGate.configured)
                    ? null
                    : _submit,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _registering ? 'Create Workforce account' : 'Sign in',
                        ),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _registering = !_registering;
                        _message = null;
                      }),
                child: Text(
                  _registering
                      ? 'Already registered? Sign in'
                      : 'Need an account? Register',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Care360 Workforce uses an independent login. '
                'This account cannot access Care360 Patient clinical records.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF536B72)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

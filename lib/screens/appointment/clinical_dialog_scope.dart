import 'package:flutter/material.dart';

/// Dialog futures complete before their closing animation removes the fields.
/// Own controllers until the route widget is unmounted, avoiding early disposal.
class ClinicalDialogControllerScope extends StatefulWidget {
  const ClinicalDialogControllerScope({
    super.key,
    required this.controllers,
    required this.child,
  });
  final List<TextEditingController> controllers;
  final Widget child;
  @override
  State<ClinicalDialogControllerScope> createState() =>
      _ClinicalDialogControllerScopeState();
}

class _ClinicalDialogControllerScopeState
    extends State<ClinicalDialogControllerScope> {
  @override
  void dispose() {
    for (final c in widget.controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

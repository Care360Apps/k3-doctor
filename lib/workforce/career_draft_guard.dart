import 'package:flutter/material.dart';

class CareerDraftGuard extends StatefulWidget {
  const CareerDraftGuard({
    super.key,
    required this.isDirty,
    required this.isBusy,
    required this.child,
  });
  final bool Function() isDirty, isBusy;
  final Widget child;
  @override
  State<CareerDraftGuard> createState() => _CareerDraftGuardState();
}

class _CareerDraftGuardState extends State<CareerDraftGuard> {
  bool _allow = false, _asking = false;
  Future<void> _back(Object? result) async {
    if (_asking || widget.isBusy()) return;
    _asking = true;
    var leave = !widget.isDirty();
    if (!leave)
      leave =
          await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Discard unsaved entries?'),
              content: const Text('Your changes have not been submitted.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Keep editing'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          ) ==
          true;
    _asking = false;
    if (!leave || !mounted) return;
    setState(() => _allow = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _allow,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back(result);
    },
    child: widget.child,
  );
}

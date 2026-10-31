import 'package:flutter/material.dart';

/// Shared Care360 master logo with the professional product label.
///
/// Care360 Plus intentionally shares the original logo with Care360 Patient.
/// The caption differentiates the doctor experience; it is not another logo.
class Care360MasterBrand extends StatelessWidget {
  const Care360MasterBrand({
    super.key,
    this.onDark = false,
    this.logoSize = 64,
  });

  final bool onDark;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Care360, quality healthcare for all. Care360 Plus',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/care360_master_logo.webp',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 5),
          Text(
            'Care360 Plus',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onDark ? Colors.white : const Color(0xFF102B48),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

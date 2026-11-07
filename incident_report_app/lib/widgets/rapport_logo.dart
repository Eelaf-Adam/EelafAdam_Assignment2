import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class RapportLogo extends StatelessWidget {
  const RapportLogo({super.key, this.fontSize = 32});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Rap',
            style: style.copyWith(color: AppColors.textPrimary),
          ),
          TextSpan(
            text: 'port',
            style: style.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

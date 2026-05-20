import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_scaffold.dart';

class DiscoPage extends StatelessWidget {
  const DiscoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Disco',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Disco',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your widgets here.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

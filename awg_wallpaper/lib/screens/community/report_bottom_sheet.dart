import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/community_provider.dart';

class ReportBottomSheet extends StatefulWidget {
  final int postId;
  const ReportBottomSheet({super.key, required this.postId});

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  String? _selectedReason;
  bool _isSubmitting = false;

  static const _reasons = [
    ('spam', 'Spam', Icons.report_gmailerrorred_outlined),
    ('nudity', 'Nudity / Adult Content', Icons.no_adult_content_outlined),
    ('copyright', 'Copyright Violation', Icons.copyright_outlined),
    ('other', 'Other', Icons.flag_outlined),
  ];

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _isSubmitting = true);

    try {
      await context
          .read<CommunityProvider>()
          .reportPost(widget.postId, _selectedReason!);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report submitted. Thank you for helping keep the community safe.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.getBackground(isDark),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Report Post',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Why are you reporting this post?',
              style: TextStyle(
                  fontSize: 14, color: AppTheme.getTextMuted(isDark)),
            ),

            const SizedBox(height: 20),

            // Reason options
            ...List.generate(_reasons.length, (i) {
              final (value, label, icon) = _reasons[i];
              final selected = _selectedReason == value;
              return GestureDetector(
                onTap: () => setState(() => _selectedReason = value),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : AppTheme.getSurface(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 20,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.getTextMuted(isDark)),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.getTextPrimary(isDark),
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.primary, size: 18),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_selectedReason == null || _isSubmitting) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor:
                      AppTheme.primary.withValues(alpha: 0.4),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 15),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

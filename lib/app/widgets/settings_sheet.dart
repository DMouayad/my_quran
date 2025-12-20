import 'package:flutter/material.dart';
import 'package:my_quran/app/utils.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  // Helper to launch URL
  Future<void> _launchGithub() async {
    // final Uri url = Uri.parse('https://github.com/dmouayad/my_quran');
    // if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    //   debugPrint('Could not launch $url');
    // }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      // Add padding for safe area
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 1. App Icon & Identity ---
          Image.asset(
            'assets/icon.png',
            width: 50,
            height: 50,
            color: const Color(0xFF0F766E),
            fit: BoxFit.fill,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('قرآني', style: TextStyle(fontSize: 25)),
          ),
          // --- 3. Github / Open Source Card ---
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _launchGithub,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surfaceContainerLow.applyOpacity(0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.code_rounded,
                        size: 20,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'كود المصدر (GitHub)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'ساهم في تطوير التطبيق',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- 4. Footer (Version) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_outlined,
                size: 14,
                color: colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                'الإصدار 1.0.1',
                style: TextStyle(
                  color: colorScheme.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // Add bottom padding for safe area if not handled by container
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

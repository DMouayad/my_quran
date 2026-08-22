import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/backup_service.dart';
import 'package:my_quran/app/services/search_service.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/quran/quran.dart';
part 'general_settings.dart';
part 'appearance_settings.dart';
part 'backup_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.fontController,
    required this.settingsController,
    super.key,
  });

  final SettingsController settingsController;
  final FontSizeController fontController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isDesktop ? const .all(12) : .zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: context.colorScheme.surfaceContainer,
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge([fontController, settingsController]),
        builder: (context, _) {
          final section = settingsController.section;

          return Row(
            children: [
              if (isDesktop || kIsWeb) ...[
                SettingsNavigator(controller: settingsController),
                const VerticalDivider(),
              ],

              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ListView(
                            padding: isMobile
                                ? const .all(12)
                                : const .symmetric(horizontal: 50, vertical: 5),
                            children: [
                              if (section == SettingSection.general.index)
                                GeneralSettings(
                                  settingsController: settingsController,
                                ),

                              if (section == SettingSection.appearance.index)
                                AppearanceSettings(
                                  fontController: fontController,
                                  settingsController: settingsController,
                                ),

                              if (section == SettingSection.backup.index)
                                const BackupSettings(),
                            ],
                          ),
                          closeButton(),
                        ],
                      ),
                    ),

                    if (isMobile) ...[
                      const Divider(),
                      SettingsNavigator(controller: settingsController),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget closeButton() {
    if (isMobile) return const SizedBox.shrink();
    return const Positioned(left: 0, top: 0, child: CloseButton());
  }
}

// ───────────────────────── helpers ─────────────────────────

ButtonStyle _segmentStyle(ColorScheme colorScheme) {
  return ButtonStyle(
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    ),
    foregroundColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? colorScheme.onPrimary
          : colorScheme.onSurfaceVariant,
    ),
    backgroundColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? colorScheme.primary
          : Colors.transparent,
    ),
    side: WidgetStatePropertyAll(BorderSide(color: colorScheme.outlineVariant)),
  );
}

enum SettingSection { general, appearance, backup }

typedef _NavigationItem = ({String label, IconData icon});

class SettingsNavigator extends StatelessWidget {
  const SettingsNavigator({required this.controller, super.key});

  final SettingsController controller;

  List<_NavigationItem> get _items => [
    (label: 'عام', icon: Icons.tune),
    (label: 'المظهر', icon: Icons.palette_outlined),
    (label: 'النسخ الاحتياطي', icon: Icons.backup_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return switch (isMobile) {
      true => _buildMobileLayout(),
      false => _buildDesktopLayout(context),
    };
  }

  NavigationBar _buildMobileLayout() {
    return NavigationBar(
      selectedIndex: controller.section,
      onDestinationSelected: (index) => controller.section = index,
      destinations: _items.map((item) {
        return NavigationDestination(icon: Icon(item.icon), label: item.label);
      }).toList(),
    );
  }

  NavigationRail _buildDesktopLayout(BuildContext context) {
    return NavigationRail(
      selectedIndex: controller.section,
      onDestinationSelected: (index) => controller.section = index,
      labelType: .all,
      backgroundColor: context.colorScheme.surfaceContainer,
      destinations: _items.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          label: Text(item.label),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────
// Stepper row (unchanged)
// ─────────────────────────────────────────

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    this.isDefault = false,
    this.onReset,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onReset;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: context.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          if (onReset != null && !isDefault) ...[
            const SizedBox(height: 6),
            IconButton.filledTonal(
              onPressed: onReset,
              icon: const Icon(Icons.restore),
              iconSize: 20,
              tooltip: 'الافتراضي',
            ),
          ],
          const Spacer(),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onDecrease,
                  icon: Icon(
                    Icons.remove,
                    size: 18,
                    color: onDecrease != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.applyOpacity(0.25),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.arabicNumbersFontFamily.name,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onIncrease,
                  icon: Icon(
                    Icons.add,
                    size: 18,
                    color: onIncrease != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.applyOpacity(0.25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Segmented row (unchanged)
// ─────────────────────────────────────────

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 14,
            children: [
              Icon(icon, size: 22, color: context.colorScheme.onSurfaceVariant),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Action row (used for backup)
// ─────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
    );
  }
}

// ─────────────────────────────────────────
// Toggle row (kept as-is)
// ─────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.subtitle,
    this.padding,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTextStyle(
      style: TextStyle(
        color: enabled ? context.colorScheme.onSurface : Colors.black26,
      ),
      child: InkWell(
        onTap: !enabled ? null : () => onChanged(!value),
        child: Padding(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: !enabled
                    ? Colors.black26
                    : value
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: enabled && value,
                onChanged: enabled ? onChanged : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

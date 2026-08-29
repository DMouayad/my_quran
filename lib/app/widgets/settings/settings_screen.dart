import 'dart:async';

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

  List<Widget> _sectionWidgets(SettingSection section) => [
    if (section == SettingSection.general)
      GeneralSettings(settingsController: settingsController),
    if (section == SettingSection.appearance)
      AppearanceSettings(
        fontController: fontController,
        settingsController: settingsController,
      ),
    if (section == SettingSection.backup) const BackupSettings(),
  ];

  String _sectionTitle(SettingSection s) => switch (s) {
    SettingSection.general => 'عام',
    SettingSection.appearance => 'المظهر',
    SettingSection.backup => 'النسخ الاحتياطي',
  };

  Widget _header(BuildContext context, SettingSection section) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _sectionTitle(section),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const CloseButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = isCompactWidth(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
        maxWidth: 700,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.colorScheme.surfaceContainer,
        ),
        child: ListenableBuilder(
          listenable: Listenable.merge([fontController, settingsController]),
          builder: (context, _) {
            final section = settingsController.section;

            if (compact) {
              return Column(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: ListView(
                        key: ValueKey(section),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        children: _sectionWidgets(section),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SettingsNavigator(
                    controller: settingsController,
                    compact: true,
                  ),
                ],
              );
            }
            // Desktop: NavigationRail
            return SizedBox(
              height: screenHeight * 0.75,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsNavigator(
                    controller: settingsController,
                    compact: false,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        _header(context, section),
                        const Divider(height: 1),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: ListView(
                              key: ValueKey(section),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              children: _sectionWidgets(section),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────── design system ─────────────────────────

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon, {this.color, this.enabled = true});

  final IconData icon;
  final Color? color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tint = !enabled ? scheme.onSurfaceVariant : (color ?? scheme.primary);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.applyOpacity(enabled ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: tint.applyOpacity(enabled ? 1 : 0.5)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _SettingsIcon(icon, color: iconColor, enabled: enabled),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? scheme.onSurface
                            : scheme.onSurface.applyOpacity(0.4),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant.applyOpacity(
                            enabled ? 1 : 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, this.title, super.key});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 8),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: scheme.primary,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Divider(
                      height: 1,
                      indent: 62,
                      color: scheme.outlineVariant.applyOpacity(0.35),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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

class SettingsNavigator extends StatelessWidget {
  const SettingsNavigator({
    required this.controller,
    required this.compact,
    super.key,
  });

  final SettingsController controller;
  final bool compact;

  static const Map<SettingSection, ({String label, IconData icon})> _meta = {
    SettingSection.general: (label: 'عام', icon: Icons.tune),
    SettingSection.appearance: (label: 'المظهر', icon: Icons.palette_outlined),
    SettingSection.backup: (
      label: 'النسخ الاحتياطي',
      icon: Icons.backup_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) =>
      compact ? _buildMobileLayout() : _buildDesktopLayout(context);

  NavigationBar _buildMobileLayout() {
    return NavigationBar(
      selectedIndex: SettingSection.values.indexOf(controller.section),
      onDestinationSelected: (index) =>
          controller.section = SettingSection.values[index],
      destinations: SettingSection.values.map((s) {
        final m = _meta[s]!;
        return NavigationDestination(icon: Icon(m.icon), label: m.label);
      }).toList(),
    );
  }

  NavigationRail _buildDesktopLayout(BuildContext context) {
    final scheme = context.colorScheme;
    return NavigationRail(
      selectedIndex: SettingSection.values.indexOf(controller.section),
      onDestinationSelected: (index) =>
          controller.section = SettingSection.values[index],
      labelType: NavigationRailLabelType.all,
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      destinations: [
        for (final s in SettingSection.values)
          NavigationRailDestination(
            icon: Icon(_meta[s]!.icon),
            label: Text(_meta[s]!.label),
          ),
      ],
    );
  }
}

// ───────────────────────── toggle row ─────────────────────────

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
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      iconColor: value ? null : context.colorScheme.onSurfaceVariant,
      onTap: () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ───────────────────────── action row ─────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      iconColor: destructive ? scheme.error : iconColor,
      trailing: Icon(
        Icons.chevron_right,
        color: scheme.onSurfaceVariant.applyOpacity(0.6),
      ),
    );
  }
}

// ───────────────────────── stepper row ─────────────────────────

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
    final scheme = context.colorScheme;
    return _SettingsTile(
      icon: icon,
      title: label,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onReset != null && !isDefault)
            IconButton(
              onPressed: onReset,
              icon: const Icon(Icons.restore, size: 18),
              tooltip: 'الافتراضي',
              visualDensity: VisualDensity.compact,
              color: scheme.primary,
            ),
          _Stepper(
            value: value,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.applyOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onPressed: onDecrease),
          SizedBox(
            width: 40,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: FontFamily.arabicNumbersFontFamily.name,
                color: scheme.onSurface,
              ),
            ),
          ),
          _StepperButton(icon: Icons.add, onPressed: onIncrease),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 16,
          color: onPressed != null
              ? scheme.onSurface
              : scheme.onSurface.applyOpacity(0.25),
        ),
      ),
    );
  }
}

// ───────────────────────── segmented row ─────────────────────────

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
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 14,
            children: [
              Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
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

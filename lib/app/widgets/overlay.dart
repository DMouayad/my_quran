import 'package:flutter/material.dart';
import 'package:my_quran/app/utils.dart';

typedef OverlayPresenter<T> = Future<T?> Function(BuildContext context, Widget widget);

/// Shows a platform-specific overlay.
///
/// - On mobile: uses [showModalBottomSheet].
/// - On desktop and web: uses [showDialog].
///
/// [mobilePresenter] and [desktopPresenter] allows 
/// custom presenter for each platform (e.g. use [showAdaptiveDialog] 
/// in some cases in mobile platform).
Future<T?> showOverlay<T>(
  BuildContext context, {
  required Widget widget,
  MobileOverlayConfig mobileConfig = const MobileOverlayConfig(),
  OverlayPresenter<T>? mobilePresenter,
  DesktopOverlayConfig desktopConfig = const DesktopOverlayConfig(),
  OverlayPresenter<T>? desktopPresenter,
}) async {
  if (isMobile) {
    return mobilePresenter != null
        ? await mobilePresenter(context, widget)
        : await _defaultMobileOverlay<T>(context, widget, mobileConfig);
  } else {
    /// For now, we don't need a separate Web function, as dialogs work
    /// well on both platforms.
    return desktopPresenter != null
        ? await desktopPresenter(context, widget)
        : await _defaultDesktopOverlay<T>(context, widget, desktopConfig);
  }
}

Future<T?> _defaultMobileOverlay<T>(
  BuildContext context,
  Widget widget,
  MobileOverlayConfig config,
) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (_) => widget,
    useRootNavigator: config.useRootNavigator,
    useSafeArea: config.useSafeArea,
    constraints: config.constraints,
    isScrollControlled: config.isScrollControlled,
    showDragHandle: config.showDragHandle,
    barrierColor: config.barrierColor,
  );
}

Future<T?> _defaultDesktopOverlay<T>(
  BuildContext context,
  Widget widget,
  DesktopOverlayConfig config,
) {
  return showDialog<T>(
    context: context,
    useRootNavigator: config.useRootNavigator,
    useSafeArea: config.useSafeArea,
    barrierColor: config.barrierColor,
    builder: (_) => Dialog(
      constraints: config.constraints,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: widget,
    ),
  );
}

/// Combines common properties for "show" functions 
/// (e.g., showDialog, showModal) to reduce redundancy.
abstract class OverlayConfig {
  const OverlayConfig({
    this.useRootNavigator = false,
    this.useSafeArea = false,
    this.constraints,
    this.barrierColor,
  });

  final bool useRootNavigator;
  final bool useSafeArea;
  final BoxConstraints? constraints;
  final Color? barrierColor;
}

/// Configuration for the overlay used in the mobile [showModalBottomSheet].
class MobileOverlayConfig extends OverlayConfig {
  const MobileOverlayConfig({
    super.useRootNavigator,
    super.useSafeArea,
    super.constraints, 
    super.barrierColor,
    this.isScrollControlled = false,
    this.showDragHandle,
  });

  final bool isScrollControlled;
  final bool? showDragHandle;
}

/// Configuration for the overlay used in the Desktop and Web [showDialog].
class DesktopOverlayConfig extends OverlayConfig {
  const DesktopOverlayConfig({
    super.useRootNavigator = true,
    super.useSafeArea,
    super.constraints, 
    super.barrierColor,
  });
}

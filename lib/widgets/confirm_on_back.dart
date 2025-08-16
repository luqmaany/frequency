import 'package:flutter/material.dart';

/// A reusable wrapper that intercepts back navigation (system back or gesture)
/// and shows a confirmation dialog. Use this around any screen `Scaffold`.
class ConfirmOnBack extends StatelessWidget {
  final Widget child;

  /// If provided, this builder is used to create the confirmation dialog.
  /// The dialog should call `Navigator.of(context).pop(true)` to confirm,
  /// or `Navigator.of(context).pop(false)` to cancel.
  final Widget Function(BuildContext context)? dialogBuilder;

  /// Optional callback invoked when the user confirms leaving.
  /// Use this to perform cleanup (e.g., clear state, navigate to home).
  /// If provided, the back pop will NOT be performed by this widget; your
  /// callback should handle navigation. In that case this widget returns false
  /// to prevent double-pop.
  final Future<void> Function(BuildContext context)? onConfirmed;

  /// If no [dialogBuilder] is provided, these fields configure the default dialog.
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool barrierDismissible;

  /// Optional override for back handling. If provided and returns false,
  /// the back action is cancelled without showing a dialog.
  /// If it returns true, the normal confirmation flow runs.
  final Future<bool> Function(BuildContext context)? onWillPopOverride;

  const ConfirmOnBack({
    super.key,
    required this.child,
    this.dialogBuilder,
    this.onConfirmed,
    this.onWillPopOverride,
    this.title = 'Leave this screen?',
    this.message = 'Your progress may be lost. Do you want to leave?',
    this.confirmText = 'Leave',
    this.cancelText = 'Stay',
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (onWillPopOverride != null) {
          final bool proceed = await onWillPopOverride!(context);
          if (!proceed) return false;
        }
        final bool? shouldLeave = await showDialog<bool>(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (ctx) {
            if (dialogBuilder != null) {
              return dialogBuilder!(ctx);
            }
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(cancelText),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmText),
                ),
              ],
            );
          },
        );
        if (shouldLeave == true) {
          if (onConfirmed != null) {
            await onConfirmed!(context);
            return false; // we handled navigation in callback
          }
          return true;
        }
        return false;
      },
      child: child,
    );
  }
}

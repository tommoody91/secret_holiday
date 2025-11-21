import 'package:flutter/material.dart';
import 'package:secret_holiday_app/core/presentation/widgets/dialogs.dart';

/// Helper class for showing snackbars (compatibility wrapper)
class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    AppSnackBar.show(
      context: context,
      message: message,
      type: SnackBarType.success,
    );
  }
  
  static void showError(BuildContext context, String message) {
    AppSnackBar.show(
      context: context,
      message: message,
      type: SnackBarType.error,
    );
  }
  
  static void showInfo(BuildContext context, String message) {
    AppSnackBar.show(
      context: context,
      message: message,
      type: SnackBarType.info,
    );
  }
  
  static void showWarning(BuildContext context, String message) {
    AppSnackBar.show(
      context: context,
      message: message,
      type: SnackBarType.warning,
    );
  }
}

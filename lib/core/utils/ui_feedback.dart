import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Consistent snackbars + human-readable error messages.
class UiFeedback {
  UiFeedback._();

  static void success(BuildContext context, String message) {
    _show(context, message, isError: false);
  }

  static void error(BuildContext context, Object error) {
    _show(context, describeError(error), isError: true);
  }

  static void _show(BuildContext context, String message,
      {required bool isError}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? scheme.errorContainer : null,
      ));
  }

  /// Map common Firebase errors to friendly text.
  static String describeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'Please choose a stronger password (6+ characters).';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }
    if (error is FirebaseFunctionsException) {
      return error.message ?? 'The server rejected the request.';
    }
    final s = error.toString();
    if (s.contains('permission-denied')) {
      return 'You don\'t have permission to do that.';
    }
    return s.replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
  }
}

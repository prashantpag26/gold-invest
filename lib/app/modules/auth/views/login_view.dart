import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:gold_invest/app/modules/auth/controllers/auth_controller.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/utils/app_translations.dart';
import '../../../../core/utils/validators.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = Get.find<AuthController>();
  final _isBusy = false.obs;
  final _obscure = true.obs;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    _isBusy.value = true;
    try {
      await _auth.signIn(email: _email.text, password: _password.text);
    } catch (e) {
      Get.snackbar('Error', _describeError(e),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isBusy.value = false;
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (Validators.email(email) != null) {
      Get.snackbar('Error', 'Enter your email above first.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      await _auth.sendPasswordReset(email);
      Get.snackbar(
          'Sent', '${'reset_password_sent'.tr} $email',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', _describeError(e),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _signInWithGoogle() async {
    _isBusy.value = true;
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      Get.snackbar('Error', _describeError(e),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isBusy.value = false;
    }
  }

  String _describeError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user-not-found') || msg.contains('wrong-password')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('network')) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.workspace_premium,
                            size: 64, color: Color(0xFFC9A227)),
                        const SizedBox(height: 12),
                        Text('welcome'.tr,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text('Sign in to your gold savings account',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'email'.tr,
                            prefixIcon:
                                const Icon(Icons.email_outlined),
                          ),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure.value,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'password'.tr,
                            prefixIcon:
                                const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  _obscure.value = !_obscure.value,
                            ),
                          ),
                          validator: Validators.password,
                          onFieldSubmitted: (_) => _signIn(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isBusy.value
                                ? null
                                : _forgotPassword,
                            child: Text('forgot_password'.tr),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed:
                              _isBusy.value ? null : _signIn,
                          child: _isBusy.value
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Text('sign_in'.tr),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isBusy.value
                              ? null
                              : _signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 22),
                          label: Text('sign_in_with_google'.tr),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('no_account_yet'.tr),
                            TextButton(
                              onPressed: _isBusy.value
                                  ? null
                                  : () => Get.toNamed(
                                      AppRoutes.register),
                              child: Text('register'.tr),
                            ),
                          ],
                        ),
                      ],
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

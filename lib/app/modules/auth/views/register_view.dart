import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/validators.dart';
import '../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _reference = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _auth = Get.find<AuthController>();
  final _isBusy = false.obs;
  final _obscure = true.obs;
  final _obscureConfirm = true.obs;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _reference.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    _isBusy.value = true;
    try {
      await _auth.register(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        referredBy: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
      );
      // Profile created with status=pending → AuthController._reevaluateRoute
      // will navigate to /pending automatically.
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        _describeError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isBusy.value = false;
    }
  }

  String _describeError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('email-already-in-use')) return 'An account already exists for that email.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('network')) return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('create_account'.tr)),
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
                        Text(
                          'New accounts need admin approval before you can start a '
                          'plan. Add your reference code to speed this up.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'full_name'.tr,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (v) => Validators.required(v, field: 'full_name'.tr),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'email'.tr,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'phone'.tr,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _reference,
                          decoration: const InputDecoration(
                            labelText: 'Reference code (optional)',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure.value,
                          decoration: InputDecoration(
                            labelText: 'password'.tr,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => _obscure.value = !_obscure.value,
                            ),
                          ),
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirm,
                          obscureText: _obscureConfirm.value,
                          decoration: InputDecoration(
                            labelText: 'confirm_password'.tr,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  _obscureConfirm.value = !_obscureConfirm.value,
                            ),
                          ),
                          validator: (v) =>
                              v != _password.text ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isBusy.value ? null : _register,
                          child: _isBusy.value
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text('create_account'.tr),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('already_have_account'.tr),
                            TextButton(
                              onPressed: _isBusy.value
                                  ? null
                                  : () => Get.toNamed(AppRoutes.login),
                              child: Text('sign_in'.tr),
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

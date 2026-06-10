import 'package:get/get.dart';

import 'package:gold_invest/app/modules/auth/controllers/auth_controller.dart';

class ProfileController extends GetxController {
  ProfileController({required AuthController authController})
      : _auth = authController;

  final AuthController _auth;

  Future<void> signOut() => _auth.signOut();
}

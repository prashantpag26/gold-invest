import 'package:get/get.dart';

/// Auth screens (login / register / pending) share the AuthController which
/// is already registered as permanent in InitialBinding — no extra lazy-puts
/// needed here. This binding exists as the required binding slot for GetPages.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is permanent; no lazy registration needed.
  }
}

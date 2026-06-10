import 'package:get/get.dart';

class AdminShellController extends GetxController {
  final RxInt tabIndex = 0.obs;
  void changeTab(int i) => tabIndex.value = i;
}

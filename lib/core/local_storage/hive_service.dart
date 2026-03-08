import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String cartBoxName = 'cartBox';
  static const String adminBoxName = 'adminBox';
  static const String profileBoxName = 'profileBox';
  static const String ordersBoxName = 'ordersBox';

  Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox(cartBoxName);
    await Hive.openBox(adminBoxName);
    await Hive.openBox(profileBoxName);
    await Hive.openBox(ordersBoxName);
  }

  Box get cartBox => Hive.box(cartBoxName);
  Box get adminBox => Hive.box(adminBoxName);
  Box get profileBox => Hive.box(profileBoxName);
  Box get ordersBox => Hive.box(ordersBoxName);

  Future<void> clearAll() async {
    await cartBox.clear();
    await adminBox.clear();
    // Profile and Orders should persist after logout per user request
  }
}

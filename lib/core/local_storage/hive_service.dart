import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String cartBoxName = 'cartBox';
  static const String adminBoxName = 'adminBox';

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters here if needed
    // Hive.registerAdapter(ProductAdapter());
    
    await Hive.openBox(cartBoxName);
    await Hive.openBox(adminBoxName);
  }

  Box get cartBox => Hive.box(cartBoxName);
  Box get adminBox => Hive.box(adminBoxName);

  Future<void> clearAll() async {
    await cartBox.clear();
    await adminBox.clear();
  }
}

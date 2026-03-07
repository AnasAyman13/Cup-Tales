import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.loc.navOrders)),
      body: Center(
        child:
            Text(context.loc.navOrders, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

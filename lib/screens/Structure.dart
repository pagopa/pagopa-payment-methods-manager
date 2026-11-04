import 'package:flutter/material.dart';
import 'package:payment_methods_manager/screens/bundle_list_screen.dart';
import 'package:payment_methods_manager/screens/payment_list_screen.dart';

class Structure extends StatelessWidget {
  const Structure({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabBar(
          tabs: [
            Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: "Pacchetti Commissionali"),
            Tab(icon: Icon(Icons.payment), text: "Metodi di Pagamento"),
          ],
        ),
        body: TabBarView(
          children: [
            BundleListScreen(),
            PaymentListScreen(),
          ],
        ),
      ),
    );
  }
}

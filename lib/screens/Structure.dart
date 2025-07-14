import 'package:flutter/material.dart';
import 'package:payment_methods_manager/screens/bundle_list_screen.dart';
import 'package:payment_methods_manager/screens/payment_list_screen.dart';

class Structure extends StatefulWidget {
  const Structure({super.key});

  @override
  State<Structure> createState() => _StructureState();
}

class _StructureState extends State<Structure> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // DefaultTabController è il modo più semplice per gestire le schede. [1]
    return const DefaultTabController(
      length: 2, // Il numero di schede/sezioni di contenuto da visualizzare. [8]
      child: Scaffold(
        appBar: TabBar(
          tabs: [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: "Pacchetti Commissionali"),
            Tab(icon: Icon(Icons.payment), text: "Metodi di Pagamento"),
          ],
        ),
        // TabBarView viene utilizzato per visualizzare il contenuto corrispondente a ciascuna scheda. [8, 9]
        body: TabBarView(
          children: [
            BundleListScreen(),
            PaymentListScreen(),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  getTab() {
    return IndexedStack(
      index: _selectedIndex,
      children: const <Widget>[
        BundleListScreen(),
        PaymentListScreen(),
        // StatusPage(projects: projectsTouchPoint),
      ],
    );
  }
}

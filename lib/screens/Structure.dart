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
    return Scaffold(
      body: getTab(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: "Pacchetti Commissionali"),
          BottomNavigationBarItem(
              icon: Icon(Icons.payment), label: "Metodi di Pagamento"),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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

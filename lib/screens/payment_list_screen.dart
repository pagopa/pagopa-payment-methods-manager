// lib/screens/payment_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment_method.dart';
import '../providers/payment_provider.dart';
import 'payment_form_screen.dart';

class PaymentListScreen extends StatefulWidget {

  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false).fetchPaymentMethods();
    });
  }

  void _navigateToForm({PaymentMethod? paymentMethod}) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => PaymentFormScreen(paymentMethod: paymentMethod)),
    ).then((_) {
      Provider.of<PaymentProvider>(context, listen: false).fetchPaymentMethods();
    });
  }

  Future<void> _showDeleteConfirmationDialog(PaymentMethod method) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: Text('Sei sicuro di voler eliminare "${method.displayName}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULLA'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ELIMINA', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await Provider.of<PaymentProvider>(context, listen: false).deletePaymentMethod(method.paymentMethodId!);
      } catch (e) {
        // Gestisci l'errore se necessario
      }
    }
  }

  // --- Widget per l'intestazione della tabella ---
  Widget _buildHeader() {
    final headerStyle =
    Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade600);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('LOGO', style: headerStyle)),
          Expanded(flex: 2, child: Text('NOME', style: headerStyle)),
          Expanded(flex: 1, child: Text('GRUPPO', style: headerStyle)),
          Expanded(flex: 1, child: Text('STATO', style: headerStyle)),
          Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('AZIONI', style: headerStyle))),
        ],
      ),
    );
  }

  // --- Widget per una singola riga di dati ---
  Widget _buildDataRow(PaymentMethod method) {
    return InkWell(
      onTap: () => _navigateToForm(paymentMethod: method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(flex: 1, child: method.paymentMethodAsset!=null ? SizedBox(height: 25, width: 25,child: Image.network(method.paymentMethodAsset!)) : Icon(Icons.broken_image_outlined)),
            Expanded(flex: 2, child: Text(method.displayName, style: Theme.of(context).textTheme.titleLarge)),
            Expanded(flex: 1, child: Text(method.group ?? 'N/A')),
            Expanded(flex: 1, child: _buildStatusChip(method.status)),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _showDeleteConfirmationDialog(method),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    status ??= 'N/A';
    Color color = Colors.grey;
    if (status == 'ENABLED') {
      color = Colors.green;
    } else if (status == 'DISABLED') {
      color = Colors.orange;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10)),
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: EdgeInsets.zero,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title:  Text('Metodo di pagamento')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gestisci i metodi di pagamento', style: textTheme.titleLarge),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Nuovo'),
                  onPressed: () => _navigateToForm(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // La Card ora contiene la nostra tabella personalizzata
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias, // Assicura che i figli rispettino i bordi arrotondati
                child: Consumer<PaymentProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.paymentMethods.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.errorMessage != null) {
                      return Center(child: Text('Errore: ${provider.errorMessage}'));
                    }
                    if (provider.paymentMethods.isEmpty) {
                      return const Center(child: Text('Nessun metodo di pagamento trovato.'));
                    }

                    // Struttura a tabella: Colonna con intestazione e poi la lista
                    return Column(
                      children: [
                        _buildHeader(), // La nostra intestazione fissa
                        Expanded(
                          // La ListView ora è dentro un Expanded, quindi ha un'altezza finita
                          child: ListView.builder(
                            itemCount: provider.paymentMethods.length,
                            itemBuilder: (context, index) {
                              final method = provider.paymentMethods[index];
                              return _buildDataRow(method); // La nostra riga di dati
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
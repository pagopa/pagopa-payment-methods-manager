import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment_method.dart';
import '../providers/api_provider.dart';
import '../widget/catalog_filter_panel.dart';
import '../widget/csv_export_button.dart';
import 'payment_form_screen.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ApiProvider>(context, listen: false).fetchPaymentMethods();
    });
  }

  void _navigateToForm({PaymentMethod? paymentMethod}) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
          builder: (context) =>
              PaymentFormScreen(paymentMethod: paymentMethod)),
    )
        .then((_) {
      Provider.of<ApiProvider>(context, listen: false).fetchPaymentMethods();
    });
  }

  Future<void> _showDeleteConfirmationDialog(PaymentMethod method) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content:
              Text('Sei sicuro di voler eliminare "${method.displayName}"?'),
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
        await Provider.of<ApiProvider>(context, listen: false)
            .deletePaymentMethod(method.paymentMethodId!);
      } catch (e) {}
    }
  }

  Widget _buildHeader() {
    final headerStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade600);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('NOME', style: headerStyle)),
          Expanded(flex: 1, child: Text('GRUPPO', style: headerStyle)),
          Expanded(flex: 1, child: Text('STATO', style: headerStyle)),
          Expanded(flex: 1, child: Text('TIPO', style: headerStyle)),
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('AZIONI', style: headerStyle))),
        ],
      ),
    );
  }

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
            Expanded(
                flex: 2,
                child: Text(method.displayName,
                    style: Theme.of(context).textTheme.titleLarge)),
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
        label: Text(status,
            style: const TextStyle(color: Colors.white, fontSize: 10)),
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Metodi di pagamento')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gestisci i metodi di pagamento',
                    style: textTheme.titleLarge),
                Consumer<ApiProvider>(
                  builder: (context, provider, _) => CsvExportButton(
                    filename: 'metodi-pagamento.csv',
                    createCsv: provider.exportPaymentMethodsCsv,
                    enabled: !provider.methodsLoading &&
                        provider.methodsError == null,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Nuovo'),
                  onPressed: () => _navigateToForm(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Gli stessi filtri applicati alla tabella selezionano i record CSV.
            CatalogFilterPanel(
              fields: const [
                FilterField('search', 'Nome o ID metodo'),
                FilterField('touchpoint', 'Touchpoint',
                    options: ['IO', 'CHECKOUT', 'CHECKOUT_CART']),
                FilterField('management', 'Gestione', options: [
                  'REDIRECT',
                  'ONBOARDABLE',
                  'ONBOARDABLE_ONLY',
                  'NOT_ONBOARDABLE'
                ]),
                FilterField('status', 'Stato',
                    options: ['ENABLED', 'DISABLED', 'MAINTENANCE']),
                FilterField('group', 'Gruppo'),
                FilterField('category', 'Categoria',
                    options: ['CARTE', 'CONTO', 'APP']),
                FilterField('device', 'Device',
                    options: ['IOS', 'ANDROID', 'WEB', 'SAFARI']),
              ],
              onApply: context.read<ApiProvider>().applyMethodFilters,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Consumer<ApiProvider>(
                  builder: (context, provider, child) {
                    final methods = provider.filteredPaymentMethods;
                    if (provider.methodsLoading &&
                        provider.paymentMethods.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.methodsError != null) {
                      return Center(
                          child: Text('Errore: ${provider.methodsError}'));
                    }
                    if (methods.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Nessun metodo di pagamento trovato.'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: provider.methodsLoading
                                  ? null
                                  : () => provider.fetchPaymentMethods(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Ricarica metodi'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: methods.length,
                            itemBuilder: (context, index) {
                              final method = methods[index];
                              return _buildDataRow(method);
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

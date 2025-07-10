import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payment_methods_manager/providers/api_provider.dart';
import 'package:provider/provider.dart';

class BundleDetailScreen extends StatefulWidget {
  final String bundleId;
  const BundleDetailScreen({super.key, required this.bundleId});

  @override
  State<BundleDetailScreen> createState() => _BundleDetailScreenState();
}

class _BundleDetailScreenState extends State<BundleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ApiProvider>(context, listen: false)
          .fetchBundleDetails(widget.bundleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio Pacchetto'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ApiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || provider.selectedBundle == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Errore: ${provider.errorMessage}'));
          }

          final bundle = provider.selectedBundle!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Informazioni di Base'),
                _buildDetailCard([
                  _buildDetailRow('Nome Pacchetto', bundle.name),
                  _buildDetailRow('ID Bundle', bundle.idBundle),
                  _buildDetailRow('Descrizione', bundle.description, isMultiline: true),
                  _buildDetailRow('PSP', bundle.pspBusinessName),
                  _buildDetailRow('ID PSP', bundle.idPsp),
                ]),
                const SizedBox(height: 24),

                _buildSectionTitle('Regole e Configurazione'),
                _buildDetailCard([
                  _buildDetailRow('Tipo', bundle.type),
                  _buildDetailRow('Touchpoint', bundle.touchpoint),
                  _buildAmountRange('Range Importo', bundle.minPaymentAmount, bundle.maxPaymentAmount),
                  _buildDateRange('Periodo di Validità', bundle.validityDateFrom, bundle.validityDateTo),
                  _buildDetailRow('Canale', bundle.idChannel),
                  _buildDetailRow('Broker PSP', bundle.idBrokerPsp),
                ]),
                const SizedBox(height: 24),

                _buildSectionTitle('Attributi Aggiuntivi'),
                _buildDetailCard([
                  _buildBooleanRow('Bollo Digitale', bundle.digitalStamp),
                  _buildBooleanRow('Restrizione Bollo Digitale', bundle.digitalStampRestriction),
                  _buildBooleanRow('Utilizzabile nel Carrello', bundle.cart),
                  _buildBooleanRow('Pagamento On-Us', bundle.onUs),
                  _buildStringList('Lista Tipi Trasferimento', bundle.transferCategoryList),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/D',
              style: const TextStyle(fontSize: 16),
              softWrap: isMultiline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanRow(String label, bool? value) {
    IconData icon;
    Color color;
    String text;

    if (value == true) {
      icon = Icons.check_circle_outline;
      color = Colors.green;
      text = 'Sì';
    } else if (value == false) {
      icon = Icons.highlight_off;
      color = Colors.red;
      text = 'No';
    } else {
      icon = Icons.help_outline;
      color = Colors.grey;
      text = 'N/D';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/D';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatCurrency(int? amountInCents) {
    if (amountInCents == null) return 'N/A';
    final amount = amountInCents / 100.0;
    return NumberFormat.currency(locale: 'it_IT', symbol: '€').format(amount);
  }

  Widget _buildAmountRange(String label, int? minAmount, int? maxAmount) {
    final value = '${_formatCurrency(minAmount)} - ${_formatCurrency(maxAmount)}';
    return _buildDetailRow(label, value);
  }

  Widget _buildDateRange(String label, DateTime? fromDate, DateTime? toDate) {
    final value = '${_formatDate(fromDate)} - ${_formatDate(toDate)}';
    return _buildDetailRow(label, value);
  }

  Widget _buildStringList(String label, List<String>? list) {
    final value = (list == null || list.isEmpty) ? 'Nessuno' : list.join(', ');
    return _buildDetailRow(label, value, isMultiline: true);
  }
}
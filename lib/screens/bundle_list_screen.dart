import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/psp_bundle_details.dart';
import '../providers/api_provider.dart';
import 'bundle_detail_screen.dart';
import '../models/catalog_filters.dart';
import '../widget/catalog_filter_panel.dart';
import '../widget/csv_export_button.dart';

class BundleListScreen extends StatefulWidget {
  const BundleListScreen({super.key});
  @override
  State<BundleListScreen> createState() => _BundleListScreenState();
}

class _BundleListScreenState extends State<BundleListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNearEnd);
    final provider = Provider.of<ApiProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !provider.isLoading && provider.bundlePagesLoaded == 0) {
        provider.fetchMoreBundles(isRefresh: true);
      }
    });
  }

  void _loadNearEnd() {
    if (!mounted || !_scrollController.hasClients) return;
    final provider = context.read<ApiProvider>();
    if (_scrollController.position.extentAfter < 300 &&
        provider.hasMoreBundles &&
        !provider.isLoading &&
        provider.errorMessage == null) {
      provider.fetchMoreBundles();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToDetail(String bundleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => BundleDetailScreen(
                bundleId: bundleId,
                ci: context.read<ApiProvider>().bundleFilters['ci'],
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pacchetti Commissionali')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Elenco Pacchetti',
                    style: Theme.of(context).textTheme.titleLarge),
                CsvExportButton(
                  filename: 'pacchetti.csv',
                  createCsv: context.read<ApiProvider>().exportBundlesCsv,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CatalogFilterPanel(
              fields: const [
                FilterField('name', 'Nome pacchetto'),
                FilterField('id', 'ID pacchetto'),
                FilterField('psp', 'Nome o ID PSP'),
                FilterField('type', 'Tipo',
                    options: ['GLOBAL', 'PUBLIC', 'PRIVATE']),
                FilterField('status', 'Stato',
                    options: ['active', 'future', 'expired']),
                FilterField('touchpoint', 'Touchpoint',
                    options: ['IO', 'CHECKOUT', 'CHECKOUT_CART']),
                FilterField('paymentType', 'Tipo pagamento (codice esatto)'),
                FilterField('amount', 'Importo pagamento EUR', currency: true),
                FilterField('minFee', 'Commissione minima EUR', currency: true),
                FilterField('maxFee', 'Commissione massima EUR',
                    currency: true),
                FilterField('taxonomy', 'Tassonomia configurata (esatta)'),
                FilterField('ci', 'Codice fiscale ente'),
                FilterField('channel', 'Canale'),
                FilterField('broker', 'Broker'),
                FilterField('onUs', 'On-us', options: ['true', 'false']),
                FilterField('cart', 'Carrello', options: ['true', 'false']),
                FilterField('stamp', 'Bollo', options: ['true', 'false']),
                FilterField('stampRestriction', 'Restrizione bollo',
                    options: ['true', 'false']),
              ],
              onApply: context.read<ApiProvider>().applyBundleFilters,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Consumer<ApiProvider>(
                  builder: (context, provider, child) {
                    final bundlesToDisplay = provider.filteredBundles;
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _loadNearEnd());

                    final progress = Column(
                      children: [
                        if (provider.isLoading && bundlesToDisplay.isEmpty)
                          const LinearProgressIndicator(),
                        if (provider.errorMessage != null)
                          Text('Ricerca incompleta: ${provider.errorMessage}'),
                        if (!provider.isLoading &&
                            provider.errorMessage != null)
                          TextButton(
                            onPressed: () => provider.fetchMoreBundles(
                                isRefresh: provider.bundlePagesLoaded == 0),
                            child: const Text('Riprova'),
                          ),
                      ],
                    );
                    if (provider.isLoading && bundlesToDisplay.isEmpty) {
                      return progress;
                    }
                    if (provider.errorMessage != null &&
                        bundlesToDisplay.isEmpty) {
                      return progress;
                    }
                    if (bundlesToDisplay.isEmpty && !provider.isLoading) {
                      return Column(children: [
                        progress,
                        Text(provider.bundlesComplete
                            ? 'Nessun pacchetto trovato con i filtri attuali.'
                            : 'Ricerca interrotta.'),
                      ]);
                    }

                    return Column(
                      children: [
                        progress,
                        _buildHeader(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () =>
                                provider.fetchMoreBundles(isRefresh: true),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _scrollController,
                              itemCount: bundlesToDisplay.length +
                                  (provider.isLoading &&
                                          bundlesToDisplay.isNotEmpty
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index == bundlesToDisplay.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final bundle = bundlesToDisplay[index];
                                return _buildDataRow(bundle);
                              },
                            ),
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

  Widget _buildHeader() {
    final headerStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade600);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('NOME PACCHETTO', style: headerStyle)),
          Expanded(flex: 2, child: Text('PSP', style: headerStyle)),
          Expanded(flex: 1, child: Text('TIPO', style: headerStyle)),
          Expanded(
              flex: 3,
              child: Text('TOUCHPOINT / PAGAMENTO / FEE / RANGE',
                  style: headerStyle)),
          Expanded(flex: 2, child: Text('STATO', style: headerStyle)),
        ],
      ),
    );
  }

  Widget _buildDataRow(PspBundleDetails bundle) {
    return InkWell(
      onTap: () => _navigateToDetail(bundle.idBundle!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                bundle.name ?? 'N/D',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(bundle.pspBusinessName ?? bundle.idPsp ?? 'N/D'),
            ),
            Expanded(flex: 1, child: Text(bundle.type ?? 'N/D')),
            Expanded(
              flex: 3,
              child: Text(
                  '${bundle.touchpoint ?? "N/D"} / ${bundle.paymentType ?? "N/D"}\n'
                  '${money(bundle.paymentAmount)} / ${money(bundle.minPaymentAmount)} - ${money(bundle.maxPaymentAmount)}'),
            ),
            Expanded(flex: 2, child: _buildStatusChip(bundle)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PspBundleDetails bundle) {
    final today = DateUtilsForFilters.day(DateTime.now());
    String statusText = 'ATTIVO';
    Color color = Colors.green;

    if (bundle.validityDateFrom != null &&
        DateUtilsForFilters.day(bundle.validityDateFrom!).isAfter(today)) {
      statusText = 'FUTURO';
      color = Colors.blue;
    } else if (bundle.validityDateTo != null &&
        DateUtilsForFilters.day(bundle.validityDateTo!).isBefore(today)) {
      statusText = 'SCADUTO';
      color = Colors.grey;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(statusText,
            style: const TextStyle(color: Colors.white, fontSize: 10)),
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: EdgeInsets.zero,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/psp_bundle_details.dart';
import '../providers/api_provider.dart';
import 'bundle_detail_screen.dart';

class BundleListScreen extends StatefulWidget {
  const BundleListScreen({super.key});
  @override
  State<BundleListScreen> createState() => _BundleListScreenState();
}

class _BundleListScreenState extends State<BundleListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameFilterController = TextEditingController();
  final TextEditingController _pspFilterController = TextEditingController();

  String? _selectedType;
  BundleStatusFilter _selectedStatus = BundleStatusFilter.all;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ApiProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.fetchMoreBundles(isRefresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
        provider.fetchMoreBundles();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameFilterController.dispose();
    _pspFilterController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    Provider.of<ApiProvider>(context, listen: false).setFilters(
      name: _nameFilterController.text,
      psp: _pspFilterController.text,
      types: _selectedType != null ? [_selectedType!] : null,
      status: _selectedStatus,
    );
  }

  void _resetFilters() {
    _nameFilterController.clear();
    _pspFilterController.clear();
    setState(() {
      _selectedType = null;
      _selectedStatus = BundleStatusFilter.all;
    });
    Provider.of<ApiProvider>(context, listen: false).setFilters();
  }

  void _navigateToDetail(String bundleId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => BundleDetailScreen(bundleId: bundleId)),
    );
  }

  Widget _buildFilterPanel() {
    return ExpansionTile(
      title: const Text('Filtri di Ricerca'),
      leading: const Icon(Icons.filter_list),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Pacchetto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pspFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Nome o ID PSP',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_center_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                      items: ['GLOBAL', 'PUBLIC', 'PRIVATE']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedType = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<BundleStatusFilter>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Stato', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: BundleStatusFilter.all, child: Text('Tutti')),
                        DropdownMenuItem(value: BundleStatusFilter.active, child: Text('Attivo')),
                        DropdownMenuItem(value: BundleStatusFilter.future, child: Text('Futuro')),
                        DropdownMenuItem(value: BundleStatusFilter.expired, child: Text('Scaduto')),
                      ],
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _resetFilters, child: const Text('Resetta')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.check),
                    label: const Text('Applica'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pacchetti Commissionali')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Elenco Pacchetti', style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 16),
            _buildFilterPanel(),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Consumer<ApiProvider>(
                  builder: (context, provider, child) {
                    final bundlesToDisplay = provider.filteredBundles;

                    if (provider.isLoading && bundlesToDisplay.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.errorMessage != null && bundlesToDisplay.isEmpty) {
                      return Center(child: Text('Errore: ${provider.errorMessage}'));
                    }
                    if (bundlesToDisplay.isEmpty && !provider.isLoading) {
                      return const Center(child: Text('Nessun pacchetto trovato con i filtri attuali.'));
                    }

                    return Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => provider.fetchMoreBundles(isRefresh: true),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: bundlesToDisplay.length + (provider.isLoading && bundlesToDisplay.isNotEmpty ? 1 : 0),
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
            Expanded(flex: 2, child: _buildStatusChip(bundle)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PspBundleDetails bundle) {
    final now = DateTime.now();
    String statusText = 'ATTIVO';
    Color color = Colors.green;

    if (bundle.validityDateFrom != null && now.isBefore(bundle.validityDateFrom!)) {
      statusText = 'FUTURO';
      color = Colors.blue;
    } else if (bundle.validityDateTo != null && now.isAfter(bundle.validityDateTo!)) {
      statusText = 'SCADUTO';
      color = Colors.grey;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10)),
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: EdgeInsets.zero,
      ),
    );
  }
}